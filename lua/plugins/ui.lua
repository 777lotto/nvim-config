return {
{
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000, -- Make sure this is loaded first
  config = function()
    require("catppuccin").setup({ flavour = "macchiato" })
    vim.cmd.colorscheme("catppuccin")
  end,
},

{
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
  config = function()
    -- Follow the active colorscheme, including changes made at runtime.
    require("lualine").setup({ options = { theme = "auto" } })
  end,
},

{
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  opts = {
    options = {
      mode = "buffers", -- Show all open buffers
      separator_style = "slant",
      always_show_bufferline = true,
    },
  },
},

-- ===========================================================================
-- WHICH-KEY (Popup menu of your available keybindings)
-- ===========================================================================
{
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local wk = require("which-key")
    wk.setup({})

    -- Optional: friendly names for your <leader> prefixes.
    -- You do NOT need to register individual keys here — which-key reads
    -- the `desc` from every mapping you already created automatically.
    wk.add({
      { "<leader>f", group = "Find / Files" },
      { "<leader>e", group = "Edit", mode = { "n", "x" } },
      { "<leader>n", group = "Navigate", mode = { "n", "x" } },
      { "<leader>s", group = "Window / Search" },
      { "<leader>x", group = "Diagnostics" },
      { "<leader>b", group = "Buffers" },
      { "<leader>g", group = "Git" },
      { "<leader>t", group = "Tab bar (buffers)" },
      { "<leader>tm", group = "Tab bar: move" },
      { "<leader>c", group = "Code" },
      { "<leader>q", group = "Quit / Session" },
    })
  end,
},

-- ===========================================================================
-- WINDOW MAXIMIZER (Zoom the focused split to full screen and back)
-- ===========================================================================
{
  "szw/vim-maximizer",
  keys = {
    { "<leader>sm", "<cmd>MaximizerToggle<cr>", desc = "Maximize / restore window" },
  },
},
}
