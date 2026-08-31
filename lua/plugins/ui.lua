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
  opts = function()
    local setup_opts = {
      options = {
        mode = "buffers", -- Show all open buffers
        separator_style = "slant",
        always_show_bufferline = true,
      },
    }
    return require("config.ux_baselines").record("bufferline", setup_opts)
  end,
},

-- ===========================================================================
-- WHICH-KEY (Popup menu of your available keybindings)
-- ===========================================================================
{
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local wk = require("which-key")
    wk.setup({
      -- Keep the popup alphabetical while making case meaningful: all
      -- lowercase categories appear before the uppercase categories.
      sort = { "case", "alphanum", "mod" },
    })

    -- which-key reads each mapping's `desc` automatically. This list owns the
    -- category names and mirrors the case-aware alphabetical popup order.
    wk.add({
      { "<leader>a", group = "(a)gent" },
      { "<leader>b", group = "(b)uffer" },
      { "<leader>bm", group = "(m)ove buffer" },
      { "<leader>c", group = "(c)ode" },
      { "<leader>d", group = "(d)iagnostic" },
      { "<leader>e", group = "(e)dit", mode = { "n", "x" } },
      { "<leader>f", group = "(f)ile" },
      { "<leader>g", group = "(g)it" },
      { "<leader>n", group = "(n)avigate", mode = { "n", "x" } },
      { "<leader>q", group = "(q)uit" },
      { "<leader>s", group = "(s)earch", mode = { "n", "x" } },
      { "<leader>w", group = "(w)ord", mode = { "n", "x" } },
      { "<leader>S", group = "(S)ession" },
      { "<leader>T", group = "(T)erminal" },
      { "<leader>W", group = "(W)indow" },
    })
  end,
},

-- ===========================================================================
-- WINDOW MAXIMIZER (Zoom the focused split to full screen and back)
-- ===========================================================================
{
  "szw/vim-maximizer",
  keys = {
    { "<leader>Wm", "<cmd>MaximizerToggle<cr>", desc = "Maximize / restore window" },
  },
},
}
