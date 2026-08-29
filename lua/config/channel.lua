local M = {}

local DEFAULT_CHANNEL = "bet"

local function state_file()
  if vim.env.NVIM_CONFIG_CHANNEL_FILE and vim.env.NVIM_CONFIG_CHANNEL_FILE ~= "" then
    return vim.env.NVIM_CONFIG_CHANNEL_FILE
  end
  return vim.fn.stdpath("state") .. "/nvim-config/channel"
end

local function valid(channel)
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
    return valid(requested) and requested or DEFAULT_CHANNEL
  end

  local persisted = read_file(state_file())
  return valid(persisted) and persisted or DEFAULT_CHANNEL
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
