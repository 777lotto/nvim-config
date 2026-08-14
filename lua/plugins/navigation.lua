local keymap = vim.keymap

return {
{
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- Routes vim.ui.select() (e.g. code-action pickers) through Telescope.
    -- Maintained replacement for the now-archived dressing.nvim.
    "nvim-telescope/telescope-ui-select.nvim",
  },
  config = function()
    require("telescope").setup({
      extensions = {
        ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
      },
    })
    require("telescope").load_extension("ui-select")
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
   local function on_attach(bufnr)
     local api = require("nvim-tree.api")

     -- Keep nvim-tree's complete default keymap, then make every terminal
     -- representation of Enter perform the same open/expand action. Some
     -- terminal/SSH combinations send LF or keypad Enter instead of CR.
     api.config.mappings.default_on_attach(bufnr)
     local opts = {
       buffer = bufnr,
       desc = "nvim-tree: Open / expand",
       noremap = true,
       silent = true,
       nowait = true,
     }
     for _, lhs in ipairs({ "<CR>", "<NL>", "<kEnter>" }) do
       vim.keymap.set("n", lhs, api.node.open.edit, opts)
     end
   end

   require("nvim-tree").setup({
     on_attach = on_attach,
     renderer = {
       -- Dotfiles stay visible, but mute both their names and icons so they
       -- remain visually distinct from ordinary files and directories.
       highlight_hidden = "all",
     },
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
 keymap.set("n", "<leader>fe", "<cmd>NvimTreeToggle<CR>", { desc = "File Explorer (toggle)" })
end,
},

{
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      -- Toggle the floating terminal with Ctrl-\ (a real control byte, so it
      -- survives common terminal and SSH layers). It works in normal AND
      -- terminal mode, so
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

    -- Exit terminal mode with Escape. Keep this autocmd local to the plugin
    -- instead of clearing every TermOpen autocmd in the user's configuration.
    local terminal_group = vim.api.nvim_create_augroup("ToggleTermKeymaps", { clear = true })
    vim.api.nvim_create_autocmd("TermOpen", {
      group = terminal_group,
      pattern = "term://*",
      callback = function(event)
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], { buffer = event.buf })
      end,
    })

    -- =====================================================================
    -- LAZYGIT — full-screen Git TUI on <leader>gl (worktrees + fast stage /
    -- commit / push / pull). The richer, categorized Git UI now lives on
    -- <leader>gg (the local GitPanel plugin); Neogit's
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
}
