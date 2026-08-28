-- Treesitter support for Mise configuration is purely syntax-aware. It must
-- not depend on the optional mise executable being present.
local M = {}

local function path_parts(path)
  local normalized = path:gsub("\\", "/")
  return vim.split(normalized, "/", { plain = true, trimempty = true })
end

local function is_mise_filename(filename)
  if filename == "mise.toml" or filename == ".mise.toml" then return true end

  local suffix = filename:match("^%.?mise%.(.+)%.toml$")
  return suffix ~= nil and suffix:match("^[%w][%w_.-]*$") ~= nil
end

local function is_grouped_config(filename)
  if filename == "config.toml" then return true end

  local suffix = filename:match("^config%.(.+)%.toml$")
  return suffix ~= nil and suffix:match("^[%w][%w_.-]*$") ~= nil
end

function M.is_config_path(path)
  if type(path) ~= "string" or path == "" then return false end

  local parts = path_parts(path)
  local filename = parts[#parts]
  if not filename then return false end
  if is_mise_filename(filename) then return true end

  local parent = parts[#parts - 1]
  if (parent == "mise" or parent == ".mise") and is_grouped_config(filename) then
    return true
  end

  local grandparent = parts[#parts - 2]
  return parent == "conf.d"
    and (grandparent == "mise" or grandparent == ".mise")
    and filename:sub(1, 1) ~= "."
    and filename:match("%.toml$") ~= nil
end

function M.setup()
  vim.treesitter.query.add_predicate("is-mise?", function(_, _, source)
    if type(source) ~= "number" then return false end
    return M.is_config_path(vim.api.nvim_buf_get_name(source))
  end, { force = true })
end

return M
