-- Neovim configuration entrypoint.
-- Keep this file deliberately small; implementation lives under lua/config,
-- plugin specifications under lua/plugins, and reusable local plugins under
-- local-plugins/.
require("config.environment").setup()
require("config.mise").setup()
require("config.options")
require("config.keymaps")
require("config.diagnostics")
require("config.autocmds")
require("config.update").setup()
require("config.lazy")
