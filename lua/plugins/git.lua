return {
{
  "777lotto/git-panel.nvim",
  main = "git_panel",
  cmd = { "GitPanel", "GitPanelSplit" },
  opts = function()
    local app_cli = vim.fn.expand("~/.local/bin/gh-app")
    if vim.fn.executable(app_cli) == 1 then
      return {
        github = {
          gh_command = app_cli,
          merge_backend = "signed_git",
          timeout = 60000,
        },
      }
    end
    return { github = { merge_backend = "api" } }
  end,
  keys = {
    { "<leader>gg", "<cmd>GitPanel<cr>", desc = "Git panel (custom dashboard)" },
    { "<leader>gG", "<cmd>GitPanelSplit<cr>", desc = "Git panel (left split)" },
  },
},
}
