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
- Automatic environment policy with `NVIM_CLIPBOARD` overrides and
  `:EnvironmentInfo` diagnostics.
- GitPanel first-push publishing: create a GitHub repository with optional
  `gh`, or attach an existing remote URL and establish upstream tracking.
- GitHub community health files, structured issue forms, and Debian CI.
- Signed `bet` / `bluff` production and integration branch workflow.
- Independent terminal buffers on `<leader>tt` and an explicit
  `:FloatTerminal` command for the persistent `<C-\>` floating terminal.

### Changed

- lualine now follows runtime colorscheme changes with `theme = "auto"`.
- Quit mappings are explicit: `<leader>qq` and `<leader>qa`.
- The bootstrap script follows the repository's default branch.
- Git and SSH processes launched by Neovim use the GPG agent's Java Card socket
  when `gpgconf` reports an available socket.
- Trailing-whitespace cleanup preserves Markdown hard line breaks.
- Runtime and troubleshooting documentation now target the Debian XFCE client
  and headless Debian server instead of the former KDE/macOS environment.
- SSH clipboard integration is documented as copy-only OSC 52 pending
  end-to-end server validation.
- GitPanel accepts CR, LF, and keypad Enter locally, matching the terminal-safe
  Enter handling already used by nvim-tree.
- Project live grep now uses `<leader>sw`; `<C-r>` inside the picker performs a
  confirmed exact-text project replacement, replacing the Spectre plugin and
  its `<leader>sr` mappings. The cursor-word search mappings were removed.
- Telescope now tracks its latest stable release for compatibility with
  Neovim 0.12 and the rewritten `nvim-treesitter` API.
- Repository documentation now uses the account-wide `bet` production and
  `bluff` integration convention instead of OS-named long-lived branches.
