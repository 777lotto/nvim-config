return {
{
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {},
  config = function()
    require("trouble").setup({
      -- SETTINGS START HERE
      win = {
        type = "split",      -- Force it to be a standard split (resizeable)
        position = "right",  -- Side of screen
        size = 0.3,          -- Use 30% of screen width (better than fixed 80)
      },
      -- SETTINGS END HERE
    })

    -- Keymaps
    vim.keymap.set("n", "<leader>db", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      { desc = "Buffer diagnostics (Trouble)" })
    vim.keymap.set("n", "<leader>dp", "<cmd>Trouble diagnostics toggle<cr>",
      { desc = "Project diagnostics (Trouble)" })
  end,
},
}
