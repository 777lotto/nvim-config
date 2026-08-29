local root = assert(arg[1], "repository root argument is required")
local channel = require("config.channel").current()

if vim.env.NVIM_CONFIG_VERIFY_LOCK == "1" then
  -- lazy.nvim reloads the spec graph during restore/update. An isolated
  -- checkout must remain the source of truth across that reload.
  require("lazy.core.plugin").load()
  local lazy_config = require("lazy.core.config")
  for _, name in ipairs({ "UX-foundation.nvim", "UX-styling.nvim", "UX-chrome.nvim" }) do
    assert(lazy_config.plugins[name], "isolated Lazy spec reload lost " .. name)
  end
  require("lazy.manage.lock").update()
  local lock = vim.json.decode(table.concat(vim.fn.readfile(root .. "/lazy-lock.json"), "\n"))
  for _, name in ipairs({ "UX-foundation.nvim", "UX-styling.nvim", "UX-chrome.nvim" }) do
    assert(lock[name] and lock[name].branch == "bet", "lock regeneration lost " .. name)
  end
end

local function registration(plugin_id)
  for _, item in ipairs(require("ux_foundation").registrations()) do
    if item.manifest.plugin.id == plugin_id then return item end
  end
end

local foundation = require("ux_foundation")
local foundation_state = foundation.state()
assert(foundation.contract_version == 1, "UX Foundation contract changed")
assert(foundation_state.profile_id == "default" and foundation_state.session_entries == 0,
  "guarded integration applied a saved UX profile")

local chrome = require("ux_chrome")
local chrome_state = chrome.state()
assert(chrome_state.initialized, "UX Chrome did not initialize")
if channel ~= "bet" then
  assert(chrome.health().neovim_supported, "nightly Chrome rejected the tested Neovim runtime")
end
assert(registration("ux.chrome"), "UX Chrome did not register with Foundation")
for _, surface in ipairs({ "tabline", "statusline", "winbar", "statuscolumn", "windows", "scrollbar" }) do
  assert(chrome_state.ownership[surface] == "external", "Chrome owns guarded surface " .. surface)
  assert(not chrome_state.surfaces[surface].active, "Chrome activated guarded surface " .. surface)
end
assert(not vim.o.tabline:find("ux_chrome", 1, true), "Chrome replaced the live tabline")
assert(not vim.o.statusline:find("ux_chrome", 1, true), "Chrome replaced the live statusline")

local baselines = require("config.ux_baselines")
for _, name in ipairs({ "bufferline", "nvim_tree", "telescope" }) do
  assert(type(baselines.get(name)) == "table", "missing exact UX baseline: " .. name)
end

vim.cmd("UXStyling")
local styling = require("ux_styling")
local styling_state = styling._state()
assert(styling_state.foundation_available, "UX Styling could not reach Foundation")
assert(styling_state.workspace, "UX Styling workspace did not open")
assert(vim.deep_equal(styling_state.config.bufferline.baseline_setup, baselines.get("bufferline")),
  "Bufferline baseline drifted between boot and Styling")
assert(vim.deep_equal(styling_state.config.nvim_tree.baseline_setup, baselines.get("nvim_tree")),
  "nvim-tree baseline drifted between boot and Styling")
assert(vim.deep_equal(styling_state.config.telescope.baseline_setup, baselines.get("telescope")),
  "Telescope baseline drifted between boot and Styling")
for _, plugin_id in ipairs({
  "ux.chrome.bufferline",
  "ux.chrome.lualine",
  "ux.navigation.nvim_tree",
  "ux.navigation.telescope",
  "mcp.buff",
}) do
  assert(registration(plugin_id), "UX Styling omitted integration registration " .. plugin_id)
end
assert(styling.close(), "UX Styling workspace did not close cleanly")

local final_chrome = chrome.state()
for _, surface in ipairs({ "tabline", "statusline", "winbar", "statuscolumn", "windows", "scrollbar" }) do
  assert(not final_chrome.surfaces[surface].active,
    "Styling interaction activated guarded Chrome surface " .. surface)
end

io.stdout:write(("Guarded UX integration (%s) passed on Neovim %s with %d registrations\n"):format(
  channel,
  vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
  #foundation.registrations()
))
vim.cmd("quitall!")
