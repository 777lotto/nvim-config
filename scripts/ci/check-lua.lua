local root = arg[1] or "."
local files = vim.fn.globpath(root, "**/*.lua", false, true)
local failures = {}

table.sort(files)

for _, path in ipairs(files) do
  local chunk, message = loadfile(path)
  if not chunk then
    table.insert(failures, ("%s: %s"):format(path, message))
  end
end

if #files == 0 then
  error(("no Lua files found below %s"):format(root))
end

if #failures > 0 then
  error("Lua compilation failed:\n" .. table.concat(failures, "\n"))
end

print(("Lua compilation passed for %d files"):format(#files))
