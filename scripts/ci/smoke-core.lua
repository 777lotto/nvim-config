local root = assert(arg[1], "repository root argument is required")
local expected_clipboard = assert(arg[2], "expected clipboard mode argument is required")

vim.opt.runtimepath:prepend(vim.fn.fnamemodify(root, ":p"))

local environment = require("config.environment")
environment.setup()
require("config.mise").setup()
require("config.options")
require("config.keymaps")
require("config.diagnostics")
require("config.autocmds")
require("config.update").setup()

local toolchain = require("config.toolchain")
assert(toolchain.node.minimum_major == 22, "unexpected Node compatibility floor")
assert(toolchain.node.recommended_major == 24, "unexpected recommended Node release")
assert(toolchain.node.canary_major == 26, "unexpected Node canary release")
assert(#toolchain.parsers >= 10, "Treesitter parser inventory is incomplete")
assert(#toolchain.mason_packages >= 10, "Mason package inventory is incomplete")
assert(vim.list_contains(vim.treesitter.query.list_predicates(), "is-mise?"), "Mise query predicate is missing")

local operations = assert(loadfile(root .. "/lua/plugins/operations.lua"))()
local mcp_buff = assert(operations[1], "MCP Buff plugin spec is missing")
assert(mcp_buff[1] == "777lotto/mcp-buff", "unexpected MCP Buff repository")
assert(mcp_buff.branch == "bet", "MCP Buff must consume its production branch")
assert(mcp_buff.opts.endpoint == "http://127.0.0.1:8792", "MCP Buff endpoint must remain loopback-only")

assert(
  environment.clipboard_mode == expected_clipboard,
  ("expected clipboard mode %s, got %s"):format(expected_clipboard, environment.clipboard_mode)
)
assert(vim.fn.exists(":EnvironmentInfo") == 2, ":EnvironmentInfo was not registered")
assert(vim.fn.exists(":NvimConfigUpdate") == 2, ":NvimConfigUpdate was not registered")
assert(vim.fn.exists(":NvimConfigDoctor") == 2, ":NvimConfigDoctor was not registered")

print(("Core smoke passed with clipboard mode %s"):format(environment.clipboard_mode))
