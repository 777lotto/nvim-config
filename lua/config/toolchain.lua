-- Single source of truth for editor/runtime compatibility and managed tools.
-- Plugin commits remain reproducibly pinned in lazy-lock.json; unversioned
-- Mason entries intentionally mean the newest registry version available when
-- the updater runs.
local M = {}

M.neovim = {
  minimum = "0.12.0",
  tested = "0.12.4",
}

M.node = {
  minimum_major = 22,
  recommended_major = 24,
  canary_major = 26,
}

M.parsers = {
  "c", "lua", "vim", "vimdoc", "query", "javascript", "typescript",
  "tsx", "python", "html", "xml", "css", "json", "markdown",
  "markdown_inline", "bash", "toml", "kdl",
}

M.parser_filetypes = {
  "c", "lua", "vim", "help", "query", "javascript", "javascriptreact",
  "typescript", "typescriptreact", "python", "html", "xml", "css", "json",
  "jsonc", "markdown", "sh", "toml", "kdl",
}

-- mason-lspconfig uses Neovim LSP server names.
M.lsp_servers = {
  "lua_ls", "pyright", "ts_ls", "html", "cssls", "jsonls", "marksman",
}

-- mason-tool-installer uses Mason registry package names. Keeping all external
-- executables here lets bootstrap, interactive startup, and the updater agree.
M.mason_packages = {
  "tree-sitter-cli",
  "prettier",
  "markdownlint-cli2",
  "lua-language-server",
  "pyright",
  "typescript-language-server",
  "html-lsp",
  "css-lsp",
  "json-lsp",
  "marksman",
}

M.node_backed_packages = {
  "prettier",
  "markdownlint-cli2",
  "pyright",
  "typescript-language-server",
  "html-lsp",
  "css-lsp",
  "json-lsp",
}

return M
