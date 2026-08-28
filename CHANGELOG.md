# Changelog

Notable user-visible changes are recorded here. Versions follow semantic
versioning for release organization.

## Unreleased

### Added

- `nvim-config doctor`, `update`, and `sync` commands for health checks,
  fast-forward-only whole-config updates, and explicit dependency
  reconciliation without rerunning the installer.
- Asynchronous `:NvimConfigUpdate` and `:NvimConfigDoctor` commands with an
  in-editor maintenance report.
- A centralized Neovim, Node, Mason, LSP, and Treesitter compatibility
  manifest plus latest-tested dependency automation.
- MCP Buff on its production `bet` branch, restricted to the documented
  loopback endpoint.
- Optional Mise-aware Treesitter injections for config `run` scripts and Bash
  file-task MISE/USAGE directives, with managed Bash, TOML, and KDL parsers.
- A copy-only Toughbook clipboard bridge for SSH sessions. `NVIM_CLIPBOARD=auto`
  selects it when `~/.local/bin/toughbook-copy` is executable and keeps OSC 52
  as the portable fallback; `NVIM_CLIPBOARD=bridge` requests it explicitly.
- An optional `mise.toml` task façade over `bin/nvim-config` plus fleet tasks
  over a gitignored `dev/` directory. Mise declares no toolchain here and
  remains optional; every task has a direct equivalent.
- lazy.nvim dev mode for this account's own plugins. When `dev/` holds a
  checkout or symlink for a `777lotto` plugin it is loaded from there;
  `fallback = true` keeps every machine without `dev/` resolving from the
  committed `lazy-lock.json` pins, and dev matching is off during
  `nvim-config` maintenance runs so they never rewrite a dev plugin's pin.

### Changed

- GitPanel uses the repository-scoped `gh-app` API wrapper and locally signed
  Git merges when the workstation helper is installed, while other installs
  retain the standard `gh` API backend.
- Git workflows now use the dependency-free GitPanel exclusively; the
  Gitsigns, Diffview, Neogit, and Lazygit integrations and their keymaps were
  removed.
- GitPanel now resolves to the responsive repository dashboard promoted to its
  production `bet` branch.
- `bootstrap.sh` is installation-only; existing checkouts use the safer
  clean-worktree, configured-upstream updater.
- Node 22 is the supported floor, Node 24 is the recommended default, and Node
  26 is the forward-compatibility canary. CI exercises the latest releases of
  the managed Node-backed tools on all three lanes.
- The copy-only clipboard providers now serve `p` from the text they last sent
  instead of an empty register. Neither provider reads the client clipboard.
- The tested `git-panel.nvim` pin advances to its current `bet` head, which
  carries the locally signed Git merge backend this configuration already
  selects when the workstation `gh-app` helper is installed.
- `lazy-lock.json` is stored in lazy.nvim's own key order, so a plain
  `nvim-config sync` no longer leaves the worktree dirty with a `mcp-buff`
  reorder that changes no pin.

## 0.1.0 - 2026-08-15

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
- Standalone GitPanel licensing, community files, cross-version tests, and CI.
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
- The configuration consumes the published `777lotto/git-panel.nvim` plugin;
  its implementation, tests, and releases now live in the standalone repository.

[Unreleased]: https://github.com/777lotto/nvim-config/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/777lotto/nvim-config/releases/tag/v0.1.0
