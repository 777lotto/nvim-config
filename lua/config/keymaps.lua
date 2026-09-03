-- =============================================================================
-- KEYMAPS
-- =============================================================================
local keymap = vim.keymap

-- Remap the command key to backtick.
keymap.set("n", "`", ":")

local function notify(message, level, title)
  vim.notify(message, level or vim.log.levels.INFO, { title = title })
end

local function move_buffer_to(command)
  for _ = 1, #vim.fn.getbufinfo({ buflisted = 1 }) do
    vim.cmd(command)
  end
end

local function rename_current_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local old_name = vim.api.nvim_buf_get_name(bufnr)

  if old_name == "" or vim.bo[bufnr].buftype ~= "" then
    notify("The current buffer is not a file.", vim.log.levels.WARN, "File rename")
    return
  end
  if vim.bo[bufnr].modified then
    notify("Save the current file before renaming it.", vim.log.levels.WARN, "File rename")
    return
  end

  local old_path = vim.fs.normalize(vim.fn.fnamemodify(old_name, ":p"))
  local old_basename = vim.fs.basename(old_path)

  vim.ui.input({
    prompt = "File name / rename: ",
    default = old_basename,
  }, function(input)
    if input == nil then return end

    local new_basename = vim.trim(input)
    if new_basename == "" or new_basename == old_basename then return end
    if new_basename == "."
      or new_basename == ".."
      or new_basename:find("/", 1, true)
      or new_basename:find("\\", 1, true)
    then
      notify("Enter a file name without a directory path.", vim.log.levels.ERROR, "File rename")
      return
    end

    local new_path = vim.fs.joinpath(vim.fs.dirname(old_path), new_basename)
    if vim.uv.fs_stat(new_path) then
      notify("A file with that name already exists.", vim.log.levels.ERROR, "File rename")
      return
    end

    local ok, err = pcall(vim.lsp.util.rename, old_path, new_path)
    if not ok then
      notify("Could not rename the file: " .. tostring(err), vim.log.levels.ERROR, "File rename")
      return
    end
    if vim.uv.fs_stat(old_path) or not vim.uv.fs_stat(new_path) then
      notify("The file was not renamed.", vim.log.levels.ERROR, "File rename")
      return
    end

    notify("Renamed to " .. new_basename, nil, "File rename")
  end)
end

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
    if line:match("%S") then
      n = n + 1
      lines[i] = fn(line, n)
    end
  end
  vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, lines)
end

local function edit_all_match(line1, line2, pattern)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  for _, line in ipairs(lines) do
    if line:match("%S") and not line:match(pattern) then return false end
  end
  return true
end

vim.api.nvim_create_user_command("BulletToggle", function(options)
  local on = edit_all_match(options.line1, options.line2, "^%s*%- ")
  edit_transform_range(options.line1, options.line2, function(line)
    local indent, rest = edit_split_indent(line)
    if on then return indent .. (rest:gsub("^%- ", "")) end
    return indent .. "- " .. rest
  end)
end, { range = true, desc = "Toggle '- ' bullets on the range" })

vim.api.nvim_create_user_command("NumberToggle", function(options)
  local on = edit_all_match(options.line1, options.line2, "^%s*%d+%. ")
  edit_transform_range(options.line1, options.line2, function(line, index)
    local indent, rest = edit_split_indent(line)
    if on then return indent .. (rest:gsub("^%d+%. ", "")) end
    return indent .. index .. ". " .. rest
  end)
end, { range = true, desc = "Toggle '1. ' numbering on the range" })

vim.api.nvim_create_user_command("CheckboxToggle", function(options)
  local on = edit_all_match(options.line1, options.line2, "^%s*%- %[.%] ")
  edit_transform_range(options.line1, options.line2, function(line)
    local indent, rest = edit_split_indent(line)
    if on then return indent .. (rest:gsub("^%- %[.%] ", "")) end
    rest = rest:gsub("^%- ", "")
    return indent .. "- [ ] " .. rest
  end)
end, { range = true, desc = "Toggle '- [ ] ' checkboxes on the range" })

-- =============================================================================
-- LEADER MENUS
-- Lowercase groups are listed first, followed by uppercase groups. which-key
-- applies the same case-aware alphabetical order in its popup.
-- =============================================================================

-- ---- (b)uffer ---------------------------------------------------------------
-- The bar at the top uses bufferline's "buffers" mode. These mappings operate
-- on buffers, not on Neovim tab pages, so the UI and names use "buffer" only.
keymap.set("n", "<leader>ba", "<cmd>buffer #<cr>", { desc = "Alternate buffer" })
keymap.set("n", "<leader>bc", "<cmd>enew<cr>", { desc = "Create buffer" })
keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
keymap.set("n", "<leader>bf", "<cmd>BufferLineGoToBuffer 1<cr>", { desc = "First buffer" })
keymap.set("n", "<leader>bl", "<cmd>BufferLineGoToBuffer -1<cr>", { desc = "Last buffer" })
keymap.set("n", "<leader>bmf", function() move_buffer_to("BufferLineMovePrev") end, { desc = "Move to first" })
keymap.set("n", "<leader>bml", function() move_buffer_to("BufferLineMoveNext") end, { desc = "Move to last" })
keymap.set("n", "<leader>bmn", "<cmd>BufferLineMoveNext<cr>", { desc = "Move right" })
keymap.set("n", "<leader>bmp", "<cmd>BufferLineMovePrev<cr>", { desc = "Move left" })
keymap.set("n", "<leader>bn", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
keymap.set("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", { desc = "Delete other buffers" })
keymap.set("n", "<leader>bp", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
keymap.set("n", "<leader>bs", "<cmd>BufferLinePick<cr>", { desc = "Select buffer by letter" })

-- These fast buffer motions deliberately replace H/L's screen-edge motions.
keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })

-- ---- (e)dit -----------------------------------------------------------------
keymap.set("n", "<leader>ea", "ggVG", { desc = "Select all" })
keymap.set("n", "<leader>eb", "<cmd>BulletToggle<cr>", { desc = "Toggle bullet list" })
keymap.set("x", "<leader>eb", ":BulletToggle<cr>", { desc = "Toggle bullet list" })
keymap.set("n", "<leader>ed", "<cmd>t.<cr>", { desc = "Duplicate line" })
keymap.set("x", "<leader>ed", ":t '><cr>", { desc = "Duplicate selection" })
keymap.set("n", "<leader>ej", "<cmd>m .+1<cr>==", { desc = "Move line down" })
keymap.set("x", "<leader>ej", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
keymap.set("n", "<leader>ek", "<cmd>m .-2<cr>==", { desc = "Move line up" })
keymap.set("x", "<leader>ek", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
keymap.set("n", "<leader>el", "V", { desc = "Select line" })
keymap.set("n", "<leader>eo", "<cmd>NumberToggle<cr>", { desc = "Toggle numbered list" })
keymap.set("x", "<leader>eo", ":NumberToggle<cr>", { desc = "Toggle numbered list" })
keymap.set("n", "<leader>ep", "vip", { desc = "Select paragraph" })
keymap.set("n", "<leader>es", "v", { desc = "Start selection" })
keymap.set("n", "<leader>ex", "<cmd>CheckboxToggle<cr>", { desc = "Toggle checkboxes" })
keymap.set("x", "<leader>ex", ":CheckboxToggle<cr>", { desc = "Toggle checkboxes" })
keymap.set("x", "<leader>eS", ":sort<cr>", { desc = "Sort selected lines" })
keymap.set("n", "<leader>e/", "gcc", { remap = true, desc = "Toggle comment" })
keymap.set("x", "<leader>e/", "gc", { remap = true, desc = "Toggle comment" })
keymap.set("n", "<leader>e<", "<<", { desc = "Outdent line" })
keymap.set("x", "<leader>e<", "<gv", { desc = "Outdent selection" })
keymap.set("n", "<leader>e>", ">>", { desc = "Indent line" })
keymap.set("x", "<leader>e>", ">gv", { desc = "Indent selection" })

-- Direct edit motions remain available without opening the leader menu.
keymap.set("n", "<M-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
keymap.set("x", "<M-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
keymap.set("n", "<M-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
keymap.set("x", "<M-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
keymap.set("x", "<Tab>", ">gv", { desc = "Indent selection" })
keymap.set("x", "<S-Tab>", "<gv", { desc = "Outdent selection" })

-- ---- (f)ile -----------------------------------------------------------------
keymap.set("n", "<leader>fn", rename_current_file, { desc = "File name / rename" })
keymap.set("n", "<leader>fr", "<C-r>", { desc = "Redo" })
keymap.set("n", "<leader>fs", "<cmd>write<cr>", { desc = "Save file" })
keymap.set("n", "<leader>fu", "u", { desc = "Undo" })
keymap.set("n", "<leader>fS", "<cmd>wall<cr>", { desc = "Save all files" })

-- ---- (n)avigate -------------------------------------------------------------
-- These motions extend an existing visual selection where that is meaningful.
keymap.set({ "n", "x" }, "<leader>nb", "G", { desc = "Bottom of document" })
keymap.set({ "n", "x" }, "<leader>nc", "zz", { desc = "Center cursor" })
keymap.set({ "n", "x" }, "<leader>ne", "$", { desc = "End of line" })
keymap.set("n", "<leader>ng", function()
  local line = tonumber(vim.fn.input("Go to line: "))
  if line then vim.cmd("normal! " .. line .. "G") end
end, { desc = "Go to line number" })
keymap.set("n", "<leader>ni", "<C-i>", { desc = "Newer jump" })
keymap.set({ "n", "x" }, "<leader>nj", "}", { desc = "Next paragraph" })
keymap.set({ "n", "x" }, "<leader>nk", "{", { desc = "Previous paragraph" })
keymap.set({ "n", "x" }, "<leader>nm", "%", { desc = "Matching bracket" })
keymap.set("n", "<leader>no", "<C-o>", { desc = "Older jump" })
keymap.set({ "n", "x" }, "<leader>ns", "^", { desc = "Start of line" })
keymap.set({ "n", "x" }, "<leader>nt", "gg", { desc = "Top of document" })

-- ---- (q)uit -----------------------------------------------------------------
-- Modified buffers still trigger Neovim's ordinary save warning.
keymap.set("n", "<leader>qa", "<cmd>qall<cr>", { desc = "Quit all" })
keymap.set("n", "<leader>qq", "<cmd>quit<cr>", { desc = "Quit current window" })

-- ---- (w)ord -----------------------------------------------------------------
keymap.set("n", "<leader>wf", function()
  require("telescope.builtin").current_buffer_fuzzy_find({
    default_text = vim.fn.expand("<cword>"),
  })
end, { desc = "Find word in file" })
keymap.set("n", "<leader>wn", "*", { desc = "Next occurrence" })
keymap.set("n", "<leader>wp", "#", { desc = "Previous occurrence" })
keymap.set("n", "<leader>wr", vim.lsp.buf.rename, { desc = "Rename symbol" })
keymap.set("n", "<leader>ws", "viw", { desc = "Select word" })
keymap.set("n", "<leader>wu", "guiw", { desc = "Lowercase word" })
keymap.set("x", "<leader>wu", "u", { desc = "Lowercase selection" })
keymap.set("n", "<leader>wU", "gUiw", { desc = "Uppercase word" })
keymap.set("x", "<leader>wU", "U", { desc = "Uppercase selection" })

-- ---- (W)indow ---------------------------------------------------------------
keymap.set("n", "<leader>Wc", "<cmd>close<cr>", { desc = "Close window" })
keymap.set("n", "<leader>Wh", "<C-w>h", { desc = "Focus left" })
keymap.set("n", "<leader>Wj", "<C-w>j", { desc = "Focus down" })
keymap.set("n", "<leader>Wk", "<C-w>k", { desc = "Focus up" })
keymap.set("n", "<leader>Wl", "<C-w>l", { desc = "Focus right" })
keymap.set("n", "<leader>Wo", "<C-w>o", { desc = "Close other windows" })
keymap.set("n", "<leader>Ws", "<C-w>s", { desc = "Split horizontally" })
keymap.set("n", "<leader>Wv", "<C-w>v", { desc = "Split vertically" })
keymap.set("n", "<leader>W=", "<C-w>=", { desc = "Equalize windows" })

keymap.set("n", "<M-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
keymap.set("n", "<M-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
keymap.set("n", "<M-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
keymap.set("n", "<M-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Discover every menu and mapping.
keymap.set("n", "<leader>?", "<cmd>WhichKey<cr>", { desc = "Show all keymaps" })
