local keymap = vim.keymap

return {
{
  "nvim-telescope/telescope.nvim",
  version = "*",
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
    keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find Buffers" })
    keymap.set("n", "<leader>sw", function()
      require("config.project_search").live_grep()
    end, { desc = "Search Project (Live Grep)" })
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
    -- Each invocation creates a new, ordinary terminal buffer. These terminals
    -- are deliberately independent from the persistent ToggleTerm instance
    -- below, and appear as separate entries in the bufferline "tab" bar.
    keymap.set("n", "<leader>tt", function()
      vim.cmd("terminal")
      vim.cmd("startinsert")
    end, { desc = "Terminal: new buffer", noremap = true, silent = true })

    require("toggleterm").setup({
      -- Toggle one persistent floating terminal with Ctrl-\ (a real control
      -- byte, so it survives common terminal and SSH layers). Hiding its
      -- window leaves its buffer and shell job running for the Neovim session.
      -- It works in normal AND terminal mode, so the same chord dismisses the
      -- float from inside it. <esc> still drops to normal mode (its
      -- <C-\><C-n> RHS is non-recursive, so no conflict).
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

    -- This is an explicit command for the same persistent terminal toggled by
    -- <C-\>; it does not share a job with the <leader>tt terminal buffers.
    vim.api.nvim_create_user_command("FloatTerminal", function()
      vim.cmd("ToggleTerm direction=float")
    end, { desc = "Toggle the persistent floating terminal" })

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
  end
},
}
