local root = assert(arg[1], "repository root argument is required")
local action = assert(arg[2], "action argument is required")

vim.opt.runtimepath:prepend(vim.fn.fnamemodify(root, ":p"))
local toolchain = require("config.toolchain")

local function assert_unique(values, label)
  local seen = {}
  for _, value in ipairs(values) do
    assert(not seen[value], ("duplicate %s entry: %s"):format(label, value))
    seen[value] = true
  end
  return seen
end

if action == "get" then
  local section = assert(arg[3], "section is required")
  local key = assert(arg[4], "key is required")
  local value = assert(toolchain[section] and toolchain[section][key], "unknown toolchain value")
  io.write(tostring(value), "\n")
elseif action == "validate" then
  assert(#toolchain.parsers > 0, "parser inventory is empty")
  assert(#toolchain.parser_filetypes > 0, "parser filetype inventory is empty")
  assert(#toolchain.lsp_servers > 0, "LSP inventory is empty")
  assert(#toolchain.mason_packages > #toolchain.lsp_servers, "Mason inventory is incomplete")
  assert(toolchain.node.minimum_major <= toolchain.node.recommended_major)
  assert(toolchain.node.recommended_major < toolchain.node.canary_major)
  assert_unique(toolchain.parsers, "parser")
  assert_unique(toolchain.parser_filetypes, "parser filetype")
  assert_unique(toolchain.lsp_servers, "LSP")
  local mason_packages = assert_unique(toolchain.mason_packages, "Mason package")
  assert_unique(toolchain.node_backed_packages, "Node-backed package")
  for _, package in ipairs(toolchain.node_backed_packages) do
    assert(mason_packages[package], "Node-backed package missing from Mason inventory: " .. package)
  end
  local nvmrc = assert(io.open(root .. "/.nvmrc", "r"))
  local recommended_node = nvmrc:read("*l")
  nvmrc:close()
  assert(tonumber(recommended_node) == toolchain.node.recommended_major, ".nvmrc differs from recommended Node")
  print("Toolchain manifest validation passed")
else
  error("unknown toolchain action: " .. action)
end
