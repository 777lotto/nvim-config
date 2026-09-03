local root = assert(arg[1], "repository root argument is required")
local expected_clipboard = assert(arg[2], "expected clipboard mode argument is required")

vim.opt.runtimepath:prepend(vim.fn.fnamemodify(root, ":p"))
vim.env.NVIM_CONFIG_CHANNEL = "bet"

local environment = require("config.environment")
environment.setup()
require("config.mise").setup()
require("config.options")
require("config.keymaps")
require("config.diagnostics")
require("config.autocmds")
require("config.update").setup()

local toolchain = require("config.toolchain")
assert(toolchain.neovim.minimum == "0.12.2", "unexpected Neovim compatibility floor")
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
assert(vim.deep_equal(mcp_buff.opts.capability_cmd,
  { "pass", "show", "zemrip/mcp/admin-capability" }),
  "MCP Buff must read the local pass-backed admin capability")
assert(mcp_buff.opts.tunnel.host == "zemrip-server",
  "MCP Buff must use the WireGuard zemrip-server SSH alias")
assert(not mcp_buff.opts.tunnel.host:find("lan", 1, true),
  "MCP Buff must not fall back to a LAN SSH alias")
assert(mcp_buff.keys[1][1] == "<leader>ar", "MCP Buff review must use <leader>ar")

local agent_manager = assert(operations[2], "Agent Manager plugin spec is missing")
assert(agent_manager[1] == "777lotto/agent-manager.nvimz", "unexpected Agent Manager repository")
assert(agent_manager.branch == "bet", "Agent Manager must consume its production branch")
assert(agent_manager.main == "agent_manager", "Agent Manager setup module is incorrect")
for _, command in ipairs({
  "AgentManager",
  "AgentManagerStart",
  "AgentManagerSend",
  "AgentManagerSteer",
  "AgentManagerInterrupt",
  "AgentManagerHealth",
  "AgentManagerClose",
}) do
  assert(vim.list_contains(agent_manager.cmd, command), command .. " is not lazy-loadable")
end
assert(vim.deep_equal(agent_manager.keys, {
  { "<leader>amm", "<cmd>AgentManager<cr>", desc = "Agent Manager" },
  { "<leader>amc", "<cmd>AgentManagerStart codex<cr>", desc = "Start Codex agent" },
  { "<leader>ams", "<cmd>AgentManagerSend<cr>", desc = "Send agent prompt" },
}), "Agent Manager shortcuts changed unexpectedly")

local git_specs = assert(loadfile(root .. "/lua/plugins/git.lua"))()
assert(git_specs[1].branch == "bet", "Git Panel must consume the selected production channel")
assert(vim.list_contains(git_specs[1].cmd, "GitPanelConnection"),
  "Git Panel connection command is not lazy-loadable")
assert(vim.list_contains(git_specs[1].cmd, "GitPanelDoctor"),
  "Git Panel doctor command is not lazy-loadable")

local git_panel_config = require("config.git_panel")
local function helper_options(name)
  return git_panel_config.options({
    expand = function(path) return path end,
    executable = function(path) return path:find(name, 1, true) ~= nil end,
  })
end
local broker_options = helper_options("gh-agent").github
assert(broker_options.profile == "zemrip-broker", "agent plane did not select the broker profile")
assert(broker_options.transport == "curl", "broker profile must use curl")
assert(broker_options.remote_path_prefix == "github/git", "broker Git prefix is missing")
assert(broker_options.api_url == "http://10.77.0.1:8790/github/api",
  "broker REST endpoint is incorrect")
assert(broker_options.allow_insecure_http == true, "private plaintext broker needs explicit opt-in")
assert(broker_options.token_provider == nil, "broker profile must remain credential-free")
assert(broker_options.profiles["github-cli"] and broker_options.profiles["public-rest"],
  "portable connection profiles are missing")

local app_options = helper_options("gh-app").github
assert(app_options.profile == "github-app" and app_options.merge_backend == "signed_git",
  "workstation App profile lost signed merge behavior")
local portable_options = git_panel_config.options({
  expand = function(path) return path end,
  executable = function() return false end,
}).github
assert(portable_options.profile == nil and portable_options.merge_backend == "api",
  "portable GitPanel defaults changed unexpectedly")

vim.env.NVIM_CONFIG_CHANNEL = "bluff"
local nightly_operations = assert(loadfile(root .. "/lua/plugins/operations.lua"))()
assert(nightly_operations[1].branch == "bluff",
  "MCP Buff did not follow the nightly channel")
assert(nightly_operations[2].branch == "bluff",
  "Agent Manager did not follow the nightly channel")
assert(assert(loadfile(root .. "/lua/plugins/git.lua"))()[1].branch == "bluff",
  "Git Panel did not follow the nightly channel")
vim.env.NVIM_CONFIG_CHANNEL = "nightly/feature-1"
assert(require("config.channel").current() == "nightly/feature-1",
  "valid nested channel was rejected")
vim.env.NVIM_CONFIG_CHANNEL = "invalid channel"
assert(require("config.channel").current() == "bet", "invalid Lua channel did not fall back safely")
vim.env.NVIM_CONFIG_CHANNEL = "nightly/.hidden"
assert(require("config.channel").current() == "bet", "invalid Git path component was accepted")
vim.env.NVIM_CONFIG_CHANNEL = "bet"

local original_channel_file = vim.env.NVIM_CONFIG_CHANNEL_FILE
local original_state_home = vim.env.XDG_STATE_HOME
local original_channel_home = vim.env.HOME
vim.env.NVIM_CONFIG_CHANNEL_FILE = nil
vim.env.XDG_STATE_HOME = "/tmp/nvim-config-state-home"
assert(require("config.channel").state_file() == "/tmp/nvim-config-state-home/nvim-config/channel",
  "Lua channel path drifted from the updater's XDG state path")
vim.env.XDG_STATE_HOME = nil
vim.env.HOME = "/tmp/nvim-config-home"
assert(require("config.channel").state_file() == "/tmp/nvim-config-home/.local/state/nvim-config/channel",
  "Lua channel path drifted from the updater's HOME fallback")
vim.env.NVIM_CONFIG_CHANNEL_FILE = original_channel_file
vim.env.XDG_STATE_HOME = original_state_home
vim.env.HOME = original_channel_home

local channel_module = require("config.channel")
assert(channel_module.valid("bluff") and channel_module.valid("nightly/feature-1"),
  "the exported channel validator rejected a usable branch")
for _, rejected in ipairs({ "invalid channel", "nightly/.hidden", "../escape", "bet.lock", "@" }) do
  assert(not channel_module.valid(rejected),
    "the exported channel validator accepted " .. rejected)
end

-- Which lockfile a session may write. An editing session must never be handed
-- the committed one: lazy.nvim rewrites it from the resolved plugin
-- directories, which drops the dev/ fleet's pins and picks up whatever the
-- shared plugin root currently holds, leaving a modified tracked file that
-- `nvim-config update` then refuses to fast-forward over.
local lockfile = require("config.lockfile")
local lock_root, lock_state = vim.fn.tempname(), vim.fn.tempname()
vim.fn.mkdir(lock_root, "p")
vim.fn.writefile({ '{ "probe": 1 }' }, lock_root .. "/lazy-lock.json")

local committed_path, is_committed = lockfile.select({
  config_root = lock_root, state_dir = lock_state, use_dev = false, maintenance = true,
})
assert(is_committed and committed_path == lock_root .. "/lazy-lock.json",
  "a maintenance run resolving the committed pins must write them back")

local scratch_path, scratch_is_committed = lockfile.select({
  config_root = lock_root, state_dir = lock_state, use_dev = false, maintenance = false,
})
assert(not scratch_is_committed, "an editing session must not write the committed lockfile")
assert(scratch_path == lock_state .. "/" .. lockfile.SCRATCH_BASENAME,
  "the scratch lockfile left the per-machine state directory")
assert(table.concat(vim.fn.readfile(scratch_path), "\n") == '{ "probe": 1 }',
  "the scratch lockfile was not seeded from the committed pins")

local dev_path, dev_is_committed = lockfile.select({
  config_root = lock_root, state_dir = lock_state, use_dev = true, maintenance = true,
})
assert(not dev_is_committed and dev_path == scratch_path,
  "dev matching must deny the committed lockfile even on a maintenance run")

vim.fn.writefile({ '{ "probe": 2 }' }, scratch_path)
lockfile.select({
  config_root = lock_root, state_dir = lock_state, use_dev = false, maintenance = false,
})
assert(table.concat(vim.fn.readfile(scratch_path), "\n") == '{ "probe": 2 }',
  "a scratch lockfile newer than the committed pins was overwritten")
vim.fn.delete(lock_root, "rf")
vim.fn.delete(lock_state, "rf")

local registered = vim.api.nvim_get_commands({})
for _, command in ipairs({ "NvimUpdate", "NvimChannel", "NvimConfigDoctor", "DevPlugins" }) do
  assert(registered[command], command .. " is not registered")
end
-- The branch argument is the whole point of the command, so it must stay
-- optional rather than becoming required or being dropped.
assert(registered.DevPlugins.nargs == "?", "DevPlugins must take an optional branch")

-- :DevPlugins shells out to the fleet script, so stub the spawn and assert on
-- the command and environment it would have run. Both refusals must happen
-- before any process starts: one bad keystroke should not clone six
-- repositories onto a production install that has no fleet by design.
local update = require("config.update")
local original_root, original_dev = vim.env.NVIM_CONFIG_ROOT, vim.env.NVIM_DEV_DIR
local original_notify, original_system = vim.notify, vim.system
local notices, spawned = {}, nil
vim.notify = function(message) notices[#notices + 1] = message end
vim.system = function(command, options)
  spawned = { command = command, options = options }
  return { wait = function() return { code = 0 } end }
end
vim.env.NVIM_CONFIG_ROOT = root
vim.env.NVIM_DEV_DIR = root .. "/dev"

update.dev_plugins("../escape")
assert(notices[#notices]:match("not a usable branch name"), "DevPlugins accepted a malformed branch")
assert(not spawned, "DevPlugins spawned a process for a malformed branch")

update.dev_plugins("bluff")
assert(notices[#notices]:match("no plugin fleet at"), "DevPlugins did not refuse an absent fleet")
assert(notices[#notices]:match("plugins:clone"), "the fleet refusal does not say how to create one")
assert(not spawned, "DevPlugins spawned a process with no fleet on disk")

local fleet = vim.fn.tempname()
vim.fn.mkdir(fleet, "p")
vim.env.NVIM_DEV_DIR = fleet
update.dev_plugins("bluff")
assert(spawned, "DevPlugins did not run the fleet script")
assert(spawned.command[1]:match("scripts/dev%-plugins%.sh$") and spawned.command[2] == "sync",
  "DevPlugins ran the wrong command: " .. vim.inspect(spawned.command))
assert(not vim.list_contains(spawned.command, "--no-color"),
  "dev-plugins.sh takes no flags; --no-color belongs to the nvim-config CLI")
assert(spawned.options.env.NVIM_DEV_GIT_BRANCH == "bluff",
  "DevPlugins did not pass the chosen branch to the fleet script")
assert(not spawned.options.clear_env,
  "the fleet script must inherit the session environment, not replace it")
vim.fn.delete(fleet, "rf")

update.running = false
vim.notify, vim.system = original_notify, original_system
vim.env.NVIM_CONFIG_ROOT, vim.env.NVIM_DEV_DIR = original_root, original_dev

local ux_specs = assert(loadfile(root .. "/lua/plugins/ux.lua"))()
local foundation, chrome, styling = ux_specs[1], ux_specs[2], ux_specs[3]
assert(foundation[1] == "777lotto/UX-foundation.nvim" and foundation.lazy == false,
  "UX Foundation must load eagerly")
assert(foundation.branch == "bet" and foundation.opts.load_active == false,
  "UX Foundation must use the selected channel without applying a profile")
assert(chrome[1] == "777lotto/UX-chrome.nvim" and chrome.branch == "bet",
  "UX Chrome spec is missing or on the wrong channel")
for _, surface in ipairs({ "tabline", "statusline", "winbar", "statuscolumn", "windows", "scrollbar" }) do
  assert(chrome.opts.ownership[surface] == "external",
    "UX Chrome must not take over " .. surface .. " during the compatibility soak")
end
assert(styling[1] == "777lotto/UX-styling.nvim" and styling.cmd == "UXStyling",
  "UX Styling must remain command-lazy")

local lock = vim.json.decode(table.concat(vim.fn.readfile(root .. "/lazy-lock.json"), "\n"))
for _, name in ipairs({ "UX-foundation.nvim", "UX-styling.nvim", "UX-chrome.nvim" }) do
  local pin = assert(lock[name], "production lock is missing " .. name)
  assert(pin.branch == "bet", name .. " production pin must target bet")
  assert(type(pin.commit) == "string" and pin.commit:match("^[0-9a-f]+$") and #pin.commit == 40,
    name .. " production lock commit is invalid")
end

local baselines = require("config.ux_baselines")
local marker = function() return "retained" end
baselines.record("bufferline", { options = { mode = "buffers", callback = marker } })
local styling_opts = styling.opts()
assert(styling_opts.bufferline.baseline_setup.options.callback == marker,
  "UX Styling lost callbacks from the exact Bufferline setup baseline")
styling_opts.bufferline.baseline_setup.options.mode = "tabs"
assert(baselines.get("bufferline").options.mode == "buffers",
  "UX baseline consumers can mutate the retained setup input")

local ui_specs = assert(loadfile(root .. "/lua/plugins/ui.lua"))()
local which_key
for _, spec in ipairs(ui_specs) do
  if spec[1] == "folke/which-key.nvim" then which_key = spec end
end
assert(which_key, "which-key plugin spec is missing")

local which_key_setup
local which_key_groups
local original_which_key = package.loaded["which-key"]
package.loaded["which-key"] = {
  setup = function(options) which_key_setup = options end,
  add = function(groups) which_key_groups = groups end,
}
which_key.config()
package.loaded["which-key"] = original_which_key

assert(
  vim.deep_equal(which_key_setup.sort, { "case", "alphanum", "mod" }),
  "which-key must sort lowercase groups before uppercase groups"
)
local expected_groups = {
  ["<leader>a"] = "(a)gent",
  ["<leader>am"] = "(m)anager",
  ["<leader>b"] = "(b)uffer",
  ["<leader>c"] = "(c)ode",
  ["<leader>d"] = "(d)iagnostic",
  ["<leader>e"] = "(e)dit",
  ["<leader>f"] = "(f)ile",
  ["<leader>g"] = "(g)it",
  ["<leader>n"] = "(n)avigate",
  ["<leader>q"] = "(q)uit",
  ["<leader>s"] = "(s)earch",
  ["<leader>w"] = "(w)ord",
  ["<leader>S"] = "(S)ession",
  ["<leader>T"] = "(T)erminal",
  ["<leader>W"] = "(W)indow",
}
for _, item in ipairs(which_key_groups) do
  if expected_groups[item[1]] then
    assert(item.group == expected_groups[item[1]], "unexpected which-key group for " .. item[1])
    expected_groups[item[1]] = nil
  end
end
assert(next(expected_groups) == nil, "one or more which-key groups are missing")

local function assert_mapping(mode, lhs, description)
  local mapping = vim.fn.maparg(lhs, mode, false, true)
  assert(type(mapping) == "table" and mapping.lhs, "missing mapping " .. lhs)
  assert(mapping.desc == description, ("unexpected description for %s: %s"):format(lhs, tostring(mapping.desc)))
  return mapping
end

assert(vim.fn.maparg("<leader>aa", "n") == "", "retired Agent Manager shortcut is still mapped")
local file_rename = assert_mapping("n", "<leader>fn", "File name / rename")
assert_mapping("n", "<leader>fr", "Redo")
assert_mapping("n", "<leader>fu", "Undo")

-- Exercise the rename mapping against a disposable real file. This proves the
-- prompt result changes both the path on disk and the existing buffer name.
local rename_root = vim.fn.tempname()
local old_path = rename_root .. "/before.txt"
local new_path = rename_root .. "/after.txt"
vim.fn.mkdir(rename_root, "p")
vim.fn.writefile({ "rename smoke" }, old_path)
local original_input = vim.ui.input
local original_notify = vim.notify
local rename_ok, rename_error = pcall(function()
  vim.cmd("edit " .. vim.fn.fnameescape(old_path))
  vim.ui.input = function(options, callback)
    assert(options.default == "before.txt", "file rename prompt has the wrong default")
    callback("after.txt")
  end
  vim.notify = function() end
  file_rename.callback()
  assert(vim.uv.fs_stat(old_path) == nil, "file rename left the old path behind")
  assert(vim.uv.fs_stat(new_path), "file rename did not create the new path")
  assert(vim.fs.normalize(vim.api.nvim_buf_get_name(0)) == new_path, "file rename did not update the buffer name")
end)
vim.ui.input = original_input
vim.notify = original_notify
pcall(vim.cmd, "bdelete!")
vim.fn.delete(rename_root, "rf")
assert(rename_ok, rename_error)

assert(
  environment.clipboard_mode == expected_clipboard,
  ("expected clipboard mode %s, got %s"):format(expected_clipboard, environment.clipboard_mode)
)

-- The resolved mode must also be the provider that was installed. "native"
-- deliberately leaves g:clipboard unset so Neovim picks a local provider,
-- while each SSH mode wires its own copy-only table.
local expected_providers = {
  bridge = "Toughbook bridge (copy only)",
  osc52 = "OSC 52 (copy only)",
}
local expected_provider = expected_providers[expected_clipboard]
local configured = type(vim.g.clipboard) == "table" and vim.g.clipboard.name or nil
assert(
  configured == expected_provider,
  ("expected clipboard provider %s, got %s"):format(tostring(expected_provider), tostring(configured))
)
assert(vim.fn.exists(":EnvironmentInfo") == 2, ":EnvironmentInfo was not registered")
assert(vim.fn.exists(":NvimConfigUpdate") == 2, ":NvimConfigUpdate was not registered")
assert(vim.fn.exists(":NvimConfigDoctor") == 2, ":NvimConfigDoctor was not registered")
assert(vim.fn.exists(":NvimUpdate") == 2, ":NvimUpdate was not registered")
assert(vim.fn.exists(":NvimChannel") == 2, ":NvimChannel was not registered")
local channel_choices = require("config.update").channel_choices()
assert(channel_choices[1].id == "bet" and channel_choices[1].loaded,
  "channel picker did not identify the loaded production channel")
assert(channel_choices[2].id == "bluff", "channel picker is missing the integration channel")

print(("Core smoke passed with clipboard mode %s"):format(environment.clipboard_mode))

-- Clipboard policy matrix, resolved in-process so the coverage is identical on
-- a workstation that has the bridge helper and on a CI runner that does not.
-- `auto` may select the bridge only when the helper is executable; an explicit
-- NVIM_CLIPBOARD must win either way.
local original_home = vim.env.HOME
local original_ssh_tty = vim.env.SSH_TTY
local original_ssh_connection = vim.env.SSH_CONNECTION
local original_requested = vim.env.NVIM_CLIPBOARD

local function isolated_home(with_helper)
  local home = vim.fn.tempname()
  vim.fn.mkdir(home .. "/.local/bin", "p")
  if with_helper then
    local helper = home .. "/.local/bin/toughbook-copy"
    local handle = assert(io.open(helper, "w"), "could not write the bridge helper stub")
    handle:write("#!/bin/sh\ncat >/dev/null\n")
    handle:close()
    assert(vim.uv.fs_chmod(helper, 493), "could not make the bridge helper executable")
  end
  return home
end

local homes = { [true] = isolated_home(true), [false] = isolated_home(false) }

local function resolved_policy(helper_present, ssh, requested)
  vim.env.HOME = homes[helper_present]
  vim.env.SSH_TTY = ssh and "/dev/pts/0" or nil
  vim.env.SSH_CONNECTION = nil
  vim.env.NVIM_CLIPBOARD = requested
  vim.g.clipboard = nil
  package.loaded["config.environment"] = nil
  local reloaded = require("config.environment")
  reloaded.setup()
  return reloaded.clipboard_mode, type(vim.g.clipboard) == "table" and vim.g.clipboard.name or nil
end

-- Exercise the provider itself, not just the name it registered. A copy-only
-- provider must accept a yank even when the helper cannot be spawned, and each
-- register must serve back exactly what was last sent to *that* register.
local function assert_round_trip(description)
  local provider = vim.g.clipboard
  if type(provider) ~= "table" then
    return
  end
  -- A distinct regtype per register catches a provider that drops or crosses
  -- the mode as well as one that crosses the text.
  local regtypes = { ["+"] = "v", ["*"] = "V" }
  for _, register in ipairs({ "+", "*" }) do
    local sent = { register .. " payload" }
    local copied, copy_error = pcall(provider.copy[register], sent, regtypes[register])
    assert(copied, ("clipboard copy to %q (%s) raised: %s"):format(register, description, tostring(copy_error)))
  end
  for _, register in ipairs({ "+", "*" }) do
    local pasted = provider.paste[register]()
    assert(
      type(pasted) == "table" and type(pasted[1]) == "table",
      ("clipboard paste from %q (%s) returned no register payload"):format(register, description)
    )
    assert(
      pasted[1][1] == register .. " payload",
      ("clipboard paste from %q (%s): expected %q, got %q"):format(
        register,
        description,
        register .. " payload",
        tostring(pasted[1][1])
      )
    )
    assert(
      pasted[2] == regtypes[register],
      ("clipboard paste regtype from %q (%s): expected %q, got %q"):format(
        register,
        description,
        regtypes[register],
        tostring(pasted[2])
      )
    )
  end
end

-- pcall so the isolated homes and the real environment are restored even when
-- a case fails.
local matrix_ok, matrix_error = pcall(function()
  for _, case in ipairs({
    { helper = true, ssh = true, expected = "bridge" },
    { helper = false, ssh = true, expected = "osc52" },
    { helper = true, ssh = false, expected = "native" },
    { helper = false, ssh = false, expected = "native" },
    { helper = true, ssh = true, requested = "osc52", expected = "osc52" },
    { helper = true, ssh = true, requested = "native", expected = "native" },
    { helper = false, ssh = true, requested = "bridge", expected = "bridge" },
    { helper = false, ssh = false, requested = "bridge", expected = "bridge" },
  }) do
    local mode, provider = resolved_policy(case.helper, case.ssh, case.requested)
    local description = ("helper=%s ssh=%s requested=%s"):format(
      tostring(case.helper),
      tostring(case.ssh),
      tostring(case.requested)
    )
    assert(
      mode == case.expected,
      ("clipboard policy (%s): expected %s, got %s"):format(description, case.expected, mode)
    )
    assert(
      provider == expected_providers[case.expected],
      ("clipboard provider (%s): expected %s, got %s"):format(
        description,
        tostring(expected_providers[case.expected]),
        tostring(provider)
      )
    )
    assert_round_trip(description)
  end
end)

for _, home in pairs(homes) do
  vim.fn.delete(home, "rf")
end
vim.env.HOME = original_home
vim.env.SSH_TTY = original_ssh_tty
vim.env.SSH_CONNECTION = original_ssh_connection
vim.env.NVIM_CLIPBOARD = original_requested
assert(matrix_ok, matrix_error)

print("Clipboard policy matrix passed with and without the bridge helper")
