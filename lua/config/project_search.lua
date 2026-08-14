local M = {}

local api = vim.api
local uv = vim.uv

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Project replace" })
end

local function plural(count, singular, plural_form)
  return count == 1 and singular or (plural_form or singular .. "s")
end

local function abbreviated(text, max_chars)
  text = text:gsub("[%c]", " ")
  if vim.fn.strdisplaywidth(text) <= max_chars then return text end
  return vim.fn.strcharpart(text, 0, math.max(1, max_chars - 1)) .. "…"
end

local function replace_plain(text, search, replacement)
  local pieces = {}
  local start_at = 1
  local count = 0

  while true do
    local first, last = text:find(search, start_at, true)
    if not first then
      pieces[#pieces + 1] = text:sub(start_at)
      break
    end

    pieces[#pieces + 1] = text:sub(start_at, first - 1)
    pieces[#pieces + 1] = replacement
    start_at = last + 1
    count = count + 1
  end

  return table.concat(pieces), count
end

local function count_plain(text, search)
  local start_at = 1
  local count = 0

  while true do
    local first, last = text:find(search, start_at, true)
    if not first then return count end
    start_at = last + 1
    count = count + 1
  end
end

local function open_replacement_input(search, callback)
  local width = math.max(1, math.min(64, vim.o.columns - 4))
  local usable_lines = math.max(1, vim.o.lines - vim.o.cmdheight)
  local title_text = abbreviated(search, math.max(1, width - 18))
  local buf = api.nvim_create_buf(false, true)

  vim.bo[buf].buftype = "prompt"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.fn.prompt_setprompt(buf, "› ")

  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    title = " Replace " .. title_text .. " with ",
    title_pos = "center",
    width = width,
    height = 1,
    row = math.max(0, math.floor((usable_lines - 3) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
  })
  vim.wo[win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"

  local finished = false
  local function finish(value)
    if finished then return end
    finished = true
    if api.nvim_win_is_valid(win) then api.nvim_win_close(win, true) end
    if api.nvim_buf_is_valid(buf) then pcall(api.nvim_buf_delete, buf, { force = true }) end
    vim.schedule(function() callback(value) end)
  end

  local function submit()
    local line = api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    finish(line)
  end

  vim.keymap.set({ "i", "n" }, "<CR>", submit, { buffer = buf, silent = true })
  vim.keymap.set({ "i", "n" }, "<Esc>", function() finish(nil) end, { buffer = buf, silent = true })
  vim.keymap.set({ "i", "n" }, "<C-c>", function() finish(nil) end, { buffer = buf, silent = true })
  api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function() finish(nil) end,
  })

  vim.cmd("startinsert")
end

local function buffer_for_path(path)
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    local name = api.nvim_buf_get_name(bufnr)
    if name ~= "" and vim.fs.normalize(name) == path then return bufnr end
  end
end

local function read_file(path)
  local fd, open_error = uv.fs_open(path, "r", 438)
  if not fd then return nil, nil, open_error end

  local stat, stat_error = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return nil, nil, stat_error
  end

  local contents = ""
  if stat.size > 0 then
    local read_error
    contents, read_error = uv.fs_read(fd, stat.size, 0)
    if not contents then
      uv.fs_close(fd)
      return nil, nil, read_error
    end
  end
  uv.fs_close(fd)
  return contents, stat
end

local function same_fingerprint(path, expected)
  local current = uv.fs_stat(path)
  return current
    and current.size == expected.size
    and current.mtime.sec == expected.mtime.sec
    and current.mtime.nsec == expected.mtime.nsec
end

local function scan_exact_matches(search, cwd, callback)
  vim.system({
    "rg",
    "--files-with-matches",
    "--null",
    "--fixed-strings",
    "--case-sensitive",
    "--",
    search,
    ".",
  }, { cwd = cwd, text = false }, function(result)
    vim.schedule(function()
      if result.code == 1 then
        callback({})
        return
      end
      if result.code ~= 0 then
        local detail = (result.stderr or ""):gsub("%s+$", "")
        callback(nil, detail ~= "" and detail or "ripgrep could not scan the project")
        return
      end

      local files = {}
      local modified = {}
      local paths = vim.split(result.stdout or "", "\0", { plain = true, trimempty = true })
      for _, relative_path in ipairs(paths) do
        relative_path = relative_path:gsub("^%./", "")
        local path = relative_path:sub(1, 1) == "/"
            and vim.fs.normalize(relative_path)
          or vim.fs.normalize(cwd .. "/" .. relative_path)
        local bufnr = buffer_for_path(path)

        if bufnr and api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].modified then
          modified[#modified + 1] = relative_path
        else
          local contents, stat, read_error = read_file(path)
          if not contents then
            callback(nil, string.format("Could not read %s: %s", relative_path, read_error or "unknown error"))
            return
          end

          local count = count_plain(contents, search)
          if count > 0 then
            files[#files + 1] = {
              path = path,
              relative_path = relative_path,
              count = count,
              fingerprint = stat,
            }
          end
        end
      end

      if #modified > 0 then
        local sample = table.concat(vim.list_slice(modified, 1, math.min(3, #modified)), ", ")
        if #modified > 3 then sample = sample .. ", …" end
        callback(nil, "Save modified matching buffers first: " .. sample)
        return
      end
      callback(files)
    end)
  end)
end

local function restore_buffer(item)
  if item.was_loaded or not api.nvim_buf_is_valid(item.bufnr) then return end
  if item.existed then
    pcall(api.nvim_buf_delete, item.bufnr, { unload = true })
  else
    pcall(api.nvim_buf_delete, item.bufnr, { force = false })
  end
end

local function restore_buffers(items, first)
  for index = first or 1, #items do restore_buffer(items[index]) end
end

local function prepare_buffers(files, search, replacement)
  local prepared = {}

  for _, file in ipairs(files) do
    if not same_fingerprint(file.path, file.fingerprint) then
      restore_buffers(prepared)
      return nil, file.relative_path .. " changed after the scan; run the replacement again"
    end

    local bufnr = buffer_for_path(file.path)
    local existed = bufnr ~= nil
    if not bufnr then bufnr = vim.fn.bufadd(file.path) end

    local item = {
      bufnr = bufnr,
      existed = existed,
      was_loaded = api.nvim_buf_is_loaded(bufnr),
      relative_path = file.relative_path,
      count = file.count,
    }
    prepared[#prepared + 1] = item

    if not item.was_loaded then
      local loaded = pcall(vim.fn.bufload, bufnr)
      if not loaded or not api.nvim_buf_is_loaded(bufnr) then
        restore_buffers(prepared)
        return nil, "Could not load " .. file.relative_path
      end
    end

    if vim.bo[bufnr].modified then
      restore_buffers(prepared)
      return nil, "Save modified matching buffer first: " .. file.relative_path
    end
    if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable or vim.bo[bufnr].readonly then
      restore_buffers(prepared)
      return nil, "Matching file is not writable: " .. file.relative_path
    end

    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local count = 0
    for index, line in ipairs(lines) do
      local changed_line, line_count = replace_plain(line, search, replacement)
      lines[index] = changed_line
      count = count + line_count
    end

    if count ~= file.count then
      restore_buffers(prepared)
      return nil, file.relative_path .. " changed after the scan; run the replacement again"
    end
    item.lines = lines
  end

  return prepared
end

local function apply_replacement(files, search, replacement)
  local prepared, prepare_error = prepare_buffers(files, search, replacement)
  if not prepared then return 0, 0, prepare_error end

  local replaced = 0
  local written = 0
  for index, item in ipairs(prepared) do
    local changed, change_error = pcall(api.nvim_buf_set_lines, item.bufnr, 0, -1, false, item.lines)
    if not changed then
      restore_buffer(item)
      restore_buffers(prepared, index + 1)
      return replaced, written, string.format("Stopped at %s: %s", item.relative_path, change_error)
    end

    local saved, save_error = pcall(api.nvim_buf_call, item.bufnr, function()
      vim.cmd("silent noautocmd keepalt write")
    end)
    if not saved then
      restore_buffers(prepared, index + 1)
      return replaced, written, string.format(
        "Stopped at %s; its modified buffer was kept for recovery: %s",
        item.relative_path,
        save_error
      )
    end

    replaced = replaced + item.count
    written = written + 1
    restore_buffer(item)
  end

  return replaced, written
end

local function begin_replacement(search, cwd, reopen)
  open_replacement_input(search, function(replacement)
    if replacement == nil then
      reopen()
      return
    end
    if replacement == search then
      notify("Search and replacement text are identical", vim.log.levels.WARN)
      reopen()
      return
    end

    scan_exact_matches(search, cwd, function(files, scan_error)
      if not files then
        notify(scan_error, vim.log.levels.ERROR)
        reopen()
        return
      end
      if #files == 0 then
        notify("No exact, case-sensitive matches found", vim.log.levels.WARN)
        reopen()
        return
      end

      local matches = 0
      for _, file in ipairs(files) do matches = matches + file.count end
      local replacement_label = replacement == "" and "<delete>" or abbreviated(replacement, 30)
      local choice = string.format(
        "Replace %d %s in %d %s with %s",
        matches,
        plural(matches, "match", "matches"),
        #files,
        plural(#files, "file"),
        replacement_label
      )

      vim.ui.select({ choice, "Cancel" }, {
        prompt = "Exact, case-sensitive project replacement",
      }, function(selected)
        if selected ~= choice then
          reopen()
          return
        end

        local replaced, written, replace_error = apply_replacement(files, search, replacement)
        if replace_error then
          local prefix = written > 0 and string.format("Replaced %d matches before failure. ", replaced) or ""
          notify(prefix .. replace_error, vim.log.levels.ERROR)
          return
        end
        notify(string.format(
          "Replaced %d %s in %d %s",
          replaced,
          plural(replaced, "match", "matches"),
          written,
          plural(written, "file")
        ))
      end)
    end)
  end)
end

function M.live_grep(opts)
  opts = vim.deepcopy(opts or {})
  local user_attach_mappings = opts.attach_mappings
  opts.attach_mappings = nil
  opts.prompt_title = opts.prompt_title or "Live Grep  ·  <C-r> replace exact text"
  local resume_opts = vim.deepcopy(opts)

  opts.attach_mappings = function(prompt_bufnr, map)
    -- Telescope normally reserves these <C-r> chords for inserting text from
    -- the original buffer. Suppress them in this picker so the replacement
    -- action fires immediately instead of waiting for a possible second key.
    for _, lhs in ipairs({ "<C-r><C-w>", "<C-r><C-a>", "<C-r><C-f>", "<C-r><C-l>" }) do
      map("i", lhs, false)
    end
    map({ "i", "n" }, "<C-r>", function()
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local search = action_state.get_current_line()
      if search == "" then
        notify("Enter search text before replacing", vim.log.levels.WARN)
        return
      end

      local picker = action_state.get_current_picker(prompt_bufnr)
      local cwd = vim.fs.normalize(picker.cwd or uv.cwd())
      actions.close(prompt_bufnr)
      vim.schedule(function()
        begin_replacement(search, cwd, function()
          local reopened = vim.deepcopy(resume_opts)
          reopened.cwd = cwd
          reopened.default_text = search
          M.live_grep(reopened)
        end)
      end)
    end, { desc = "Replace exact text across the project" })

    if user_attach_mappings and user_attach_mappings(prompt_bufnr, map) == false then return false end
    return true
  end

  require("telescope.builtin").live_grep(opts)
end

return M
