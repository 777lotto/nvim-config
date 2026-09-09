local function install_agent_manager_runtime(plugin)
  if plugin._ and plugin._.is_local then
    coroutine.yield("Agent Manager dev checkout: runtime stays under DevPlugins/source-build control")
    return
  end

  local installer = plugin.dir .. "/ops/m5-release-install/install-current.sh"
  if vim.fn.executable(installer) ~= 1 then
    coroutine.yield("Agent Manager pin predates packaged runtime installation; leaving it unchanged")
    return
  end

  -- The installer runs inside the plugin checkout, whose own mise.toml is
  -- untrusted on a fresh machine. When python3 or another tool on PATH is a
  -- Mise shim, that untrusted config makes the shim refuse to run and the
  -- installer reports a missing Python instead. Trusting the pinned
  -- checkout's config for this one process adds no capability: Lazy is
  -- already executing that checkout's installer script.
  local result = vim.system({ installer }, {
    cwd = plugin.dir,
    text = true,
    env = {
      MISE_TRUSTED_CONFIG_PATHS = require("config.mise").trusted_config_paths(plugin.dir),
    },
  }):wait()
  local output = vim.trim(table.concat({ result.stdout or "", result.stderr or "" }, "\n"))
  if output ~= "" then coroutine.yield(output) end
  if result.code ~= 0 then
    error("Agent Manager packaged runtime installation failed with exit " .. tostring(result.code))
  end
end

return {
  {
    "777lotto/mcp-buff",
    branch = "bluff",
    main = "mcp_buff",
    cmd = { "McpBuff" },
    keys = {
      { "<leader>ar", "<cmd>McpBuff<cr>", desc = "MCP Buff review" },
    },
    opts = {
      -- WireGuard is an always-on workstation prerequisite. This dedicated SSH
      -- alias resolves to zemrip-server's WireGuard address; MCP Buff owns only
      -- its ephemeral loopback forward and never falls back to the LAN alias.
      endpoint = "http://127.0.0.1:8792",
      capability_cmd = { "pass", "show", "zemrip/mcp/admin-capability" },
      tunnel = {
        host = "zemrip-server",
      },
      -- The GitHub broker has a separate listener and bearer. Do not inherit
      -- either from Cloudflare: each tab owns its own capability cache and
      -- panel-scoped SSH process.
      github = {
        endpoint = "http://127.0.0.1:8793",
        capability_cmd = { "pass", "show", "zemrip/github/admin-capability" },
        tunnel = {
          host = "zemrip-server",
        },
      },
    },
  },

  {
    "777lotto/agent-manager.nvimz",
    branch = "bluff",
    build = install_agent_manager_runtime,
    pin = true,
    main = "agent_manager",
    cmd = {
      "AgentManager",
      "AgentManagerStart",
      "AgentManagerSend",
      "AgentManagerSteer",
      "AgentManagerInterrupt",
      "AgentManagerHealth",
      "AgentManagerClose",
    },
    keys = {
      { "<leader>am", "<cmd>AgentManager<cr>", desc = "Agent Manager" },
    },
    opts = {},
  },
}
