return {
{
  "nvim-pack/nvim-spectre",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("spectre").setup()

    -- Add keymaps for it
    local keymap = vim.keymap
    keymap.set("n", "<leader>sr", "<cmd>Spectre<cr>", { desc = "Search and Replace (Project)" })
    keymap.set("n", "<leader>swr", "<cmd>Spectre word<cr>", { desc = "Search/Replace word under cursor" })
    keymap.set("v", "<leader>sr", "<cmd>Spectre visual<cr>", { desc = "Search/Replace selected text" })
  end,
},
}
