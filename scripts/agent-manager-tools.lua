local manifest_path = assert(arg[1], "Agent Manager mise.toml path is required")
local file = assert(io.open(manifest_path, "r"))
local tools = {}
local in_tools = false
for line in file:lines() do
  local section = line:match("^%s*%[([^]]+)%]%s*$")
  if section then
    in_tools = section == "tools"
  elseif in_tools then
    local name, configured = line:match("^%s*([%w_-]+)%s*=%s*(.-)%s*$")
    if name then
      tools[name] = configured:match('^"([^"]+)"$')
        or configured:match('^%{.-version%s*=%s*"([^"]+)".-%}$')
    end
  end
end
file:close()

local function version(name)
  local value = assert(tools[name], "missing tool pin: " .. name)
  assert(
    type(value) == "string" and value:match("^%d[%w._+-]*$"),
    "invalid tool pin: " .. name
  )
  return value
end

for _, name in ipairs({ "rust", "python", "uv" }) do
  io.write(name, "@", version(name), "\n")
end
