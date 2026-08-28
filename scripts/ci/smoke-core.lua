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
  for _, register in ipairs({ "+", "*" }) do
    local sent = { register .. " payload" }
    local copied, copy_error = pcall(provider.copy[register], sent, "v")
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
