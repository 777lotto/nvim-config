-- Neovim configuration entrypoint.
-- Keep this file deliberately small; implementation lives under lua/config,
-- plugin specifications under lua/plugins, and reusable local plugins under
-- local-plugins/.
local requested_root = vim.env.NVIM_CONFIG_ROOT
if requested_root and requested_root ~= "" then
  -- Maintenance and verification may execute this init from a checkout other
  -- than stdpath("config"). Resolve every module from that same source tree.
  vim.opt.runtimepath:prepend(requested_root)
end

require("config.environment").setup()
require("config.mise").setup()
require("config.options")
require("config.keymaps")
require("config.diagnostics")
require("config.autocmds")
require("config.update").setup()
require("config.lazy")
