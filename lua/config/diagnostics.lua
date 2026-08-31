-- A single presentation policy for diagnostics from LSP servers and linters.
vim.diagnostic.config({
  severity_sort = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 2,
    source = "if_many",
    prefix = "●",
  },
  -- Keep the detailed virtual line focused on the cursor line; virtual_text
  -- still gives a compact summary on every affected line.
  virtual_lines = { current_line = true },
  float = {
    border = "rounded",
    source = "if_many",
    header = "",
    prefix = "",
  },
})

local keymap = vim.keymap
keymap.set("n", "<leader>df", function()
  vim.diagnostic.open_float({ scope = "cursor", focusable = true })
end, { desc = "Diagnostic details (float)" })
keymap.set("n", "<leader>dl", function()
  vim.diagnostic.setloclist({ open = true })
end, { desc = "Buffer diagnostics (location list)" })
keymap.set("n", "<leader>dq", function()
  vim.diagnostic.setqflist({ open = true })
end, { desc = "Project diagnostics (quickfix list)" })
