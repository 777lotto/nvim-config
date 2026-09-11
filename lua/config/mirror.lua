-- The zemRip Postgres mirror inside Neovim.
--
-- nvim-dbee is the client; this module decides how it reaches the mirror,
-- which depends on the plane the session runs on rather than on anything the
-- user should have to remember:
--
--   socket  zemrip-server itself (zed). The mirror is a Unix-socket-only
--           Quadlet unit and the socket directory exists at boot, so the
--           connection opens the socket directly. No tunnel, no process.
--   grant   the zemrip-ai container. The operator's attended
--           agent-mirror-grant already forwards the socket to the container's
--           127.0.0.1:55432 for its lifetime; this config only points at it.
--   tunnel  everywhere else (the Toughbook). One panel-scoped SSH forward,
--           exactly as MCP Buff does for the broker admin listeners, except
--           the local port forwards to the socket path rather than to a TCP
--           port: `-L 127.0.0.1:55433:/run/zemrip/mirror/.s.PGSQL.5432`
--           through the WireGuard `zemrip-server` alias.
--
-- Socket connections are trust-authenticated -- the socket ACL is the access
-- control -- so no URL here carries a credential and none may gain one. The
-- forward is therefore a passwordless door for as long as it exists, which
-- is why it lives exactly as long as the panel: opened by `:Mirror` (or any
-- dbee entry point, through the wrapped layout), closed with the panel, and
-- on `VimLeavePre`. It is the local mirror only; Neon is untouched until an
-- explicit `db.sh push` on the operator plane.
local M = {}

local uv = vim.uv or vim.loop

M.SOCKET_DIR = "/run/zemrip/mirror"
M.SOCKET = M.SOCKET_DIR .. "/.s.PGSQL.5432"
M.ROLE = "neondb_owner"
M.DATABASE = "neondb"
-- The tunnel port matches db.sh's own studio bridge so the two can never be
-- confused for anything but the mirror, and can never both be open at once.
M.TUNNEL_PORT = 55433
M.GRANT_PORT = 55432
M.SSH_HOST = "zemrip-server"
M.AGENT_MARKER = "~/.local/bin/gh-agent"
M.SOURCE_NAME = "zemrip"
M.CONNECTION_NAME = "zemRip mirror"

M.PLANES = {
  socket = "zemrip-server: the mirror's Unix socket, opened directly",
  grant = "zemrip-ai: the operator's agent-mirror-grant on 127.0.0.1:" .. M.GRANT_PORT,
  tunnel = "remote: a panel-scoped SSH forward to the mirror socket through " .. M.SSH_HOST,
}

local state = {
  plane = nil,
  reason = nil,
  tunnel = nil,
}

local function is_set(value)
  return type(value) == "string" and value ~= ""
end

local function notify(message, level)
  vim.schedule(function()
    vim.notify(message, level or vim.log.levels.INFO, { title = "Mirror" })
  end)
end

--- Decide which plane this session runs on. Pure given `runtime`, so the
--- policy can be exercised without the machine it describes.
--- @param runtime? table env, stat, expand, executable overrides
--- @return string plane, string reason
function M.detect(runtime)
  runtime = runtime or {}
  local env = runtime.env or vim.env
  local stat = runtime.stat or uv.fs_stat
  local expand = runtime.expand or vim.fn.expand
  local executable = runtime.executable
    or function(path) return vim.fn.executable(path) == 1 end

  local requested = env.NVIM_MIRROR_PLANE
  if is_set(requested) then
    if M.PLANES[requested] then
      return requested, "NVIM_MIRROR_PLANE=" .. requested
    end
    notify(
      ("Ignoring invalid NVIM_MIRROR_PLANE=%q; expected socket, grant, or tunnel"):format(requested),
      vim.log.levels.WARN
    )
  end

  -- tmpfiles creates the socket directory at boot on zemrip-server whether or
  -- not the unit is running, so the directory identifies the host and the
  -- socket file inside it reports whether the mirror is up.
  local directory = stat(M.SOCKET_DIR)
  if directory and directory.type == "directory" then
    return "socket", M.SOCKET_DIR .. " exists"
  end
  if executable(expand(M.AGENT_MARKER)) then
    return "grant", M.AGENT_MARKER .. " is executable"
  end
  return "tunnel", "no local mirror"
end

--- The plane for this session, detected once.
--- @return string plane, string reason
function M.plane()
  if not state.plane then
    state.plane, state.reason = M.detect()
  end
  return state.plane, state.reason
end

--- Where the client connects on a plane, for `:MirrorStatus`.
function M.target(plane)
  if plane == "socket" then return M.SOCKET end
  if plane == "grant" then return "127.0.0.1:" .. M.GRANT_PORT end
  return "127.0.0.1:" .. M.TUNNEL_PORT
end

--- The lib/pq connection URL for a plane. `sslmode=disable` is mandatory on
--- all three: the mirror container has no TLS, and lib/pq defaults to
--- requiring it. The socket form passes the directory as the `host`
--- parameter, which lib/pq resolves to `<dir>/.s.PGSQL.5432`.
function M.url(plane)
  if plane == "socket" then
    return ("postgres://%s@/%s?host=%s&sslmode=disable"):format(M.ROLE, M.DATABASE, M.SOCKET_DIR)
  end
  local port = plane == "grant" and M.GRANT_PORT or M.TUNNEL_PORT
  return ("postgres://%s@127.0.0.1:%d/%s?sslmode=disable"):format(M.ROLE, port, M.DATABASE)
end

--- The single dbee connection for a plane.
function M.connection(plane)
  return {
    name = M.CONNECTION_NAME,
    type = "postgres",
    url = M.url(plane),
  }
end

--- Managed-tunnel settings for the remote plane.
function M.tunnel_config()
  return {
    host = M.SSH_HOST,
    port = M.TUNNEL_PORT,
    socket = M.SOCKET,
  }
end

local function tunnel()
  if state.tunnel then return state.tunnel end
  local Tunnel = require("config.mirror_tunnel")
  local config, err = Tunnel.normalize(M.tunnel_config())
  if not config then error("mirror tunnel configuration is invalid: " .. err) end
  state.tunnel = Tunnel.new(config, {
    on_exit = function(failure)
      notify(failure.message .. " — run :Mirror to reopen it", vim.log.levels.WARN)
    end,
  })
  return state.tunnel
end

local function socket_present()
  local socket = uv.fs_stat(M.SOCKET)
  return socket ~= nil and socket.type == "socket"
end

--- True when the client can connect right now without any further step. The
--- grant plane cannot be known synchronously (its check is a loopback probe),
--- so it answers true and lets `ensure` report a missing grant.
function M.ready()
  local plane = M.plane()
  if plane == "socket" then return socket_present() end
  if plane == "grant" then return true end
  return state.tunnel ~= nil and state.tunnel:is_ready()
end

--- Make the mirror reachable for this plane, then call back with nil or
--- `{ message = ... }`. Only the tunnel plane starts a process; the other two
--- report a missing precondition with the operator's remedy instead of
--- letting the client fail with a bare connection error.
function M.ensure(callback)
  local plane = M.plane()
  if plane == "socket" then
    if socket_present() then
      callback(nil)
    else
      callback({ message = ("mirror-db is down: no socket at %s. Start it on zemrip-server with "
        .. "`sudo -iu zemrip-infra systemctl --user start mirror-db`."):format(M.SOCKET) })
    end
    return
  end
  if plane == "grant" then
    require("config.mirror_tunnel").probe(M.GRANT_PORT, function(listening, probe_error)
      if probe_error then
        callback({ message = probe_error })
      elseif listening then
        callback(nil)
      else
        callback({ message = ("no mirror grant on 127.0.0.1:%d. Ask the operator to run "
          .. "apps/local/db/agent-mirror-grant.sh on zemrip-server and keep it in the foreground.")
          :format(M.GRANT_PORT) })
      end
    end)
    return
  end
  tunnel():ensure(callback)
end

--- Revoke the forward this config created, if any. Safe on every plane.
function M.release()
  if state.tunnel then state.tunnel:stop() end
end

--- Forward state for `:MirrorStatus`.
function M.forward_status()
  if M.plane() ~= "tunnel" then return "not needed" end
  if not state.tunnel then return "stopped" end
  return state.tunnel:status()
end

--- The dbee configuration for this session: one connection, active by
--- default, on a layout whose open and close are tied to the forward.
function M.dbee_options()
  local plane = M.plane()
  local connection = M.connection(plane)
  local source = require("dbee.sources").MemorySource:new({ connection }, M.SOURCE_NAME)
  return {
    sources = { source },
    -- MemorySource assigns the id onto the very table it was handed.
    default_connection = connection.id,
    window_layout = M.window_layout(),
  }
end

--- dbee's default layout with the forward's lifetime attached: every entry
--- point that opens the UI (`:Dbee`, `:Dbee toggle`, the Lua API) first
--- makes the mirror reachable, and closing the UI by any route (`:Dbee
--- close`, `:q` in a dbee window, `:MirrorClose`) revokes the forward.
function M.window_layout()
  local layout = require("dbee.layouts").Default:new()
  local open, close = layout.open, layout.close
  layout.open = function(self)
    if M.ready() then
      return open(self)
    end
    M.ensure(function(failure)
      if failure then
        notify(failure.message, vim.log.levels.ERROR)
        return
      end
      require("dbee").open()
    end)
  end
  layout.close = function(self)
    close(self)
    M.release()
  end
  return layout
end

--- `:Mirror` -- make the mirror reachable and open (or re-open) the panel.
--- Unlike `:Dbee open`, this also re-establishes a forward that died under an
--- open panel.
function M.open()
  local loaded, dbee = pcall(require, "dbee")
  if not loaded then
    notify("nvim-dbee is not installed; run `nvim-config sync` and retry", vim.log.levels.ERROR)
    return
  end
  M.ensure(function(failure)
    if failure then
      notify(failure.message, vim.log.levels.ERROR)
      return
    end
    dbee.open()
  end)
end

--- `:MirrorClose` -- close the panel and revoke the forward. Never loads the
--- plugin just to close it.
function M.close()
  local dbee = package.loaded["dbee"]
  if dbee then pcall(dbee.close) end
  M.release()
end

--- `:MirrorStatus` -- plane, target, forward, and client state.
function M.status()
  local plane, reason = M.plane()
  local dbee = package.loaded["dbee"]
  local panel = "not loaded"
  if dbee then
    local ok, open = pcall(dbee.is_open)
    panel = (ok and open) and "open" or "closed"
  end
  local backend = vim.fn.stdpath("data") .. "/dbee/bin/dbee"
  local lines = {
    ("Plane: %s (%s)"):format(plane, reason),
    "Route: " .. M.PLANES[plane],
    "Target: " .. M.target(plane),
    "Role: " .. M.ROLE .. " · database: " .. M.DATABASE .. " · auth: socket trust",
    "Forward: " .. M.forward_status(),
    "Panel: " .. panel,
    "Backend: " .. (vim.fn.executable(backend) == 1 and backend or "missing — run `nvim-config sync`"),
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Mirror" })
end

function M.setup()
  vim.api.nvim_create_user_command("Mirror", M.open, {
    desc = "Open the zemRip mirror database panel (nvim-dbee), reaching the mirror for this plane",
    force = true,
  })
  vim.api.nvim_create_user_command("MirrorClose", M.close, {
    desc = "Close the mirror panel and revoke its SSH forward",
    force = true,
  })
  vim.api.nvim_create_user_command("MirrorStatus", M.status, {
    desc = "Show the detected plane, connection target, and forward state",
    force = true,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("config_mirror", { clear = true }),
    callback = M.release,
    desc = "Revoke the mirror SSH forward with the editor",
  })
end

--- Reset detection and forward state. Tests only.
function M._reset()
  M.release()
  state.plane, state.reason, state.tunnel = nil, nil, nil
end

return M
