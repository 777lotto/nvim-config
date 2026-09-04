# Changelog

Notable user-visible changes are recorded here. Versions follow semantic
versioning for release organization.

## Unreleased

### Added

- GitPanel connection profiles and diagnostics, including automatic selection
  of the credential-free Zemrip GitHub broker inside `zemrip-ai`.
- The single `nvim-update` command and asynchronous `:NvimUpdate` entry point;
  existing `nvim-config` commands remain compatible.
- Guarded UX Foundation, Styling, and Chrome integration with exact retained
  Bufferline, nvim-tree, and Telescope setup baselines. Saved UX profiles are
  not auto-applied and all Chrome surfaces remain externally owned during the
  compatibility soak.
- Cross-repository UX compatibility and performance gates covering the Neovim
  0.12.2 floor and tested 0.12.4 release, safe surface ownership, registration,
  exact rollback inputs, full startup, render hot paths, catalog refresh, and
  Styling workspace latency.
- Isolated maintenance runs now retain their requested config root through
  lazy.nvim spec reloads, preventing a different installed checkout from
  rewriting the lockfile with the wrong plugin inventory.
- `nvim-config doctor`, `update`, and `sync` commands for health checks,
  fast-forward-only whole-config updates, and explicit dependency
  reconciliation without rerunning the installer.
- Asynchronous `:NvimConfigUpdate` and `:NvimConfigDoctor` commands with an
  in-editor maintenance report.
- A centralized Neovim, Node, Mason, LSP, and Treesitter compatibility
  manifest plus latest-tested dependency automation.
- Stable-release notifications for every account-owned plugin. Dispatches name
  the exact tagged commit, and dependency refresh proves its `bluff` ancestry
  before changing only the publisher's lock entry.
- MCP Buff on the account default `bluff` branch with an exact tested pin and
  separately authenticated Cloudflare and GitHub tabs restricted to their
  documented loopback endpoints.
- Agent Manager on `bluff` with lazy-loadable workspace, provider,
  prompt, steering, interrupt, health, and close commands. `<leader>am` opens
  its workspace; provider and prompt actions stay inside it.
- Optional Mise-aware Treesitter injections for config `run` scripts and Bash
  file-task MISE/USAGE directives, with managed Bash, TOML, and KDL parsers.
- A copy-only Toughbook clipboard bridge for SSH sessions. `NVIM_CLIPBOARD=auto`
  selects it when `~/.local/bin/toughbook-copy` is executable and keeps OSC 52
  as the portable fallback; `NVIM_CLIPBOARD=bridge` requests it explicitly.
- An optional `mise.toml` task façade over `bin/nvim-config` plus fleet tasks
  over a gitignored `dev/` directory. Mise declares no toolchain here and
  remains optional; every task has a direct equivalent.
- Presence-gated lazy.nvim dev mode for this account's own plugins. Editing
  sessions load matching `dev/` checkouts or symlinks when present and fall
  back to committed `bluff` pins otherwise. Dev matching is off during pin
  maintenance so a local checkout cannot erase its lock entry.
- Safe current-file rename on `<leader>fn` and focused buffer, search, Git,
  terminal, and window helpers.

### Changed

- Developer-fleet clone and sync now bootstrap Agent Manager's release broker
  and locked Python worker automatically. A verified commit stamp makes
  current `:DevPlugins` runs probe-only, while interrupted or stale builds are
  retried.
- which-key now owns the `d`, `g`, `s`, and `t` triggers used by Agent
  Manager's buffer-local menus, avoiding recursive `which-key.show()` mappings.
- The repository now uses `bluff` as its only long-lived and default branch.
  The persisted two-channel state, branch picker, promotion-only CI gate, and
  updater branch-switching paths were removed.
- Contributor and release guidance now records the actual ZemRip broker
  boundary: `agent/**` pushes, ticketed workflow changes, expected unsigned
  agent commits, and operator-owned tags, Releases, settings, and secrets.
- Every account-owned plugin spec and lock entry now targets `bluff`; the pins
  advance to current commits on that branch and include Agent Manager for
  reproducible public installs.
- Developer fleet sync now includes Agent Manager because nvim-config consumes
  its accepted M1 implementation.
- GitPanel uses the broker's prefixed Git remote and REST route in `zemrip-ai`,
  while workstation App and portable GitHub CLI/public REST behavior remain
  available as named profiles.

- `:McpBuff` and `<leader>ar` now give the Cloudflare and GitHub brokers their
  own loopback-only SSH forwards through the WireGuard `zemrip-server` alias
  and their own Toughbook pass-backed admin capabilities. Closing the review
  session revokes both; no per-launch tunnel command, shared bearer, or LAN
  fallback remains.
- GitPanel uses the repository-scoped `gh-app` API wrapper and locally signed
  Git merges when the workstation helper is installed, while other installs
  retain the standard `gh` API backend.
- Git workflows now use the dependency-free GitPanel exclusively; the
  Gitsigns, Diffview, Neogit, and Lazygit integrations and their keymaps were
  removed.
- GitPanel now resolves to the responsive repository dashboard on `bluff`.
- `bootstrap.sh` is installation-only; existing checkouts use the safer
  clean-worktree, configured-upstream updater.
- Node 22 is the supported floor, Node 24 is the recommended default, and Node
  26 is the forward-compatibility canary. CI exercises the latest releases of
  the managed Node-backed tools on all three lanes.
- The copy-only clipboard providers now serve `p` from the text they last sent
  instead of an empty register. Neither provider reads the client clipboard.
- The tested `git-panel.nvim` pin advances to its current `bluff` head, which
  carries the locally signed Git merge backend this configuration already
  selects when the workstation `gh-app` helper is installed.
- `lazy-lock.json` is stored in lazy.nvim's own key order, so a plain
  `nvim-config sync` no longer leaves the worktree dirty with a `mcp-buff`
  reorder that changes no pin.
- Leader shortcuts now use a case-aware alphabetical which-key taxonomy:
  lowercase `a b c d e f g n q s w`, followed by uppercase `S T W`. Bufferline
  actions use the `(b)uffer` group, Agent Manager opens on `<leader>am`, MCP
  Buff uses `<leader>ar`, sessions and terminals use uppercase groups, and
  undo/redo use `<leader>fu` / `<leader>fr`.

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
