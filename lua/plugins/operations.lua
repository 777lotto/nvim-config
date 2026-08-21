return {
  {
    "777lotto/mcp-buff",
    branch = "bet",
    main = "mcp_buff",
    cmd = { "McpBuff" },
    keys = {
      { "<leader>mb", "<cmd>McpBuff<cr>", desc = "Cloudflare write tickets" },
    },
    opts = {
      -- The plugin only accepts loopback. Tunnel lifecycle and SSH routing stay
      -- outside Neovim and follow the workstation network runbook.
      endpoint = "http://127.0.0.1:8792",
    },
  },
}
