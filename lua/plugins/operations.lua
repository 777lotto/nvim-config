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
      -- The plugin only accepts loopback. Tunnel lifecycle and SSH routing stay
      -- outside Neovim and follow the workstation network runbook.
      endpoint = "http://127.0.0.1:8792",
    },
  },
}
