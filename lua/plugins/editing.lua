return {
{
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    require("nvim-autopairs").setup({})
    local ok, cmp = pcall(require, "cmp")
    if ok then
      cmp.event:on("confirm_done",
        require("nvim-autopairs.completion.cmp").on_confirm_done())
    end
  end,
},

-- Add/change/delete surrounding pairs: ysiw" , cs"' , ds( , visual S to wrap.
{
  "kylechui/nvim-surround",
  version = "*",
  event = "VeryLazy",
  opts = {},
},

-- Auto-close / auto-rename HTML/JSX/TSX tags (uses the treesitter parsers above).
{
  "windwp/nvim-ts-autotag",
  ft = { "html", "xml", "markdown", "javascript", "typescript",
         "javascriptreact", "typescriptreact" },
  opts = {},
},

-- Fast structural jump: s + 2 chars. S = treesitter node select (normal/op only
-- so it does not clash with nvim-surround's visual-mode S).
{
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
    { "S", mode = { "n", "o" },      function() require("flash").treesitter() end, desc = "Flash Treesitter" },
  },
},

-- Highlight + list TODO/FIXME/HACK/NOTE; feeds Telescope and Trouble.
{
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPost", "BufNewFile" },
  opts = {},
  keys = {
    { "<leader>dt", "<cmd>Trouble todo toggle<cr>", desc = "TODOs (Trouble)" },
    { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "TODOs" },
  },
},

-- Sticky header showing the enclosing function/class you scrolled past.
{
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPost", "BufNewFile" },
  opts = { max_lines = 3 },
},

-- Indent guide lines + current-scope highlight.
{
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = { "BufReadPost", "BufNewFile" },
  opts = {},
},

-- Render color literals (#rrggbb, rgb(), hsl(), Tailwind) inline.
{
  "catgoose/nvim-colorizer.lua",
  event = "BufReadPre",
  ft = { "css", "scss", "html", "javascript", "typescript", "lua" },
  opts = { user_default_options = { names = false, tailwind = true } },
},

-- Per-directory session save/restore.
{
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {},
  keys = {
    { "<leader>Sd", function() require("persistence").stop() end, desc = "Don't save this session" },
    { "<leader>Sl", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>Sr", function() require("persistence").load() end, desc = "Restore session (cwd)" },
  },
},

-- Edit the filesystem as a buffer; '-' opens the parent directory.
{
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Oil",
  keys = { { "-", "<cmd>Oil<cr>", desc = "Open parent dir (Oil)" } },
  opts = {},
},

-- Visualize the undo history as a tree (paired with persistent undo).
{
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  keys = { { "<leader>fh", "<cmd>UndotreeToggle<cr>", desc = "Undo history" } },
  config = function()
    vim.opt.undofile = true -- persist undo across sessions so the tree survives restarts
  end,
},
}
