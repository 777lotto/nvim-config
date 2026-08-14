-- =============================================================================
-- KEYMAPS
-- =============================================================================
local keymap = vim.keymap

-- Remap command key to backtick
keymap.set('n', '`', ':')

-- Save file
keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
keymap.set("n", "<leader>W", "<cmd>wa<CR>", { desc = "Save all files" })

-- Quit without forcing: modified buffers still trigger Neovim's save warning.
keymap.set("n", "<leader>qq", "<cmd>quit<CR>", { desc = "Quit current window" })
keymap.set("n", "<leader>qa", "<cmd>qall<CR>", { desc = "Quit all" })

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
-- EDIT & NAVIGATE MENUS   (<leader>e  /  <leader>n)
-- =============================================================================
-- Two which-key menus for "normal editor"-style editing and movement.
--   <leader>e  → Edit menu       <leader>n → Navigate menu
-- Most entries work in BOTH modes: in normal mode they act on the current
-- line/word; make a visual selection first and they act on the whole selection.
-- (Press <leader>e / <leader>n and pause to see the popup with every choice.)

-- ---- List helpers: bullets / numbers / checkboxes ---------------------------
-- Each toggles a prefix on every non-blank line in the range: if all lines
-- already have it, it is stripped; otherwise it is added. Indentation is kept.
local function edit_split_indent(line)
  local indent = line:match("^%s*")
  return indent, line:sub(#indent + 1)
end

local function edit_transform_range(line1, line2, fn)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  local n = 0
  for i, line in ipairs(lines) do
    if line:match("%S") then -- skip blank lines
      n = n + 1
      lines[i] = fn(line, n)
    end
  end
  vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, lines)
end

local function edit_all_match(line1, line2, pat)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  for _, line in ipairs(lines) do
    if line:match("%S") and not line:match(pat) then return false end
  end
  return true
end

vim.api.nvim_create_user_command("BulletToggle", function(o)
  local on = edit_all_match(o.line1, o.line2, "^%s*%- ")
  edit_transform_range(o.line1, o.line2, function(line)
    local indent, rest = edit_split_indent(line)
    if on then return indent .. (rest:gsub("^%- ", "")) end
    return indent .. "- " .. rest
  end)
end, { range = true, desc = "Toggle '- ' bullets on the range" })

vim.api.nvim_create_user_command("NumberToggle", function(o)
  local on = edit_all_match(o.line1, o.line2, "^%s*%d+%. ")
  edit_transform_range(o.line1, o.line2, function(line, i)
    local indent, rest = edit_split_indent(line)
    if on then return indent .. (rest:gsub("^%d+%. ", "")) end
    return indent .. i .. ". " .. rest
  end)
end, { range = true, desc = "Toggle '1. ' numbering on the range" })

vim.api.nvim_create_user_command("CheckboxToggle", function(o)
  local on = edit_all_match(o.line1, o.line2, "^%s*%- %[.%] ")
  edit_transform_range(o.line1, o.line2, function(line)
    local indent, rest = edit_split_indent(line)
    if on then return indent .. (rest:gsub("^%- %[.%] ", "")) end
    rest = rest:gsub("^%- ", "") -- avoid "- - [ ] " doubling
    return indent .. "- [ ] " .. rest
  end)
end, { range = true, desc = "Toggle '- [ ] ' checkboxes on the range" })

-- ---- EDIT menu: <leader>e ---------------------------------------------------
-- Select (normal mode). After any of these, extend with the arrow keys.
keymap.set("n", "<leader>es", "v",    { desc = "Select — start (extend with arrows)" })
keymap.set("n", "<leader>el", "V",    { desc = "Select whole line(s)" })
keymap.set("n", "<leader>ea", "ggVG", { desc = "Select all" })
keymap.set("n", "<leader>ew", "viw",  { desc = "Select word" })
keymap.set("n", "<leader>ep", "vip",  { desc = "Select paragraph" })

-- Indent / outdent.  Bonus: <Tab> / <S-Tab> indent a visual selection directly.
keymap.set("n", "<leader>e>", ">>",  { desc = "Indent line" })
keymap.set("n", "<leader>e<", "<<",  { desc = "Outdent line" })
keymap.set("x", "<leader>e>", ">gv", { desc = "Indent selection" })
keymap.set("x", "<leader>e<", "<gv", { desc = "Outdent selection" })
keymap.set("x", "<Tab>",   ">gv", { desc = "Indent selection" })
keymap.set("x", "<S-Tab>", "<gv", { desc = "Outdent selection" })

-- Move / duplicate lines.  Bonus: Alt-j / Alt-k move directly.
keymap.set("n", "<leader>ej", "<cmd>m .+1<cr>==", { desc = "Move line down" })
keymap.set("n", "<leader>ek", "<cmd>m .-2<cr>==", { desc = "Move line up" })
keymap.set("x", "<leader>ej", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
keymap.set("x", "<leader>ek", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
keymap.set("n", "<M-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
keymap.set("n", "<M-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
keymap.set("x", "<M-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
keymap.set("x", "<M-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
keymap.set("n", "<leader>ed", "<cmd>t.<cr>", { desc = "Duplicate line" })
keymap.set("x", "<leader>ed", ":t '><cr>",   { desc = "Duplicate selection" })

-- Comment (uses the built-in gc / gcc commenting)
keymap.set("n", "<leader>e/", "gcc", { remap = true, desc = "Toggle comment" })
keymap.set("x", "<leader>e/", "gc",  { remap = true, desc = "Toggle comment" })

-- Change case
keymap.set("n", "<leader>eu", "guiw", { desc = "Lowercase word" })
keymap.set("n", "<leader>eU", "gUiw", { desc = "UPPERCASE word" })
keymap.set("x", "<leader>eu", "u",    { desc = "Lowercase selection" })
keymap.set("x", "<leader>eU", "U",    { desc = "UPPERCASE selection" })

-- Lists / bullets (current line in normal mode, whole selection in visual mode)
keymap.set("n", "<leader>eb", "<cmd>BulletToggle<cr>",   { desc = "Toggle bullet list  '- '" })
keymap.set("n", "<leader>eo", "<cmd>NumberToggle<cr>",   { desc = "Toggle numbered list  '1. '" })
keymap.set("n", "<leader>ex", "<cmd>CheckboxToggle<cr>", { desc = "Toggle checkboxes  '- [ ] '" })
keymap.set("x", "<leader>eb", ":BulletToggle<cr>",   { desc = "Toggle bullet list  '- '" })
keymap.set("x", "<leader>eo", ":NumberToggle<cr>",   { desc = "Toggle numbered list  '1. '" })
keymap.set("x", "<leader>ex", ":CheckboxToggle<cr>", { desc = "Toggle checkboxes  '- [ ] '" })

-- Sort selected lines
keymap.set("x", "<leader>eS", ":sort<cr>", { desc = "Sort selected lines" })

-- ---- NAVIGATE menu: <leader>n -----------------------------------------------
-- Motions that also work in visual mode (they extend the selection).
keymap.set({ "n", "x" }, "<leader>ns", "^",  { desc = "Start of line" })
keymap.set({ "n", "x" }, "<leader>ne", "$",  { desc = "End of line" })
keymap.set({ "n", "x" }, "<leader>nt", "gg", { desc = "Top of document" })
keymap.set({ "n", "x" }, "<leader>nb", "G",  { desc = "Bottom of document" })
keymap.set({ "n", "x" }, "<leader>nc", "zz", { desc = "Center cursor on screen" })
keymap.set({ "n", "x" }, "<leader>nm", "%",  { desc = "Jump to matching bracket" })
keymap.set({ "n", "x" }, "<leader>nj", "}",  { desc = "Next paragraph" })
keymap.set({ "n", "x" }, "<leader>nk", "{",  { desc = "Previous paragraph" })

-- Occurrences of the word under the cursor (normal mode)
keymap.set("n", "<leader>no", "*", { desc = "Jump to next occurrence of word" })
keymap.set("n", "<leader>nO", "#", { desc = "Jump to previous occurrence of word" })
keymap.set("n", "<leader>nf", function()
  require("telescope.builtin").current_buffer_fuzzy_find({
    default_text = vim.fn.expand("<cword>"),
  })
end, { desc = "Find ALL occurrences of word in file (list)" })

-- Go to a specific line number
keymap.set("n", "<leader>ng", function()
  local n = tonumber(vim.fn.input("Go to line: "))
  if n then vim.cmd("normal! " .. n .. "G") end
end, { desc = "Go to line number…" })
