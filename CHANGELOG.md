# Changelog

Notable user-visible changes are recorded here. Versions follow semantic
versioning for release organization.

## Unreleased

### Added

- Modular `lua/config/` and category-based `lua/plugins/` layout.
- Standalone-ready local `git-panel.nvim` package with commands and help.
- JSON and JSONC Treesitter support.
- `jsonls` validation/completion with SchemaStore schemas.
- Diagnostic virtual text, current-line virtual lines, floating details,
  location lists, and quickfix lists.
- Prettier coverage for all configured filetypes supported by Prettier.

### Changed

- lualine now follows runtime colorscheme changes with `theme = "auto"`.
- Quit mappings are explicit: `<leader>qq` and `<leader>qa`.
- The bootstrap script follows the repository's default branch.
- Trailing-whitespace cleanup preserves Markdown hard line breaks.
