-- =============================================================================
-- GLOBAL OPTIONS
-- =============================================================================
vim.g.mapleader = " " -- Set the leader key to the space bar
vim.g.maplocalleader = " "

vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.tabstop = 2           -- Number of spaces a tab is
vim.opt.shiftwidth = 2        -- Number of spaces to indent
vim.opt.expandtab = true      -- Use spaces instead of tabs
vim.opt.smartindent = true    -- Be smart about indentation
vim.opt.wrap = true           -- Enable wrapping
vim.opt.linebreak = true      -- Wrap lines at convenient points (words) NOT characters
vim.opt.breakindent = true    -- Maintain indentation when wrapping
vim.opt.hidden = true         -- Keep terminal jobs alive when their buffers/windows are hidden
vim.opt.termguicolors = true  -- Enable true color support
vim.opt.scrolloff = 8         -- Keep 8 lines of context around the cursor
vim.opt.mouse = 'a'           -- Enable mouse support
vim.opt.timeoutlen = 500      -- Wait 500ms for a key sequence (snappier which-key popup)
