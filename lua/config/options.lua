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
else
  -- On a local desktop, use the native clipboard provider (pbcopy on macOS;
  -- xclip/xsel on X11; wl-clipboard on Wayland).
  vim.opt.clipboard = "unnamedplus"
end
