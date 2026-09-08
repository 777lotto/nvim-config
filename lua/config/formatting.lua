-- Formatter policy shared by conform.nvim and the smoke tests.
--
-- Biome owns the source languages it parses (JavaScript, TypeScript, JSX,
-- TSX, JSON, JSONC, CSS) and dprint owns Markdown. Prettier has no role:
-- Biome replaced it for source files across the account, and zemrip retired
-- it for Markdown on 2026-09-08 because Prettier 3.9.1 never converges on GFM
-- task-list continuations (each run indents them further). dprint is
-- idempotent there and matches Biome's split of responsibilities.
--
-- Both formatters prefer a project's own binary and config. Biome falls back
-- to buffer-local indent settings without a biome.json; dprint refuses to run
-- without a config, so a Markdown file outside any dprint project is formatted
-- with the `dprint.json` shipped at this repository's root, which mirrors the
-- zemrip wiki settings and plugin pin.
--
-- Nothing else is mapped. Lua, Python, C, XML, YAML, HTML, SCSS, Less, Vue,
-- Handlebars, GraphQL, JSON5, and MDX have no formatter until one that parses
-- the language is chosen; do not reintroduce a general-purpose fallback.
local M = {}

M.dprint_config_files = { "dprint.json", ".dprint.json", "dprint.jsonc", ".dprint.jsonc" }

M.formatters_by_ft = {
  css = { "biome" },
  javascript = { "biome" },
  javascriptreact = { "biome" },
  json = { "biome" },
  jsonc = { "biome" },
  typescript = { "biome" },
  typescriptreact = { "biome" },
  markdown = { "dprint" },
}

local function config_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fs.normalize(vim.fn.fnamemodify(source, ":p:h:h:h"))
end

function M.bundled_dprint_config()
  return vim.fs.joinpath(config_root(), "dprint.json")
end

-- The nearest ancestor of `filename` that holds a dprint config, or nil.
function M.dprint_project_root(filename)
  local found = vim.fs.find(M.dprint_config_files, {
    path = vim.fs.dirname(vim.fs.normalize(filename)),
    upward = true,
    limit = 1,
  })[1]
  return found and vim.fs.dirname(found) or nil
end

-- dprint matches `--stdin` paths against its include globs relative to the
-- working directory, so the file must live under cwd or it is passed through
-- unformatted. Inside a project that is the project root; elsewhere it is the
-- file's own directory.
function M.dprint_cwd(_, ctx)
  return M.dprint_project_root(ctx.filename) or vim.fs.dirname(vim.fs.normalize(ctx.filename))
end

function M.dprint_args(_, ctx)
  if M.dprint_project_root(ctx.filename) then
    return { "fmt", "--stdin", "$FILENAME" }
  end
  return { "fmt", "--config", M.bundled_dprint_config(), "--stdin", "$FILENAME" }
end

M.formatters = {
  dprint = {
    cwd = M.dprint_cwd,
    args = M.dprint_args,
  },
}

return M
