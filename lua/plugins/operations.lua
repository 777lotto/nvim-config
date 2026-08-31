return {
  {
    "777lotto/mcp-buff",
    branch = require("config.channel").current(),
    main = "mcp_buff",
    cmd = { "McpBuff" },
    keys = {
      { "<leader>am", "<cmd>McpBuff<cr>", desc = "MCP Buff" },
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
    },
  },
}
