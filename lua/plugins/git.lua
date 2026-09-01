return {
{
  "777lotto/git-panel.nvim",
  branch = require("config.channel").current(),
  main = "git_panel",
  cmd = { "GitPanel", "GitPanelSplit", "GitPanelConnection", "GitPanelDoctor" },
  opts = function() return require("config.git_panel").options() end,
  keys = {
    { "<leader>gg", "<cmd>GitPanel<cr>", desc = "Git panel (custom dashboard)" },
    { "<leader>gG", "<cmd>GitPanelSplit<cr>", desc = "Git panel (left split)" },
  },
},
}
