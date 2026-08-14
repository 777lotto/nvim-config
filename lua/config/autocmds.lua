local group = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- Strip accidental trailing whitespace without destroying Markdown's intentional
-- two-space hard line breaks.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function(event)
    local bo = vim.bo[event.buf]
    if bo.buftype ~= "" or not bo.modifiable then return end
    if bo.filetype == "markdown" or bo.filetype == "markdown.mdx" then return end

    local lines = vim.api.nvim_buf_get_lines(event.buf, 0, -1, false)
    local changed = false
    for index, line in ipairs(lines) do
      local trimmed = line:gsub("%s+$", "")
      if trimmed ~= line then
        lines[index] = trimmed
        changed = true
      end
    end
    if changed then vim.api.nvim_buf_set_lines(event.buf, 0, -1, false, lines) end
  end,
})
