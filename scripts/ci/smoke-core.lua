local root = assert(arg[1], "repository root argument is required")
local expected_clipboard = assert(arg[2], "expected clipboard mode argument is required")

vim.opt.runtimepath:prepend(vim.fn.fnamemodify(root, ":p"))

local environment = require("config.environment")
environment.setup()
require("config.options")
require("config.keymaps")
require("config.diagnostics")
require("config.autocmds")

assert(
  environment.clipboard_mode == expected_clipboard,
  ("expected clipboard mode %s, got %s"):format(expected_clipboard, environment.clipboard_mode)
)
assert(vim.fn.exists(":EnvironmentInfo") == 2, ":EnvironmentInfo was not registered")

print(("Core smoke passed with clipboard mode %s"):format(environment.clipboard_mode))
