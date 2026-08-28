-- Environment-dependent policy belongs here instead of in plugin specs.
-- Keep the defaults portable and expose small overrides for machines whose
-- terminal or clipboard behavior differs from the current Debian setup.
local M = {}

local function is_set(value)
  return type(value) == "string" and value ~= ""
end

local function first_set(...)
  for index = 1, select("#", ...) do
    local value = select(index, ...)
    if is_set(value) then
      return value
    end
  end
  return "unset"
end

M.is_ssh = is_set(vim.env.SSH_TTY) or is_set(vim.env.SSH_CONNECTION)
M.desktop = first_set(vim.env.XDG_CURRENT_DESKTOP, vim.env.DESKTOP_SESSION)
M.session_type = first_set(vim.env.XDG_SESSION_TYPE)
M.terminal = first_set(vim.env.TERM_PROGRAM, vim.env.COLORTERM, vim.env.TERM)
M.ssh_auth_sock = first_set(vim.env.SSH_AUTH_SOCK)

local valid_clipboard_modes = {
  auto = true,
  bridge = true,
  native = true,
  osc52 = true,
}

local function requested_clipboard_mode()
  local mode = (vim.env.NVIM_CLIPBOARD or "auto"):lower()
  if mode == "" then
    mode = "auto"
  end

  if valid_clipboard_modes[mode] then
    return mode
  end

  vim.schedule(function()
    vim.notify(
      ("Ignoring invalid NVIM_CLIPBOARD=%q; expected auto, bridge, native, or osc52"):format(mode),
      vim.log.levels.WARN,
      { title = "Environment policy" }
    )
  end)
  return "auto"
end

local function clipboard_bridge_path()
  local path = vim.fn.expand("~/.local/bin/toughbook-copy")
  return vim.fn.executable(path) == 1 and path or nil
end

local function setup_bridge_copy(path)
  local cached = {
    ["+"] = { {}, "" },
    ["*"] = { {}, "" },
  }

  local function report_failure(reason)
    vim.schedule(function()
      vim.notify(
        "Toughbook clipboard copy failed: " .. reason,
        vim.log.levels.WARN,
        { title = "Clipboard bridge" }
      )
    end)
  end

  local function copy_to_bridge(register)
    return function(lines, regtype)
      cached[register] = { vim.deepcopy(lines), regtype }
      -- vim.system raises synchronously when the helper cannot be spawned at
      -- all, so an absent or non-executable binary never reaches on_exit. An
      -- explicit NVIM_CLIPBOARD=bridge must degrade to a warning, not throw on
      -- every yank.
      local spawned, spawn_error = pcall(vim.system, { path }, {
        stdin = table.concat(lines, "\n"),
        text = true,
      }, function(result)
        if result.code ~= 0 then
          report_failure(is_set(result.stderr) and result.stderr or ("exit " .. result.code))
        end
      end)
      if not spawned then
        report_failure(tostring(spawn_error))
      end
    end
  end

  local function paste_cached(register)
    -- Preserve ordinary `p` after a yank without allowing the remote host to
    -- read arbitrary contents from the Toughbook clipboard.
    return function()
      return { vim.deepcopy(cached[register][1]), cached[register][2] }
    end
  end

  vim.g.clipboard = {
    name = "Toughbook bridge (copy only)",
    copy = {
      ["+"] = copy_to_bridge("+"),
      ["*"] = copy_to_bridge("*"),
    },
    paste = {
      ["+"] = paste_cached("+"),
      ["*"] = paste_cached("*"),
    },
  }
end

local function setup_osc52_copy()
  local osc52 = require("vim.ui.clipboard.osc52")
  local cached = {
    ["+"] = { {}, "" },
    ["*"] = { {}, "" },
  }
  local function copy_and_cache(register)
    local send = osc52.copy(register)
    return function(lines, regtype)
      cached[register] = { vim.deepcopy(lines), regtype }
      send(lines, regtype)
    end
  end
  local function paste_cached(register)
    return function()
      return { vim.deepcopy(cached[register][1]), cached[register][2] }
    end
  end

  vim.g.clipboard = {
    name = "OSC 52 (copy only)",
    copy = {
      ["+"] = copy_and_cache("+"),
      ["*"] = copy_and_cache("*"),
    },
    paste = {
      ["+"] = paste_cached("+"),
      ["*"] = paste_cached("*"),
    },
  }
end

-- Route ssh operations spawned from Neovim (git push/fetch, :terminal)
-- through gpg-agent's SSH socket, which serves the OpenPGP card auth key.
-- ~/.bashrc does this only for interactive shells; a desktop-launched Neovim
-- otherwise inherits XFCE's keyless ssh-agent and every push fails with
-- "Permission denied (publickey)".
local function route_ssh_through_gpg_agent()
  if vim.fn.executable("gpgconf") ~= 1 then
    return
  end

  local sock = vim.fn.systemlist({ "gpgconf", "--list-dirs", "agent-ssh-socket" })[1]
  if is_set(sock) and vim.uv.fs_stat(sock) then
    vim.env.SSH_AUTH_SOCK = sock
    M.ssh_auth_sock = sock
  end
end

function M.setup()
  route_ssh_through_gpg_agent()
  local mode = requested_clipboard_mode()
  local bridge_path = clipboard_bridge_path()
  if mode == "auto" then
    if M.is_ssh then
      mode = bridge_path and "bridge" or "osc52"
    else
      mode = "native"
    end
  end

  -- "native" deliberately leaves g:clipboard unset so Neovim can choose the
  -- available local clipboard provider itself.
  vim.opt.clipboard = "unnamedplus"
  if mode == "bridge" then
    setup_bridge_copy(bridge_path or vim.fn.expand("~/.local/bin/toughbook-copy"))
  elseif mode == "osc52" then
    setup_osc52_copy()
  end
  M.clipboard_mode = mode

  vim.api.nvim_create_user_command("EnvironmentInfo", function()
    local lines = {
      "SSH session: " .. tostring(M.is_ssh),
      "Desktop: " .. M.desktop,
      "Session type: " .. M.session_type,
      "Terminal: " .. M.terminal,
      "Clipboard policy: " .. M.clipboard_mode,
      "SSH_AUTH_SOCK: " .. M.ssh_auth_sock,
    }
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Neovim environment" })
  end, {
    desc = "Show detected desktop, terminal, clipboard, and SSH environment",
    force = true,
  })
end

return M
