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
      { "<leader>amm", "<cmd>AgentManager<cr>", desc = "Agent Manager" },
      { "<leader>amc", "<cmd>AgentManagerStart codex<cr>", desc = "Start Codex agent" },
      { "<leader>ams", "<cmd>AgentManagerSend<cr>", desc = "Send agent prompt" },
    },
    opts = {},
  },
}
