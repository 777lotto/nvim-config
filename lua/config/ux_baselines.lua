local M = {}
local values = {}

function M.record(name, value)
  assert(type(name) == "string" and name ~= "", "UX baseline name must be a non-empty string")
  assert(type(value) == "table", "UX baseline value must be a table")
  values[name] = vim.deepcopy(value)
  return value
end

function M.get(name)
  return values[name] and vim.deepcopy(values[name]) or nil
end

return M
