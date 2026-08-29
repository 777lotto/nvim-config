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

    keymap.set("n", "<leader>bb", "<cmd>Telescope buffers<cr>", { desc = "Browse buffers" })
    keymap.set("n", "<leader>ds", "<cmd>Telescope diagnostics<cr>", { desc = "Search diagnostics" })
    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
    keymap.set("n", "<leader>fo", "<cmd>Telescope oldfiles<cr>", { desc = "Open recent file" })
    keymap.set("n", "<leader>gb", "<cmd>Telescope git_branches<cr>", { desc = "Branches" })
    keymap.set("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", { desc = "Commits" })
    keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<cr>", { desc = "Status" })
    keymap.set("n", "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Buffer text" })
    keymap.set("n", "<leader>sh", "<cmd>Telescope help_tags<cr>", { desc = "Help" })
    keymap.set("n", "<leader>sk", "<cmd>Telescope keymaps<cr>", { desc = "Keymaps" })
    keymap.set("n", "<leader>sr", "<cmd>Telescope resume<cr>", { desc = "Resume last search" })
    keymap.set("n", "<leader>ss", "<cmd>Telescope grep_string<cr>", { desc = "Word under cursor" })
    keymap.set("v", "<leader>ss", "<cmd>Telescope grep_string<cr>", { desc = "Selected text" })
    keymap.set("n", "<leader>sw", function()
      require("config.project_search").live_grep()
    end, { desc = "Workspace text" })
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
 keymap.set("n", "<leader>fe", "<cmd>NvimTreeToggle<CR>", { desc = "File explorer" })
end,
},

{
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    -- Each invocation creates a new, ordinary terminal buffer. These terminals
    -- are deliberately independent from the persistent ToggleTerm instance
    -- below, and appear as separate entries in the buffer bar.
    local function open_terminal(split)
      if split then vim.cmd(split) end
      vim.cmd("terminal")
      vim.cmd("startinsert")
    end

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
    -- <C-\>; it does not share a job with the <leader>T* terminal buffers.
    vim.api.nvim_create_user_command("FloatTerminal", function()
      vim.cmd("ToggleTerm direction=float")
    end, { desc = "Toggle the persistent floating terminal" })
    keymap.set("n", "<leader>Tf", "<cmd>FloatTerminal<cr>", { desc = "Floating terminal" })
    keymap.set("n", "<leader>Th", function() open_terminal("botright split") end,
      { desc = "Horizontal terminal", noremap = true, silent = true })
    keymap.set("n", "<leader>Tn", function() open_terminal() end,
      { desc = "New terminal buffer", noremap = true, silent = true })
    keymap.set("n", "<leader>Tv", function() open_terminal("botright vsplit") end,
      { desc = "Vertical terminal", noremap = true, silent = true })

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
