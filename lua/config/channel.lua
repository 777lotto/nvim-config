local M = {}

local DEFAULT_CHANNEL = "bet"

local function state_home()
  if vim.env.XDG_STATE_HOME and vim.env.XDG_STATE_HOME ~= "" then
    return vim.env.XDG_STATE_HOME
  end
  local home = vim.env.HOME
  if not home or home == "" then home = (vim.uv or vim.loop).os_homedir() end
  return (home and home ~= "") and (home .. "/.local/state") or vim.fn.expand("~/.local/state")
end

local function state_file()
  if vim.env.NVIM_CONFIG_CHANNEL_FILE and vim.env.NVIM_CONFIG_CHANNEL_FILE ~= "" then
    return vim.env.NVIM_CONFIG_CHANNEL_FILE
  end
  -- Keep this byte-for-byte aligned with bin/nvim-config. stdpath("state")
  -- appends Neovim's application name (normally /nvim), which made the editor
  -- read a different file from the cross-process updater.
  return state_home() .. "/nvim-config/channel"
end

--- Accept only a branch name Git can resolve and that cannot escape a ref
--- path. Exported so every caller that takes a branch from the user -- the
--- channel selector and the dev-plugin fleet command both do -- validates it
--- the same way.
function M.valid(channel)
  local shape_valid = type(channel) == "string"
    and channel:match("^[%w][%w._/-]*$") ~= nil
    and channel ~= "@"
    and not channel:find("..", 1, true)
    and not channel:find("//", 1, true)
    and not channel:find("@{", 1, true)
    and not channel:match("[/.]$")
  if not shape_valid then return false end
  for component in channel:gmatch("[^/]+") do
    if component:sub(1, 1) == "."
        or component:sub(-1) == "."
        or component:sub(-5) == ".lock" then
      return false
    end
  end
  return true
end

local function read_file(path)
  local ok, lines = pcall(vim.fn.readfile, path, "", 1)
  if not ok or #lines == 0 then return nil end
  return vim.trim(lines[1])
end

function M.current()
  local requested = vim.env.NVIM_CONFIG_CHANNEL
  if requested and requested ~= "" then
    return M.valid(requested) and requested or DEFAULT_CHANNEL
  end

  local persisted = read_file(state_file())
  return M.valid(persisted) and persisted or DEFAULT_CHANNEL
end

function M.is_development()
  return M.current() ~= DEFAULT_CHANNEL
end

function M.default()
  return DEFAULT_CHANNEL
end

function M.state_file()
  return state_file()
end

return M
