-- =============================================================================
-- File: init.lua
-- Author: Your Name
-- Description: Complete Neovim configuration for an IDE-like experience
-- Last Updated: 2025-09-11 (Updated for Neovim 0.11 LSP changes)
-- =============================================================================

-- =============================================================================
-- BOOTSTRAP LAZY.NVIM (Package Manager)
-- =============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
-- GLOBAL OPTIONS
-- =============================================================================
vim.g.mapleader = " " -- Set the leader key to the space bar

vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.tabstop = 2           -- Number of spaces a tab is
vim.opt.shiftwidth = 2        -- Number of spaces to indent
vim.opt.expandtab = true      -- Use spaces instead of tabs
vim.opt.smartindent = true    -- Be smart about indentation
vim.opt.wrap = true           -- Enable wrapping
vim.opt.linebreak = true      -- Wrap lines at convenient points (words) NOT characters
vim.opt.breakindent = true    -- Maintain indentation when wrapping
vim.opt.termguicolors = true  -- Enable true color support
vim.opt.scrolloff = 8         -- Keep 8 lines of context around the cursor
vim.opt.mouse = 'a'           -- Enable mouse support
vim.opt.timeoutlen = 500      -- Wait 500ms for a key sequence (snappier which-key popup)

-- =============================================================================
-- CLIPBOARD OVER SSH (OSC 52)
-- =============================================================================
-- When this nvim runs over SSH, its system clipboard would otherwise be the
-- HOST machine's clipboard (pbcopy/pbpaste on macOS). OSC 52 instead routes
-- yanks back to the LOCAL terminal's clipboard (Konsole supports OSC 52 write).
-- Konsole blocks OSC 52 reads, so paste stays on Konsole's Ctrl+Shift+V; the
-- paste handlers below return empty so `"+p` can't silently give stale text.
if vim.env.SSH_TTY then
  vim.opt.clipboard = "unnamedplus"
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = function() return { {}, "" } end, ["*"] = function() return { {}, "" } end },
  }
end

-- =============================================================================
-- KEYMAPS
-- =============================================================================
local keymap = vim.keymap

-- Remap command key to backtick
keymap.set('n', '`', ':')

-- Save file
keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
keymap.set("n", "<leader>W", "<cmd>wa<CR>", { desc = "Save all files" })

-- Window management keymaps
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })
keymap.set("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", { desc = "Find Diagnostics (Project)" })
keymap.set("n", "<M-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
keymap.set("n", "<M-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
keymap.set("n", "<M-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
keymap.set("n", "<M-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- "Tab" bar management. The bar across the top is bufferline in mode="buffers",
-- so these operate on BUFFERS (the items you actually see), not native tab pages.
-- create / close
keymap.set("n", "<leader>tc", "<cmd>enew<cr>", { desc = "Tab bar: new buffer" })
keymap.set("n", "<leader>txx", "<cmd>bdelete<cr>", { desc = "Tab bar: close buffer" })
keymap.set("n", "<leader>txo", "<cmd>BufferLineCloseOthers<cr>", { desc = "Tab bar: close others" })
-- switch focus  (n=next/right, l=left/prev, e=end/rightmost, f=front/leftmost)
keymap.set("n", "<leader>tn", "<cmd>BufferLineCycleNext<cr>", { desc = "Tab bar: next (right)" })
keymap.set("n", "<leader>tl", "<cmd>BufferLineCyclePrev<cr>", { desc = "Tab bar: previous (left)" })
keymap.set("n", "<leader>te", "<cmd>BufferLineGoToBuffer -1<cr>", { desc = "Tab bar: end (rightmost)" })
keymap.set("n", "<leader>tf", "<cmd>BufferLineGoToBuffer 1<cr>", { desc = "Tab bar: front (leftmost)" })
-- move the active buffer within the bar
keymap.set("n", "<leader>tml", "<cmd>BufferLineMovePrev<cr>", { desc = "Tab bar move: left" })
keymap.set("n", "<leader>tmn", "<cmd>BufferLineMoveNext<cr>", { desc = "Tab bar move: right" })
keymap.set("n", "<leader>tme", function()
  for _ = 1, #vim.fn.getbufinfo({ buflisted = 1 }) do vim.cmd("BufferLineMoveNext") end
end, { desc = "Tab bar move: to end" })
keymap.set("n", "<leader>tmf", function()
  for _ = 1, #vim.fn.getbufinfo({ buflisted = 1 }) do vim.cmd("BufferLineMovePrev") end
end, { desc = "Tab bar move: to front" })
-- (built-in native tab pages still available via :tabnew / gt / gT if ever wanted)

-- Buffer navigation (works with bufferline.nvim)
-- NOTE: this overrides the default H / L motions (jump to top/bottom of screen).
keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
keymap.set("n", "<leader>bp", "<cmd>BufferLinePick<cr>", { desc = "Pick buffer (jump by letter)" })
keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete (close) buffer" })

-- Discover keymaps
keymap.set("n", "<leader>?", "<cmd>WhichKey<cr>", { desc = "Show all keymaps (which-key popup)" })
keymap.set("n", "<leader>sk", "<cmd>Telescope keymaps<cr>", { desc = "Search keymaps (fuzzy)" })

-- =============================================================================
-- PLUGIN CONFIGURATION
-- =============================================================================
require("lazy").setup({


  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
  { "Bilal2453/luvit-meta", lazy = true },

  -- ===========================================================================
  -- THEME & UI
  -- ===========================================================================
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
      -- catppuccin renamed its lualine themes: plain "catppuccin" no longer
      -- exists. "catppuccin-nvim" follows the active flavour (macchiato here).
      require("lualine").setup({ options = { theme = "catppuccin-nvim" } })
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
        { "<leader>s", group = "Window / Search" },
        { "<leader>x", group = "Diagnostics (Trouble)" },
        { "<leader>b", group = "Buffers" },
        { "<leader>g", group = "Git" },
        { "<leader>t", group = "Tab bar (buffers)" },
        { "<leader>tm", group = "Tab bar: move" },
        { "<leader>c", group = "Code" },
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

  -- ===========================================================================
  -- FILE NAVIGATION & UTILITIES
  -- ===========================================================================
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({})
      keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
      keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live Grep" })
      keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find Buffers" })
      keymap.set("n", "<leader>sw", "<cmd>Telescope grep_string<cr>", { desc = "Search for word under cursor" })
      keymap.set("v", "<leader>s", "<cmd>Telescope grep_string<cr>", { desc = "Search for selected text" })
    end,
  },

 {
   "nvim-tree/nvim-tree.lua",
   dependencies = { "nvim-tree/nvim-web-devicons" },
   config = function()
     require("nvim-tree").setup({
       filters = {
         dotfiles = false,
       },
       git = {
         ignore = false,
       },
       actions = {
         open_file = {
           quit_on_open = true, -- close the tree after opening a file -> file is full screen
         },
       },
       view = {
         float = {
           enable = true, -- open the tree as a centered floating overlay
           open_win_config = function()
             local cols, lines = vim.o.columns, vim.o.lines
             local w = math.floor(cols * 0.8)
             local h = math.floor(lines * 0.8)
             return {
               relative = "editor",
               border = "rounded",
               width = w,
               height = h,
               row = math.floor((lines - h) / 2),
               col = math.floor((cols - w) / 2),
             }
           end,
         },
         width = function() return math.floor(vim.o.columns * 0.8) end,
       },
     })
   keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle File Explorer" })
 end,
 },

 {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        -- Toggle the floating terminal with Ctrl-\ (a real control byte, so it
        -- survives SSH + tmux + Konsole). Works in normal AND terminal mode, so
        -- the same chord dismisses the float from inside it. <esc> still drops
        -- to normal mode (its <C-\><C-n> RHS is non-recursive, so no conflict).
        open_mapping = [[<c-\>]],
        size = function(term)
          if term.direction == "horizontal" then
            return vim.o.lines * 0.3 -- Use 30% of screen height
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
        direction = "float", -- Full-screen floating overlay
        float_opts = {
          -- TRUE FULL SCREEN. width/height are INNER cell counts and the border
          -- is drawn OUTSIDE them, so any visible border would overflow by 2
          -- cells and clip -> use border = "none" for genuine edge-to-edge.
          -- Anchor at row/col 0 (toggleterm otherwise centers the float) and
          -- subtract &cmdheight from the height so we fill everything ABOVE the
          -- command line without an "E36: Not enough room" error.
          border = "none",
          width = function() return vim.o.columns end,
          height = function() return vim.o.lines - vim.o.cmdheight end,
          row = 0,
          col = 0,
          winblend = 0,
        },
      })

      -- Terminal is toggled via open_mapping (<C-\>) set above.

      -- Optional: Keymap to exit terminal mode easily with ESC
      function _G.set_terminal_keymaps()
        local opts = {buffer = 0}
        vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
      end
      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

      -- =====================================================================
      -- LAZYGIT — full-screen Git TUI on <leader>gl (worktrees + fast stage /
      -- commit / push / pull). The richer, categorized Git UI now lives on
      -- <leader>gg (the custom Git panel at the end of this file); Neogit's
      -- popups remain available on <leader>gn. Lazygit
      -- opens as a transient full-screen float; press `q` inside lazygit to
      -- quit and the window closes (close_on_exit wipes it, so it never
      -- lingers as a buffer).
      -- =====================================================================
      local Terminal = require("toggleterm.terminal").Terminal
      local lazygit = Terminal:new({
        cmd = "lazygit",
        direction = "float",
        hidden = true,
        float_opts = {
          -- Full screen: lazygit draws its own panels/borders, so border="none"
          -- here avoids a doubled frame. See the <C-\> terminal above for
          -- why width=columns / height=lines-cmdheight / row,col=0 is correct.
          border = "none",
          width = function() return vim.o.columns end,
          height = function() return vim.o.lines - vim.o.cmdheight end,
          row = 0,
          col = 0,
        },
        on_open = function(term)
          vim.cmd("startinsert!")
          -- Let lazygit handle <esc> itself (back/cancel). Drop the global
          -- terminal <esc> mapping for THIS buffer so it passes through.
          vim.schedule(function()
            pcall(vim.keymap.del, "t", "<esc>", { buffer = term.bufnr })
          end)
        end,
      })
      vim.keymap.set("n", "<leader>gl", function() lazygit:toggle() end,
        { desc = "Lazygit (worktrees + fast Git ops)", noremap = true, silent = true })
      -- Also expose a plain command, easy to test: just run `:Lazygit`
      vim.api.nvim_create_user_command("Lazygit", function() lazygit:toggle() end,
        { desc = "Open the lazygit Git panel" })
    end
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "javascript", "typescript", "python", "html", "css", "markdown", "markdown_inline" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

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
      vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Project Diagnostics" })
      vim.keymap.set("n", "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics" })
    end,
  },

-- ===========================================================================
  -- SEARCH AND REPLACE
  -- ===========================================================================
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

-- ===========================================================================
  -- LSP, LINTING, AND COMPLETION
  -- ===========================================================================

  -- 1. Mason (The Package Manager for LSPs)
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- 2. Mason-LSPConfig + Nvim-LSPConfig (The Glue + The Setup)
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "williamboman/mason.nvim",
    },
    config = function()
      -- Make nvim-cmp's enhanced capabilities the default for EVERY server.
      -- Neovim 0.11 + mason-lspconfig v2 enable servers via automatic_enable /
      -- vim.lsp.enable(), so the old per-server `handlers` block no longer runs.
      -- Capabilities must therefore be registered on the global ("*") config.
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })

      -- ensure_installed pins the servers Mason should auto-install on a fresh
      -- machine. automatic_enable (default true in v2) then enables each one.
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "ts_ls", "html", "cssls", "marksman" },
      })

      -- SETUP KEYMAPS (LspAttach Autocommand)
      vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'LSP actions',
        callback = function(event)
          local buf = event.buf

          -- LSP Keymaps
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = buf, desc = "Go to declaration" })
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = buf, desc = "Go to definition" })
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = buf, desc = "Hover documentation" })
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = buf, desc = "Go to implementation" })
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = buf, desc = "Rename symbol" })
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = buf, desc = "Code action" })
        end,
      })
    end,
  },

  -- 3. Autocompletion Engine
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),

          -- OPTION 1 APPLIED: select = false
          -- Pressing Enter now inserts a newline normally.
          -- It only inserts a suggestion if you manually highlighted one first.
          ['<CR>'] = cmp.mapping.confirm({ select = false }),

          ['<C-e>'] = cmp.mapping.abort(),

          -- OPTIONAL: Add Tab/Shift-Tab to scroll through the menu
          ['<Tab>'] = cmp.mapping.select_next_item(),
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })

      -- Enable command-line completion
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })
    end,
  },

  -- ===========================================================================
  -- GIT INTEGRATION
  -- ===========================================================================
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- ---------------------------------------------------------------------------
  -- DIFFVIEW — scrollable, side-by-side diff overlay (opens in its own tabpage)
  -- Used both on its own keys below AND as Neogit's diff viewer (the `d` ->
  -- "Diff this" action inside the Neogit status buffer).
  -- ---------------------------------------------------------------------------
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = {
      "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles",
      "DiffviewFocusFiles", "DiffviewFileHistory", "DiffviewRefresh",
    },
    keys = {
      -- Working tree: left = index (staged), right = working dir (unstaged),
      -- both compared against HEAD. This is the staged + unstaged overlay.
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff: working tree (staged + unstaged)" },
      -- Review a whole branch/rev. Prompts so nothing is hardcoded; try a bare
      -- branch ("main") or a merge-base range ("origin/main...HEAD", PR-style).
      {
        "<leader>gD",
        function()
          vim.ui.input({ prompt = "Diff against (branch / rev, e.g. main or origin/main...HEAD): " }, function(rev)
            if rev and rev ~= "" then vim.cmd("DiffviewOpen " .. rev) end
          end)
        end,
        desc = "Diff: against a branch / rev",
      },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>",   desc = "Diff: repo commit history" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "Diff: current file history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>",         desc = "Diff: close the diff view" },
    },
    opts = {
      use_icons = true,
      watch_index = true, -- auto-refresh when the git index changes
      view = {
        default = { layout = "diff2_horizontal" }, -- side-by-side, scrollable
        merge_tool = { layout = "diff3_mixed" },
      },
      file_panel = { listing_style = "tree" },
    },
    config = function(_, opts)
      require("diffview").setup(opts)
    end,
  },

  -- ---------------------------------------------------------------------------
  -- NEOGIT — Magit-style popups on <leader>gn (kept as a power-user fallback;
  -- the custom Git panel at the end of this file owns <leader>gg). A status
  -- buffer with SEPARATE, labeled, foldable sections: Untracked files /
  -- Unstaged changes / Staged changes / Recent commits. Inside it:
  --   <tab>  expand/collapse a file's inline diff
  --   d      Diff popup -> "Diff this" opens it in Diffview (scrollable overlay)
  --   s / u  stage / unstage at point      x  discard      c  commit popup
  --   b      Branch popup (checkout/create/rename)
  --   w      Worktree popup (checkout / create / goto / move / delete)
  --   ?      show all keybindings          q  close
  -- ---------------------------------------------------------------------------
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = {
      "sindrets/diffview.nvim",        -- scrollable diffs for the `d` popup
      "nvim-telescope/telescope.nvim", -- branch / worktree selection menus
    },
    keys = {
      { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit popups (commit / rebase / merge) — fallback to the <leader>gg panel" },
    },
    opts = {
      kind = "tab",          -- full-screen tab (robust). Use "floating" for a popup window.
      graph_style = "unicode",
      integrations = {
        diffview = true,     -- `d` -> "Diff this" opens a scrollable Diffview overlay
        telescope = true,    -- fuzzy menus for branches / worktrees
      },
      -- Each section is independently labeled + foldable. Expand the three the
      -- user cares about by default so unstaged, staged AND committed changes
      -- are visible the moment the panel opens.
      sections = {
        untracked = { folded = false, hidden = false },
        unstaged  = { folded = false, hidden = false },
        staged    = { folded = false, hidden = false },
        stashes   = { folded = true,  hidden = false },
        recent    = { folded = false, hidden = false }, -- Recent (committed) changes
      },
    },
    config = function(_, opts)
      require("neogit").setup(opts)
    end,
  },

  -- ===========================================================================
  -- MARKDOWN  (in-buffer rendering + LSP + format + lint)
  -- render-markdown draws headings/lists/code/tables/checkboxes right in the
  -- buffer (fixes the "jumbled raw source" look); marksman is the markdown LSP
  -- (link/heading nav + completion); conform formats with prettier on save;
  -- nvim-lint surfaces markdownlint-cli2 diagnostics (inline + in Trouble).
  -- The non-LSP CLI tools (prettier, markdownlint-cli2) are auto-installed via
  -- mason-tool-installer, mirroring how the LSP servers are pinned above.
  -- ===========================================================================
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown", "markdown.mdx" },
    config = function()
      require("render-markdown").setup({})
      vim.keymap.set("n", "<leader>cm", "<cmd>RenderMarkdown toggle<cr>",
        { desc = "Markdown: toggle in-buffer rendering" })
    end,
  },

  -- Auto-install the CLI tools that the formatter/linter shell out to.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = { "prettier", "markdownlint-cli2" },
      })
    end,
  },

  -- Formatting (prettier). Auto-format on save is scoped to filetypes that have
  -- a formatter configured (markdown only, for now); every other filetype falls
  -- through to a no-op, so existing save behaviour is untouched.  <leader>cf
  -- formats manually (also works on a visual selection).
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_format = "never" }) end,
        mode = { "n", "v" },
        desc = "Format buffer / selection",
      },
    },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          markdown = { "prettier" },
        },
        format_on_save = function(bufnr)
          if vim.bo[bufnr].filetype == "markdown" then
            return { timeout_ms = 2000, lsp_format = "never" }
          end
        end,
      })
    end,
  },

  -- Linting (markdownlint-cli2). Runs on read/save/leave-insert; diagnostics
  -- show inline and in your existing Trouble panel (<leader>xx).
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        markdown = { "markdownlint-cli2" },
      }
      local grp = vim.api.nvim_create_augroup("nvim-lint-markdown", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = grp,
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },

})


  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  command = [[%s/\s\+$//e]],
})


-- =============================================================================
-- CUSTOM GIT PANEL  (<leader>gg)
-- A self-contained, dependency-free Git dashboard driven by the git CLI.
-- Permanent, labelled sections — Branches, Worktrees, and a Changes region that
-- toggles between a "Staged / Unstaged" and a "Committed / Uncommitted" view —
-- each visible even when empty. All actions act on the item under the cursor.
--
--   <Tab>  switch Changes view (Staged/Unstaged  <->  Committed/Uncommitted)
--   <CR>   act on item  (section header -> fold,  branch -> checkout,
--          worktree -> switch,  file -> open,  commit -> show,
--          push -> show the commits that push introduced)
-- The work view's change list also carries a "Committed (not pushed)" section
-- (local commits absent from every remote) and a "Pushed" section, folded by
-- default (the upstream reflog; each row is a push — select it to see the
-- commits it introduced).
-- When a merge/rebase/cherry-pick/revert is in progress a warning banner shows
-- in the header and the Conflicts section stays visible; resolve with o/t (take
-- ours/theirs) or edit + s (mark resolved), then > to continue or A to abort.
--   za     fold / unfold the section under the cursor
--   s / u  stage / unstage file under cursor      S / U  Stage All / Unstage All
--   x      discard changes to file under cursor (confirm)
--   o / t  resolve conflict under cursor: take ours / take theirs
--   > / A  continue / abort the in-progress operation
--   c      commit staged        C  Commit All (stage everything, then commit)
--   a      amend last commit
--   b      new branch           m  merge branch-under-cursor into current
--   d      delete branch / remove worktree (context-sensitive, confirm)
--   W      new worktree
--   F / P  pull / push          f  fetch
--   L      toggle layout (full tab  <->  left split)
--   r      refresh    g? / ?  help    q  close
-- =============================================================================
local GitPanel = (function()
  local api, fn, uv = vim.api, vim.fn, (vim.uv or vim.loop)
  local M = {
    buf = nil,
    win = nil,
    mode = nil,        -- 'tab' | 'split'
    view = 'work',     -- 'work' (Staged/Unstaged) | 'history' (Committed/Uncommitted)
    folds = { pushed = true },  -- section_id -> collapsed; Pushed starts folded (long history)
    root = nil,        -- repo root for the active panel
    line_map = {},     -- 1-indexed line number -> item descriptor
    prev_win = nil,    -- window we came from (for opening files)
    start_dir = nil,   -- dir used to locate the repo
  }
  local PANEL_WIDTH = 48
  local ns = api.nvim_create_namespace('gitpanel')
  local home = uv.os_homedir() or ''

  -- ---------------------------------------------------------------------------
  -- git runner: argv only (no shell), explicit cwd, stable locale, no locks.
  -- ---------------------------------------------------------------------------
  local function git(args, opts)
    opts = opts or {}
    local cmd = { 'git' }
    for _, a in ipairs(args) do cmd[#cmd + 1] = a end
    local res = vim.system(cmd, {
      text = true,
      cwd = opts.cwd or M.root or M.start_dir or fn.getcwd(),
      env = { LC_ALL = 'C', GIT_OPTIONAL_LOCKS = '0' },
    }):wait()
    if res.code ~= 0 and not opts.allow_fail then
      vim.notify('git ' .. table.concat(args, ' ') .. '\n' ..
        ((res.stderr or ''):gsub('%s+$', '')), vim.log.levels.ERROR)
    end
    return res
  end
  local function chomp(s) return (s or ''):gsub('%s+$', '') end
  -- split on NUL, returning every field including trailing empties dropped
  local function nul_split(s)
    local t = {}
    for field in (s or ''):gmatch('([^%z]*)%z') do t[#t + 1] = field end
    return t
  end

  -- In-progress sequencer operation, if any. Merge/cherry-pick/revert leave a
  -- *_HEAD marker; rebase leaves a state directory. All live in the (possibly
  -- per-worktree) git dir, so resolve it once and stat the markers — one git
  -- call instead of one per marker, since this runs on every refresh.
  local function op_state()
    local gd = chomp(git({ 'rev-parse', '--absolute-git-dir' }, { allow_fail = true }).stdout)
    if gd == '' then return nil end
    local function has(name) return uv.fs_stat(gd .. '/' .. name) ~= nil end
    if has('MERGE_HEAD') then return 'merge' end
    if has('CHERRY_PICK_HEAD') then return 'cherry-pick' end
    if has('REVERT_HEAD') then return 'revert' end
    if has('rebase-merge') or has('rebase-apply') then return 'rebase' end
    return nil
  end

  -- ---------------------------------------------------------------------------
  -- Data gathering -> a plain model table.
  -- ---------------------------------------------------------------------------
  local function realpath(p) return (p and uv.fs_realpath(p)) or p end
  local function same_path(a, b)
    a, b = realpath(a), realpath(b)
    if not a or not b then return false end
    return a:lower() == b:lower()  -- macOS APFS is case-insensitive
  end

  local function gather()
    local m = { branches = {}, worktrees = {}, staged = {}, unstaged = {},
                untracked = {}, conflicts = {}, commits = {}, unpushed = {},
                pushes = {}, head = {} }

    -- HEAD classification (branch / detached / unborn)
    local sym = git({ 'symbolic-ref', '--quiet', '--short', 'HEAD' }, { allow_fail = true })
    local has_head = git({ 'rev-parse', '--verify', '--quiet', 'HEAD' }, { allow_fail = true })
    if sym.code == 0 and has_head.code == 0 then
      m.head.branch = chomp(sym.stdout)
    elseif sym.code == 0 and has_head.code ~= 0 then
      m.head.branch, m.head.unborn = chomp(sym.stdout), true
    else -- detached
      m.head.detached = true
      m.head.sha = chomp(git({ 'rev-parse', '--short', 'HEAD' }, { allow_fail = true }).stdout)
    end

    -- upstream + ahead/behind for current branch
    if not m.head.unborn then
      local up = git({ 'rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}' },
        { allow_fail = true })
      if up.code == 0 then
        m.head.upstream = chomp(up.stdout)
        local ab = git({ 'rev-list', '--left-right', '--count', '@{upstream}...HEAD' },
          { allow_fail = true })
        if ab.code == 0 then
          local behind, ahead = chomp(ab.stdout):match('(%d+)%s+(%d+)')
          m.head.behind, m.head.ahead = tonumber(behind) or 0, tonumber(ahead) or 0
        end
      end
    end

    -- local branches
    local fmt = '%(HEAD)%00%(refname:short)%00%(objectname:short)%00' ..
                '%(upstream:short)%00%(upstream:trackshort)%00%(worktreepath)%00%(contents:subject)'
    local br = git({ 'for-each-ref', '--sort=-committerdate', '--format=' .. fmt, 'refs/heads' },
      { allow_fail = true })
    if br.code == 0 then
      for line in chomp(br.stdout):gmatch('[^\n]+') do
        local f = {}
        for x in (line .. '\0'):gmatch('([^%z]*)%z') do f[#f + 1] = x end
        if f[2] and f[2] ~= '' then
          m.branches[#m.branches + 1] = {
            current = (f[1] == '*'), name = f[2], sha = f[3],
            upstream = (f[4] ~= '' and f[4]) or nil, track = f[5] or '',
            worktree = (f[6] ~= '' and f[6]) or nil,  -- folder holding this branch
            subject = f[7] or '',
          }
        end
      end
      -- show the current branch first (rest stay in committerdate order)
      for idx, b in ipairs(m.branches) do
        if b.current then table.remove(m.branches, idx); table.insert(m.branches, 1, b); break end
      end
    end

    -- worktrees (porcelain -z: NUL-terminated attrs, empty field = record break)
    local wt = git({ 'worktree', 'list', '--porcelain', '-z' }, { allow_fail = true })
    if wt.code == 0 then
      local cur = {}
      local function flush()
        if cur.path then
          local label = '(bare)'
          if cur.branch then label = cur.branch:gsub('^refs/heads/', '')
          elseif cur.detached and cur.HEAD then label = cur.HEAD:sub(1, 7) .. ' (detached)' end
          m.worktrees[#m.worktrees + 1] = {
            path = cur.path, label = label,
            current = same_path(cur.path, M.root),
            flags = { locked = cur.locked, prunable = cur.prunable, bare = cur.bare },
          }
        end
        cur = {}
      end
      for _, tok in ipairs(nul_split(wt.stdout)) do
        if tok == '' then
          flush()
        else
          local key, val = tok:match('^(%S+)%s?(.*)$')
          if key == 'worktree' then cur.path = val
          elseif key == 'HEAD' then cur.HEAD = val
          elseif key == 'branch' then cur.branch = val
          elseif key == 'bare' then cur.bare = true
          elseif key == 'detached' then cur.detached = true
          elseif key == 'locked' then cur.locked = true
          elseif key == 'prunable' then cur.prunable = true end
        end
      end
      flush()
    end

    -- working-tree status (porcelain v2 -z)
    local st = git({ 'status', '--porcelain=v2', '-z', '--untracked-files=all', '--ignored=no' },
      { allow_fail = true })
    if st.code == 0 then
      local toks = nul_split(st.stdout)
      local i = 1
      while i <= #toks do
        local tok = toks[i]
        local kind = tok:sub(1, 1)
        if kind == '1' then
          local xy = tok:sub(3, 4)
          local path = tok:match('^%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+(.+)$')
          local rec = { x = xy:sub(1, 1), y = xy:sub(2, 2), path = path }
          if rec.x ~= '.' then m.staged[#m.staged + 1] = rec end
          if rec.y ~= '.' then m.unstaged[#m.unstaged + 1] = rec end
          i = i + 1
        elseif kind == '2' then
          local xy = tok:sub(3, 4)
          local path = tok:match('^%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+(.+)$')
          local orig = toks[i + 1]  -- rename/copy consumes an extra NUL field
          local rec = { x = xy:sub(1, 1), y = xy:sub(2, 2), path = path, orig = orig }
          if rec.x ~= '.' then m.staged[#m.staged + 1] = rec end
          if rec.y ~= '.' then m.unstaged[#m.unstaged + 1] = rec end
          i = i + 2
        elseif kind == 'u' then
          local xy = tok:sub(3, 4)
          local path = tok:match('^u%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+(.+)$')
          m.conflicts[#m.conflicts + 1] = { x = xy:sub(1, 1), y = xy:sub(2, 2), path = path }
          i = i + 1
        elseif kind == '?' then
          m.untracked[#m.untracked + 1] = { path = tok:sub(3) }
          i = i + 1
        else
          i = i + 1
        end
      end
    end

    -- combined "uncommitted" list (dedup by display path) for the history view
    local seen, uncommitted = {}, {}
    local function add_unc(rec, badge)
      local key = rec.path
      if seen[key] then return end
      seen[key] = true
      uncommitted[#uncommitted + 1] = { x = rec.x, y = rec.y, path = rec.path, orig = rec.orig, badge = badge }
    end
    for _, r in ipairs(m.conflicts) do add_unc(r, 'conflict') end
    for _, r in ipairs(m.staged) do add_unc(r) end
    for _, r in ipairs(m.unstaged) do add_unc(r) end
    for _, r in ipairs(m.untracked) do add_unc({ x = '?', y = '?', path = r.path }, 'untracked') end
    m.uncommitted = uncommitted

    -- recent commits (skip when unborn — git log would fail)
    if not m.head.unborn then
      local lg = git({ 'log', '-n', '30', '--format=%h%x00%s%x00%D', '-z',
        '--decorate=short', 'HEAD' }, { allow_fail = true })
      if lg.code == 0 then
        local toks = nul_split(lg.stdout)
        for j = 1, #toks - 2, 3 do
          m.commits[#m.commits + 1] = { sha = toks[j], subject = toks[j + 1], refs = toks[j + 2] }
        end
      end
    end

    -- committed-but-not-pushed: reachable from HEAD, not from ANY remote ref.
    -- Correct without an upstream (still catches local-only commits) and when
    -- the branch was pushed to a different remote. Gated on there being at
    -- least one remote-tracking ref, because with none "--not --remotes"
    -- subtracts nothing and would list the entire history as "unpushed".
    -- Fetches 51 to detect (and flag) the >50 overflow case.
    if not m.head.unborn then
      local rem = git({ 'for-each-ref', '--count=1', 'refs/remotes' }, { allow_fail = true })
      m.has_remotes = (rem.code == 0 and chomp(rem.stdout) ~= '')
      if m.has_remotes then
        local un = git({ 'log', 'HEAD', '--not', '--remotes', '-z',
          '--format=%h%x00%s%x00%D', '-n', '51' }, { allow_fail = true })
        if un.code == 0 then
          local toks = nul_split(un.stdout)
          for j = 1, #toks - 2, 3 do
            m.unpushed[#m.unpushed + 1] = { sha = toks[j], subject = toks[j + 1], refs = toks[j + 2] }
          end
        end
      end
    end

    -- push history: the reflog of the upstream tracking ref. The reflog is a
    -- contiguous journal, so entry i's *previous* ref state is entry i+1's
    -- commit — the commits that entry introduced are therefore old..new. We
    -- record old before filtering to push entries so ranges stay correct even
    -- when a fetch/pull sits between two pushes. We show the reflog date (%gd,
    -- when the push happened) and the tip commit's subject (%s) — NOT %cs (the
    -- commit's own date) nor %gs (which is just "update by push" for every row,
    -- and is used only to identify pushes).
    if m.head.upstream then
      local rl = git({ 'log', '-g', '-z', '--date=short',
        '--format=%H%x00%h%x00%gd%x00%gs%x00%s', '-n', '80', m.head.upstream },
        { allow_fail = true })
      if rl.code == 0 then
        local toks = nul_split(rl.stdout)
        local entries = {}
        for j = 1, #toks - 4, 5 do
          entries[#entries + 1] = { new = toks[j], short = toks[j + 1],
                                    date = (toks[j + 2]:match('@{(.-)}$') or ''),
                                    reflog = toks[j + 3], subject = toks[j + 4] }
        end
        for idx, e in ipairs(entries) do
          e.old = entries[idx + 1] and entries[idx + 1].new or nil
          if (e.reflog or ''):lower():find('push', 1, true) then
            m.pushes[#m.pushes + 1] = e
          end
        end
      end
    end

    m.op = op_state()   -- in-progress merge/rebase/cherry-pick/revert (or nil)

    return m
  end

  -- ---------------------------------------------------------------------------
  -- Rendering: model -> (lines, line_map, highlights)
  -- ---------------------------------------------------------------------------
  local function tilde(p)
    if home ~= '' and p:sub(1, #home) == home then return '~' .. p:sub(#home + 1) end
    return p
  end
  local function status_letter(rec)
    -- prefer the meaningful side; renames show R, untracked ?, etc.
    local c = rec.x ~= '.' and rec.x or rec.y
    if c == '.' or c == nil then c = '?' end
    return c
  end

  local function render(m)
    local lines, map, hls = {}, {}, {}
    local function emit(text, item, hl)
      lines[#lines + 1] = text
      local lnum = #lines
      if item then map[lnum] = item end
      if hl then hls[#hls + 1] = { line = lnum - 1, cs = 0, ce = #text, group = hl } end
      return lnum
    end
    local function span(lnum, cs, ce, group)
      hls[#hls + 1] = { line = lnum - 1, cs = cs, ce = ce, group = group }
    end
    local function folded(id) return M.folds[id] == true end
    local function chevron(id) return folded(id) and '▸' or '▾' end

    -- ---- header -----------------------------------------------------------
    local name = fn.fnamemodify(M.root or '', ':t')
    local hl
    if m.head.unborn then
      hl = (m.head.branch or 'HEAD') .. '  (no commits yet)'
    elseif m.head.detached then
      hl = 'detached @ ' .. (m.head.sha or '?')
    else
      hl = m.head.branch or '?'
      local extra = {}
      if m.head.ahead and m.head.ahead > 0 then extra[#extra + 1] = '↑' .. m.head.ahead end
      if m.head.behind and m.head.behind > 0 then extra[#extra + 1] = '↓' .. m.head.behind end
      if m.head.upstream and #extra == 0 then extra[#extra + 1] = '✓' end
      if #extra > 0 then hl = hl .. '  ' .. table.concat(extra, ' ') end
    end
    local hline = emit('  ' .. name .. '  on  ' .. hl, { kind = 'head' }, 'GitPanelHeader')
    span(hline, 2, 2 + #name, 'GitPanelTitle')
    emit('  <Tab> switch view · s/u stage · S/C stage·commit all · g? help · q quit',
      nil, 'GitPanelHint')
    -- in-progress merge/rebase/cherry-pick/revert banner
    if m.op then
      local OP = { merge = 'MERGING', rebase = 'REBASING',
                   ['cherry-pick'] = 'CHERRY-PICKING', revert = 'REVERTING' }
      local n = #m.conflicts
      local status = (n > 0) and (n .. ' conflict' .. (n == 1 and '' or 's') .. ' to resolve')
                              or 'all conflicts resolved'
      -- git inverts ours/theirs during a rebase (you replay onto the base), so
      -- spell out the meaning to avoid discarding the wrong side.
      local sides = (m.op == 'rebase') and 'o ours(base) · t theirs(your commit)'
                                        or  'o ours · t theirs'
      emit('  ⚠ ' .. (OP[m.op] or m.op:upper()) .. ' — ' .. status ..
        '   ·  ' .. sides .. ' · > continue · A abort', { kind = 'op' }, 'GitPanelOp')
    end
    emit('')

    -- ---- a foldable section with header + body rows ------------------------
    local function section(id, title, count, render_body)
      local head_item = { kind = 'section', section = id }
      local h = emit(' ' .. chevron(id) .. ' ' .. title ..
        (count ~= nil and ('  (' .. count .. ')') or ''), head_item, 'GitPanelSection')
      span(h, 1, 4, 'GitPanelHint')
      if not folded(id) then render_body() end
    end
    local function empty_row(text)
      emit('     ' .. text, nil, 'GitPanelHint')
    end
    -- a file/change row with a coloured status letter
    local function file_row(rec, section_id, staged)
      local letter = status_letter(rec)
      local disp = rec.path
      if rec.orig then disp = rec.orig .. ' → ' .. rec.path end
      local prefix = '     ' .. letter .. '  '
      local lnum = emit(prefix .. disp,
        { kind = 'file', value = rec.path, orig = rec.orig, section = section_id,
          staged = staged, untracked = (letter == '?'),
          conflict = (rec.badge == 'conflict') or nil })
      local grp = 'GitPanelUnstaged'
      if rec.badge == 'conflict' or letter == 'U' then grp = 'GitPanelConflict'
      elseif letter == '?' then grp = 'GitPanelUntracked'
      elseif staged then grp = 'GitPanelStaged' end
      span(lnum, 5, 6, grp)                       -- the status letter
      if rec.orig then span(lnum, #prefix, #prefix + #rec.orig, 'GitPanelHint') end
    end
    -- a conflicted-file row: <XY>  <path>   (both modified)
    local CONFLICT_KIND = {
      DD = 'both deleted', AU = 'added by us', UD = 'deleted by them',
      UA = 'added by them', DU = 'deleted by us', AA = 'both added', UU = 'both modified',
    }
    local function conflict_row(rec)
      local xy = (rec.x or '?') .. (rec.y or '?')
      local label = CONFLICT_KIND[xy] or 'unmerged'
      local prefix = '     ' .. xy .. '  '
      local lnum = emit(prefix .. rec.path .. '   (' .. label .. ')',
        { kind = 'file', value = rec.path, section = 'conflicts', conflict = true })
      span(lnum, 5, 5 + #xy, 'GitPanelConflict')            -- the XY code
      span(lnum, #prefix + #rec.path, -1, 'GitPanelHint')   -- the "(label)"
    end
    -- a commit row: <sha>  <subject>  (refs)
    local function commit_row(c, section_id)
      local refs = (c.refs and c.refs ~= '') and ('  (' .. c.refs .. ')') or ''
      local prefix = '     '
      local lnum = emit(prefix .. c.sha .. '  ' .. c.subject .. refs,
        { kind = 'commit', value = c.sha, section = section_id })
      span(lnum, #prefix, #prefix + #c.sha, 'GitPanelHash')
      if refs ~= '' then span(lnum, #prefix + #c.sha + 2 + #c.subject, -1, 'GitPanelRef') end
    end
    -- a push row: <sha>  <date>  <reflog subject>. <CR> shows old..new commits.
    local function push_row(e)
      local prefix = '     '
      local date = (e.date and e.date ~= '') and (e.date .. '  ') or ''
      local lnum = emit(prefix .. e.short .. '  ' .. date .. (e.subject or ''),
        { kind = 'push', value = e.new, old = e.old, section = 'pushed' })
      span(lnum, #prefix, #prefix + #e.short, 'GitPanelHash')
      if date ~= '' then
        span(lnum, #prefix + #e.short + 2, #prefix + #e.short + 2 + #e.date, 'GitPanelHint')
      end
    end

    -- ---- Branches (permanent) --------------------------------------------
    section('branches', 'Branches', #m.branches, function()
      if #m.branches == 0 then return empty_row('(no branches)') end
      for _, b in ipairs(m.branches) do
        local marker = b.current and '*' or ' '
        local row = '     ' .. marker .. ' ' .. b.name
        local tr = b.track ~= '' and b.track or ''
        if tr ~= '' then row = row .. '  ' .. tr end
        -- branch checked out in ANOTHER worktree: show which folder holds it
        if b.worktree and not b.current then
          row = row .. '  ⊘ ' .. fn.fnamemodify(b.worktree, ':t')
        end
        local lnum = emit(row,
          { kind = 'branch', value = b.name, current = b.current, worktree = b.worktree })
        if b.current then span(lnum, 5, 7 + #b.name, 'GitPanelBranchCurrent')
        elseif b.worktree then span(lnum, 7 + #b.name, -1, 'GitPanelHint') end
      end
    end)
    emit('')

    -- ---- Worktrees (permanent) -------------------------------------------
    section('worktrees', 'Worktrees', #m.worktrees, function()
      if #m.worktrees == 0 then return empty_row('(no worktrees)') end
      for _, w in ipairs(m.worktrees) do
        local marker = w.current and '*' or ' '
        local flags = {}
        if w.flags.locked then flags[#flags + 1] = 'locked' end
        if w.flags.prunable then flags[#flags + 1] = 'prunable' end
        local row = '     ' .. marker .. ' ' .. tilde(w.path) .. '   ' .. w.label
        if #flags > 0 then row = row .. '  [' .. table.concat(flags, ',') .. ']' end
        local lnum = emit(row, { kind = 'worktree', value = w.path, current = w.current })
        if w.current then span(lnum, 5, #row, 'GitPanelWorktreeCurrent') end
      end
    end)
    emit('')

    -- ---- Changes region: divider that toggles the view --------------------
    local function divider(label, hint)
      local lnum = emit('── ' .. label .. ' ' .. string.rep('─', math.max(2, 40 - #label)),
        { kind = 'viewheader' }, 'GitPanelDivider')
      emit('     ' .. hint, nil, 'GitPanelHint')
    end

    if M.view == 'work' then
      divider('Staged / Unstaged', '<Tab> → Committed / Uncommitted')
      if m.op or #m.conflicts > 0 then
        section('conflicts', 'Conflicts', #m.conflicts, function()
          if #m.conflicts == 0 then
            return empty_row('(all resolved — > continue · A abort)')
          end
          for _, r in ipairs(m.conflicts) do conflict_row(r) end
        end)
      end
      section('staged', 'Staged', #m.staged, function()
        if #m.staged == 0 then return empty_row('(nothing staged)') end
        for _, r in ipairs(m.staged) do file_row(r, 'staged', true) end
      end)
      section('unstaged', 'Unstaged', #m.unstaged, function()
        if #m.unstaged == 0 then return empty_row('(nothing unstaged)') end
        for _, r in ipairs(m.unstaged) do file_row(r, 'unstaged', false) end
      end)
      section('untracked', 'Untracked', #m.untracked, function()
        if #m.untracked == 0 then return empty_row('(no untracked files)') end
        for _, r in ipairs(m.untracked) do
          file_row({ x = '?', y = '?', path = r.path }, 'untracked', false)
        end
      end)
      local ucount = (#m.unpushed > 50) and '50+' or #m.unpushed
      section('unpushed', 'Committed (not pushed)', ucount, function()
        if #m.unpushed == 0 then
          return empty_row(m.has_remotes and '(nothing to push)' or '(no remote configured)')
        end
        local shown = math.min(#m.unpushed, 50)
        for i = 1, shown do commit_row(m.unpushed[i], 'unpushed') end
        if #m.unpushed > 50 then
          empty_row('… more commits not shown (see ↑ ahead-count in the header)')
        end
      end)
      section('pushed', 'Pushed', #m.pushes, function()
        if #m.pushes == 0 then return empty_row('(no pushes recorded)') end
        for _, e in ipairs(m.pushes) do push_row(e) end
      end)
    else
      divider('Committed / Uncommitted', '<Tab> → Staged / Unstaged')
      section('uncommitted', 'Uncommitted', #m.uncommitted, function()
        if #m.uncommitted == 0 then return empty_row('(working tree clean)') end
        for _, r in ipairs(m.uncommitted) do file_row(r, 'uncommitted', r.x ~= '.' and r.x ~= '?') end
      end)
      section('committed', 'Committed (recent)', nil, function()
        if #m.commits == 0 then return empty_row('(no commits yet)') end
        for _, c in ipairs(m.commits) do commit_row(c, 'committed') end
      end)
    end

    return lines, map, hls
  end

  -- ---------------------------------------------------------------------------
  -- Highlight groups (re-applied on ColorScheme so they survive a theme reload)
  -- ---------------------------------------------------------------------------
  local function define_hl()
    local link = function(a, b) api.nvim_set_hl(0, a, { link = b, default = true }) end
    link('GitPanelHeader', 'Title')
    link('GitPanelTitle', 'Directory')
    link('GitPanelHint', 'Comment')
    link('GitPanelSection', 'Statement')
    link('GitPanelDivider', 'Title')
    link('GitPanelBranchCurrent', 'Function')
    link('GitPanelWorktreeCurrent', 'Function')
    link('GitPanelStaged', 'DiagnosticOk')
    link('GitPanelUnstaged', 'DiagnosticWarn')
    link('GitPanelUntracked', 'DiagnosticHint')
    link('GitPanelConflict', 'DiagnosticError')
    link('GitPanelOp', 'WarningMsg')
    link('GitPanelHash', 'Constant')
    link('GitPanelRef', 'Special')
  end

  -- ---------------------------------------------------------------------------
  -- Buffer / window lifecycle
  -- ---------------------------------------------------------------------------
  local function with_writable(fnc)
    api.nvim_set_option_value('modifiable', true, { buf = M.buf })
    local ok, err = pcall(fnc)
    api.nvim_set_option_value('modifiable', false, { buf = M.buf })
    if not ok then error(err) end
  end

  local function find_win()
    if not (M.buf and api.nvim_buf_is_valid(M.buf)) then return nil end
    for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
      if api.nvim_win_get_buf(w) == M.buf then return w end
    end
    for _, w in ipairs(api.nvim_list_wins()) do
      if api.nvim_win_get_buf(w) == M.buf then return w end
    end
    return nil
  end

  function M.refresh()
    if not (M.buf and api.nvim_buf_is_valid(M.buf)) then return end
    local win = find_win()
    -- remember the logical item under the cursor to restore it after rebuild
    local function item_key(it)
      return (it.kind or '') .. '\0' .. tostring(it.value or '') .. '\0' ..
             tostring(it.section or '') .. '\0' .. tostring(it.old or '')
    end
    local prev_key
    if win then
      local it = M.line_map[api.nvim_win_get_cursor(win)[1]]
      if it then prev_key = item_key(it) end
    end

    local model = gather()
    local lines, map, hls = render(model)
    M.line_map = map
    with_writable(function() api.nvim_buf_set_lines(M.buf, 0, -1, false, lines) end)

    api.nvim_buf_clear_namespace(M.buf, ns, 0, -1)
    for _, h in ipairs(hls) do
      pcall(api.nvim_buf_set_extmark, M.buf, ns, h.line, h.cs,
        { end_col = (h.ce == -1) and nil or h.ce, end_row = (h.ce == -1) and h.line + 1 or nil,
          hl_group = h.group })
    end

    if win and prev_key then
      for lnum, it in pairs(map) do
        if item_key(it) == prev_key then
          pcall(api.nvim_win_set_cursor, win, { lnum, 0 })
          break
        end
      end
    end
  end

  local function set_win_opts(win)
    local w = function(n, v) api.nvim_set_option_value(n, v, { win = win }) end
    w('number', false); w('relativenumber', false); w('signcolumn', 'no')
    w('cursorline', true); w('wrap', false); w('list', false); w('foldcolumn', '0')
    w('winfixwidth', true)
  end

  local function ensure_buf()
    if M.buf and api.nvim_buf_is_valid(M.buf) then return M.buf end
    local buf = api.nvim_create_buf(false, true)
    local o = function(n, v) api.nvim_set_option_value(n, v, { buf = buf }) end
    o('buftype', 'nofile'); o('bufhidden', 'hide'); o('swapfile', false)
    o('buflisted', false); o('filetype', 'gitpanel'); o('modifiable', false)
    pcall(api.nvim_buf_set_name, buf, 'gitpanel://status')
    M.buf = buf
    M.attach_keys()
    return buf
  end

  local function open_tab()
    vim.cmd('tabnew')
    M.win = api.nvim_get_current_win()
    api.nvim_win_set_buf(M.win, M.buf)
    set_win_opts(M.win); M.mode = 'tab'
  end
  local function open_split()
    vim.cmd('topleft vsplit')
    M.win = api.nvim_get_current_win()
    api.nvim_win_set_buf(M.win, M.buf)
    api.nvim_win_set_width(M.win, PANEL_WIDTH)
    set_win_opts(M.win); M.mode = 'split'
  end

  local function detect_root()
    local cur = api.nvim_get_current_win()
    if cur ~= M.win then M.prev_win = cur end
    local bufname = api.nvim_buf_get_name(0)
    local dir = (bufname ~= '' and fn.filereadable(bufname) == 1) and fn.fnamemodify(bufname, ':p:h')
      or fn.getcwd()
    M.start_dir = dir
    local r = vim.system({ 'git', 'rev-parse', '--show-toplevel' },
      { text = true, cwd = dir }):wait()
    if r.code ~= 0 then return nil end
    return chomp(r.stdout)
  end

  function M.open(mode)
    mode = mode or 'tab'
    local root = detect_root()
    if not root then
      vim.notify('GitPanel: not inside a git repository (' .. (M.start_dir or '?') .. ')',
        vim.log.levels.WARN)
      return
    end
    M.root = root
    ensure_buf()
    local existing = find_win()
    if existing then
      M.win = existing
      api.nvim_set_current_win(existing)
      if M.mode ~= mode then M.toggle_layout() else M.refresh() end
      return
    end
    if mode == 'tab' then open_tab() else open_split() end
    M.refresh()
  end

  function M.close()
    local win = find_win()
    if not win then return end
    local last_win = #api.nvim_tabpage_list_wins(0) == 1
    local last_tab = fn.tabpagenr('$') == 1
    if last_win and last_tab then
      api.nvim_set_current_win(win); vim.cmd('enew')
    else
      pcall(api.nvim_win_close, win, true)
    end
    M.win, M.mode = nil, nil
  end

  function M.toggle_layout()
    local win = find_win()
    if not win then return M.open('split') end
    local target = (M.mode == 'tab') and 'split' or 'tab'
    api.nvim_set_current_win(win)
    -- Vacate the current panel window before building the new layout, so the
    -- panel buffer is never left showing in a stranded second window. Close it
    -- outright when something else would remain; otherwise swap in a scratch buf.
    if #api.nvim_tabpage_list_wins(0) > 1 or fn.tabpagenr('$') > 1 then
      pcall(api.nvim_win_close, win, true)
    else
      api.nvim_win_set_buf(win, api.nvim_create_buf(false, true))
    end
    if target == 'tab' then open_tab() else open_split() end
    M.refresh()
  end

  function M.toggle_view()
    M.view = (M.view == 'work') and 'history' or 'work'
    M.refresh()
  end

  function M.toggle_fold()
    local it = M.line_map[api.nvim_win_get_cursor(0)[1]]
    if it and it.section then
      M.folds[it.section] = not M.folds[it.section]
      M.refresh()
    elseif it and it.kind == 'viewheader' then
      M.toggle_view()
    end
  end

  -- ---------------------------------------------------------------------------
  -- Actions
  -- ---------------------------------------------------------------------------
  local function cur_item() return M.line_map[api.nvim_win_get_cursor(0)[1]] end
  -- Run a mutating git command. Notifies on failure unless opts.quiet (callers
  -- that inspect stderr themselves pass quiet=true to avoid a double message).
  local function run(args, opts)
    opts = opts or {}
    local res = git(args, { allow_fail = true, cwd = opts.cwd })
    if res.code ~= 0 and not opts.quiet then
      vim.notify('git ' .. table.concat(args, ' ') .. '\n' .. chomp(res.stderr), vim.log.levels.WARN)
    end
    return res.code == 0, res
  end

  local function open_file(path, jump_conflict)
    local full = (M.root or '') .. '/' .. path
    local target
    -- Reuse a window only if it lives in the CURRENT tabpage, so tab-mode never
    -- yanks focus to a different tab. prev_win qualifies only when co-located.
    local here = {}
    for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do here[w] = true end
    if M.prev_win and here[M.prev_win] and api.nvim_win_is_valid(M.prev_win)
        and api.nvim_win_get_buf(M.prev_win) ~= M.buf then
      target = M.prev_win
    else
      for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
        if api.nvim_win_get_buf(w) ~= M.buf then target = w; break end
      end
    end
    if target then
      api.nvim_set_current_win(target)
      vim.cmd('edit ' .. fn.fnameescape(full))
    elseif M.mode == 'split' then
      vim.cmd('rightbelow vsplit ' .. fn.fnameescape(full))
    else
      vim.cmd('split ' .. fn.fnameescape(full))
    end
    -- land on the first conflict marker so the user can start resolving at once
    if jump_conflict then pcall(fn.search, '^<<<<<<<', 'cw') end
  end

  -- open git output in a throwaway split, filetype=git, q to close
  local function show_scratch(text)
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text or '', '\n', { plain = true }))
    api.nvim_set_option_value('filetype', 'git', { buf = buf })
    api.nvim_set_option_value('modifiable', false, { buf = buf })
    if M.mode == 'split' then vim.cmd('rightbelow vsplit') else vim.cmd('botright split') end
    api.nvim_win_set_buf(0, buf)
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, nowait = true, silent = true })
  end
  local function show_commit(sha)
    show_scratch(git({ 'show', '--stat', '--patch', sha }, { allow_fail = true }).stdout)
  end
  -- Show the commits a push introduced: old..new. The oldest recorded push has
  -- no known prior state, so fall back to showing its tip commit alone.
  local function show_push(it)
    if it.old and it.old ~= '' then
      local res = git({ 'log', '--stat', '--patch', it.old .. '..' .. it.value }, { allow_fail = true })
      local out = res.stdout or ''
      if out:gsub('%s+', '') == '' then
        out = '(no commits to list for this push — the ref update introduced nothing new\n' ..
              'over its previous position, e.g. a re-push or a force update to ' .. it.value .. ')'
      end
      show_scratch(out)
    else
      show_scratch('(oldest recorded push — showing the pushed tip commit)\n\n' ..
        (git({ 'show', '--stat', '--patch', it.value }, { allow_fail = true }).stdout or ''))
    end
  end

  function M.primary()
    local it = cur_item()
    if not it then return end
    if it.kind == 'section' or it.kind == 'viewheader' then M.toggle_fold()
    elseif it.kind == 'branch' then M.checkout(it.value)
    elseif it.kind == 'worktree' then M.switch_worktree(it.value)
    elseif it.kind == 'file' then open_file(it.value, it.conflict)
    elseif it.kind == 'commit' then show_commit(it.value)
    elseif it.kind == 'push' then show_push(it)
    elseif it.kind == 'op' then M.op_continue()
    end
  end

  -- Any file still in an unmerged (conflicted) state?
  local function has_conflicts()
    local r = git({ 'diff', '--name-only', '--diff-filter=U' }, { allow_fail = true })
    return r.code == 0 and chomp(r.stdout) ~= ''
  end

  function M.stage()
    local it = cur_item()
    if not (it and it.kind == 'file') then return vim.notify('GitPanel: cursor not on a file', vim.log.levels.INFO) end
    -- Marking a conflict resolved (git add) while it still has markers would
    -- commit the markers; warn first. git diff --check flags leftover markers.
    if it.conflict then
      local chk = git({ 'diff', '--check', '--', it.value }, { allow_fail = true })
      if chk.code ~= 0 then
        local pick = fn.confirm('"' .. it.value .. '" still contains conflict markers ' ..
          '(<<<<<<< / =======  / >>>>>>>).\nStage it as resolved anyway?', '&Yes\n&No', 2)
        if pick ~= 1 then return end
      end
    end
    run({ 'add', '--', it.value }); M.refresh()
  end
  function M.unstage()
    local it = cur_item()
    if not (it and it.kind == 'file') then return vim.notify('GitPanel: cursor not on a file', vim.log.levels.INFO) end
    run({ 'reset', '-q', '--', it.value }); M.refresh()  -- works born and unborn
  end
  -- "Stage All" (git add -A) would sweep unresolved conflicts — marker text and
  -- all — into the index; refuse while any conflict is unresolved.
  function M.stage_all()
    if has_conflicts() then
      return vim.notify('GitPanel: unresolved conflicts — resolve with o/t or edit + s ' ..
        'before Stage All', vim.log.levels.WARN)
    end
    run({ 'add', '-A' }); M.refresh()
  end
  function M.unstage_all() run({ 'reset', '-q' }); M.refresh() end

  function M.discard()
    local it = cur_item()
    if not (it and it.kind == 'file') then return end
    -- On a conflicted file "discard" is ambiguous (restore would silently pick
    -- the HEAD side); steer the user to the explicit resolve keys instead.
    if it.conflict then
      return vim.notify('GitPanel: "' .. it.value .. '" is conflicted — use o/t to take a ' ..
        'side, edit + s to resolve, or A to abort the operation', vim.log.levels.INFO)
    end
    local pick = fn.confirm('Discard changes to "' .. it.value .. '"? This cannot be undone.',
      '&Yes\n&No', 2)
    if pick ~= 1 then return end
    if it.untracked then
      run({ 'clean', '-f', '--', it.value })        -- delete the untracked file
    else
      run({ 'restore', '--staged', '--worktree', '--', it.value }) -- unstage + revert worktree
    end
    M.refresh()
  end

  -- ---- conflict resolution -------------------------------------------------
  -- Resolve the conflicted file under the cursor by taking one whole side, then
  -- stage it. "ours"/"theirs" follow git's flags: during a merge ours = HEAD
  -- (current branch), theirs = the incoming branch; during a rebase they invert
  -- (ours = the branch you're replaying onto). checkout --ours/--theirs only
  -- works for content conflicts — for add/delete conflicts git errors and we
  -- surface that so the user edits/stages manually instead.
  local function resolve_side(side)
    local it = cur_item()
    if not (it and it.kind == 'file' and it.conflict) then
      return vim.notify('GitPanel: move the cursor onto a conflicted file', vim.log.levels.INFO)
    end
    local ok, res = run({ 'checkout', '--' .. side, '--', it.value }, { quiet = true })
    if not ok then
      return vim.notify('git checkout --' .. side .. ':\n' .. chomp(res.stderr) ..
        '\n(add/delete conflict — edit the file and press s to mark resolved)', vim.log.levels.WARN)
    end
    run({ 'add', '--', it.value })
    M.refresh()
  end
  function M.resolve_ours() resolve_side('ours') end
  function M.resolve_theirs() resolve_side('theirs') end

  -- Continue/finish the in-progress operation (commit the merge, advance the
  -- rebase, …). core.editor=true accepts the prepared message without opening
  -- an editor. git exits nonzero when it can't proceed (conflicts remain, or a
  -- rebase step became empty and wants --skip) — its own message is the most
  -- accurate, so we surface that verbatim and re-read state.
  function M.op_continue()
    local op = op_state()
    if not op then
      return vim.notify('GitPanel: no merge/rebase/cherry-pick/revert in progress', vim.log.levels.INFO)
    end
    local ok, res = run({ '-c', 'core.editor=true', op, '--continue' }, { quiet = true })
    if not ok then
      vim.notify('git ' .. op .. ' --continue:\n' .. chomp(res.stderr) ..
        '\n(follow the message above, then > to continue or A to abort' ..
        (op == 'rebase' and '; for an empty patch: :!git rebase --skip)' or ')'),
        vim.log.levels.WARN)
    end
    M.refresh()
  end
  function M.op_abort()
    local op = op_state()
    if not op then
      return vim.notify('GitPanel: nothing to abort (no operation in progress)', vim.log.levels.INFO)
    end
    local pick = fn.confirm('Abort the in-progress ' .. op ..
      '?\nThis throws away the resolution done so far.', '&Yes\n&No', 2)
    if pick ~= 1 then return end
    local ok, res = run({ op, '--abort' }, { quiet = true })
    if not ok then vim.notify('git ' .. op .. ' --abort:\n' .. chomp(res.stderr), vim.log.levels.WARN) end
    M.refresh()
  end

  local function do_commit(extra_args)
    vim.ui.input({ prompt = 'Commit message: ' }, function(msg)
      if not msg or msg == '' then return vim.notify('GitPanel: commit cancelled', vim.log.levels.INFO) end
      local args = { 'commit', '-m', msg }
      for _, a in ipairs(extra_args or {}) do args[#args + 1] = a end
      local ok, res = run(args, { quiet = true })
      if not ok then vim.notify('git commit:\n' .. chomp(res.stderr), vim.log.levels.ERROR) end
      M.refresh()
    end)
  end
  -- `c` always prompts for a message and commits. This works to finish a merge
  -- (git commit completes it) and to commit at a rebase `edit` stop; to advance
  -- with the prepared message (and for rebase after resolving a conflict) use
  -- `>` / M.op_continue instead. git refuses to commit while conflicts remain.
  function M.commit() do_commit() end
  -- "Commit All" during an operation must not `git add -A` (that would sweep in
  -- unresolved conflicts); once things are resolved it finishes the operation.
  function M.commit_all()
    if has_conflicts() then
      return vim.notify('GitPanel: unresolved conflicts — resolve them first ' ..
        '(o/t or edit + s), then > to continue', vim.log.levels.WARN)
    end
    if op_state() then return M.op_continue() end
    run({ 'add', '-A' }); M.refresh(); do_commit()
  end
  function M.amend()
    vim.ui.input({ prompt = 'Amend message (empty = keep existing): ' }, function(msg)
      local args = (msg and msg ~= '') and { 'commit', '--amend', '-m', msg }
        or { 'commit', '--amend', '--no-edit' }
      local ok, res = run(args, { quiet = true })
      if not ok then vim.notify('git commit --amend:\n' .. chomp(res.stderr), vim.log.levels.ERROR) end
      M.refresh()
    end)
  end

  function M.checkout(branch)
    local it = cur_item()
    branch = branch or (it and it.kind == 'branch' and it.value)
    if not branch then return end
    -- A branch checked out in another worktree cannot be switched to here (git's
    -- one-branch-per-worktree rule). Offer to jump to that worktree instead of
    -- surfacing the cryptic "'<b>' is already used by worktree at ..." error.
    if it and it.kind == 'branch' and it.worktree and not it.current then
      local pick = fn.confirm('"' .. branch .. '" is checked out in another worktree:\n  ' ..
        tilde(it.worktree) .. '\n(git allows a branch in only one worktree at a time)\n\n' ..
        'Jump to that worktree?', '&Yes\n&No', 1)
      if pick == 1 then M.switch_worktree(it.worktree) end
      return
    end
    local ok, res = run({ 'switch', '--', branch }, { quiet = true })
    if not ok then vim.notify('git switch:\n' .. chomp(res.stderr), vim.log.levels.WARN) end
    M.refresh()
  end
  function M.new_branch()
    vim.ui.input({ prompt = 'New branch name: ' }, function(nm)
      if not nm or nm == '' then return end
      local ok, res = run({ 'switch', '-c', nm }, { quiet = true })
      if not ok then vim.notify('git switch -c:\n' .. chomp(res.stderr), vim.log.levels.ERROR) end
      M.refresh()
    end)
  end
  function M.delete_branch()
    local it = cur_item()
    if not (it and it.kind == 'branch') then
      return vim.notify('GitPanel: move the cursor onto a branch to delete it', vim.log.levels.INFO)
    end
    if it.current then return vim.notify('GitPanel: cannot delete the current branch', vim.log.levels.WARN) end
    local ok, res = run({ 'branch', '-d', '--', it.value }, { quiet = true })
    if not ok then
      if (res.stderr or ''):match('not fully merged') then
        local pick = fn.confirm('Branch "' .. it.value .. '" is not fully merged. Force-delete?',
          '&Yes\n&No', 2)
        if pick == 1 then run({ 'branch', '-D', '--', it.value }) end
      else
        vim.notify('git branch -d:\n' .. chomp(res.stderr), vim.log.levels.WARN)
      end
    end
    M.refresh()
  end
  function M.merge()
    local it = cur_item()
    if not (it and it.kind == 'branch') then
      return vim.notify('GitPanel: move the cursor onto a branch to merge it', vim.log.levels.INFO)
    end
    if it.current then return vim.notify('GitPanel: that is already the current branch', vim.log.levels.INFO) end
    local pick = fn.confirm('Merge "' .. it.value .. '" into the current branch?', '&Yes\n&No', 1)
    if pick ~= 1 then return end
    local ok, res = run({ 'merge', '--', it.value }, { quiet = true })
    local out = chomp((res.stdout or '') .. (res.stderr or ''))
    if not ok then
      vim.notify('git merge:\n' .. out .. '\n(resolve conflicts, then commit; or :!git merge --abort)',
        vim.log.levels.WARN)
    else
      vim.notify('git merge: ' .. out, vim.log.levels.INFO)
    end
    M.refresh()
  end

  function M.switch_worktree(path)
    local it = cur_item()
    path = path or (it and it.kind == 'worktree' and it.value)
    if not path then return end
    if fn.isdirectory(path) == 0 then
      return vim.notify('GitPanel: worktree path missing: ' .. path, vim.log.levels.WARN)
    end
    vim.cmd('tcd ' .. fn.fnameescape(path))
    M.root = path
    vim.notify('GitPanel: switched to worktree ' .. tilde(path), vim.log.levels.INFO)
    M.refresh()
  end
  function M.new_worktree()
    vim.ui.input({ prompt = 'New worktree path: ', default = (M.root or '') .. '-', completion = 'dir' },
      function(path)
        if not path or path == '' then return end
        vim.ui.input({ prompt = 'Branch (existing) or new name (blank = detach HEAD): ' }, function(br)
          local args
          if not br or br == '' then args = { 'worktree', 'add', '--', path }
          else args = { 'worktree', 'add', '--', path, br } end
          local ok, res = run(args, { quiet = true })
          if not ok and (res.stderr or ''):match('invalid reference') then
            -- branch doesn't exist: create it
            run({ 'worktree', 'add', '-b', br, '--', path })
          elseif not ok then
            vim.notify('git worktree add:\n' .. chomp(res.stderr), vim.log.levels.ERROR)
          end
          M.refresh()
        end)
      end)
  end
  function M.remove_worktree()
    local it = cur_item()
    if not (it and it.kind == 'worktree') then
      return vim.notify('GitPanel: move the cursor onto a worktree to remove it', vim.log.levels.INFO)
    end
    if it.current then return vim.notify('GitPanel: cannot remove the current worktree', vim.log.levels.WARN) end
    local pick = fn.confirm('Remove worktree "' .. tilde(it.value) .. '"?', '&Yes\n&No', 2)
    if pick ~= 1 then return end
    local ok, res = run({ 'worktree', 'remove', '--', it.value }, { quiet = true })
    if not ok and (res.stderr or ''):match('use %-%-force') then
      local p2 = fn.confirm('Worktree has changes. Force remove?', '&Yes\n&No', 2)
      if p2 == 1 then run({ 'worktree', 'remove', '--force', '--', it.value }) end
    elseif not ok then
      vim.notify('git worktree remove:\n' .. chomp(res.stderr), vim.log.levels.WARN)
    end
    M.refresh()
  end

  function M.push()
    local ok, res = run({ 'push' }, { quiet = true })
    if not ok and (res.stderr or ''):match('has no upstream branch') then
      local br = git({ 'symbolic-ref', '--quiet', '--short', 'HEAD' }, { allow_fail = true })
      if br.code == 0 then run({ 'push', '-u', 'origin', chomp(br.stdout) }) end
    elseif not ok then
      vim.notify('git push:\n' .. chomp(res.stderr), vim.log.levels.WARN)
    end
    M.refresh()
  end
  function M.pull() run({ 'pull', '--ff-only' }); M.refresh() end
  function M.fetch() run({ 'fetch', '--all', '--prune' }); M.refresh() end

  local HELP = {
    'Git Panel — keys',
    '',
    '  <Tab>   switch Changes view (Staged/Unstaged <-> Committed/Uncommitted)',
    '  <CR>    act on item: section->fold, branch->checkout, worktree->switch,',
    '          file->open, commit->show, push->show its commits',
    '  za      fold / unfold section under cursor',
    '',
    '  s / u   stage / unstage file under cursor',
    '  S / U   Stage All / Unstage All',
    '  x       discard changes to file under cursor (confirm)',
    '',
    '  Conflicts (during a merge / rebase / cherry-pick / revert):',
    '  <CR>    open the conflicted file at the first <<<<<<< marker',
    '  o / t   resolve file under cursor: take ours / take theirs (then staged)',
    '          (note: git inverts ours/theirs during a rebase — see the banner)',
    '  s       mark the file resolved (git add) after editing it by hand',
    '  >       continue / finish the operation (<op> --continue)',
    '  A       abort the whole operation (confirm)',
    '',
    '  c       commit staged       C   Commit All (stage everything + commit)',
    '  a       amend last commit',
    '',
    '  <CR>    (on a branch) checkout      b   new branch',
    '  m       merge branch under cursor into current',
    '  d       delete branch / remove worktree (context-sensitive)',
    '  W       new worktree',
    '',
    '  F / P   pull (--ff-only) / push     f   fetch --all --prune',
    '  L       toggle layout (full tab <-> left split)',
    '  r       refresh    g? / ?  this help    q   close',
  }
  function M.help()
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, HELP)
    api.nvim_set_option_value('modifiable', false, { buf = buf })
    local width, height = 76, #HELP + 2
    local win = api.nvim_open_win(buf, true, {
      relative = 'editor', style = 'minimal', border = 'rounded',
      width = width, height = height,
      row = math.max(0, math.floor((vim.o.lines - height) / 2)),
      col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    })
    api.nvim_set_option_value('cursorline', false, { win = win })
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, nowait = true, silent = true })
    vim.keymap.set('n', '<esc>', '<cmd>close<cr>', { buffer = buf, nowait = true, silent = true })
  end

  function M.attach_keys()
    local buf = M.buf
    local function k(lhs, fnc, desc)
      vim.keymap.set('n', lhs, fnc, { buffer = buf, nowait = true, silent = true, desc = 'GitPanel: ' .. desc })
    end
    k('<CR>', M.primary, 'primary action')
    k('<Tab>', M.toggle_view, 'switch Changes view')
    k('za', M.toggle_fold, 'fold/unfold section')
    k('s', M.stage, 'stage file')
    k('u', M.unstage, 'unstage file')
    k('S', M.stage_all, 'Stage All')
    k('U', M.unstage_all, 'Unstage All')
    k('x', M.discard, 'discard file (confirm)')
    k('o', M.resolve_ours, 'resolve conflict: take ours')
    k('t', M.resolve_theirs, 'resolve conflict: take theirs')
    k('>', M.op_continue, 'continue merge/rebase/cherry-pick')
    k('A', M.op_abort, 'abort merge/rebase/cherry-pick')
    k('c', M.commit, 'commit staged')
    k('C', M.commit_all, 'Commit All')
    k('a', M.amend, 'amend')
    k('b', M.new_branch, 'new branch')
    k('m', M.merge, 'merge branch into current')
    k('d', function()
      local it = cur_item()
      if it and it.kind == 'worktree' then M.remove_worktree() else M.delete_branch() end
    end, 'delete branch / remove worktree')
    k('W', M.new_worktree, 'new worktree')
    k('P', M.push, 'push')
    k('F', M.pull, 'pull (--ff-only)')
    k('f', M.fetch, 'fetch')
    k('L', M.toggle_layout, 'toggle tab/split')
    k('r', M.refresh, 'refresh')
    k('q', M.close, 'close panel')
    k('g?', M.help, 'help')
    k('?', M.help, 'help')
  end

  -- startup wiring
  define_hl()
  api.nvim_create_autocmd('ColorScheme', {
    group = api.nvim_create_augroup('GitPanelHl', { clear = true }),
    callback = define_hl,
  })

  return M
end)()

_G.GitPanel = GitPanel

vim.keymap.set('n', '<leader>gg', function() GitPanel.open('tab') end,
  { desc = 'Git panel (custom dashboard)' })
vim.keymap.set('n', '<leader>gG', function() GitPanel.open('split') end,
  { desc = 'Git panel (left split)' })
vim.api.nvim_create_user_command('GitPanel', function() GitPanel.open('tab') end,
  { desc = 'Open the custom Git panel' })
vim.api.nvim_create_user_command('GitPanelSplit', function() GitPanel.open('split') end,
  { desc = 'Open the custom Git panel as a left split' })
