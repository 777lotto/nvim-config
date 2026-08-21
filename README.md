# Neovim configuration

[![CI](https://github.com/777lotto/nvim-config/actions/workflows/ci.yml/badge.svg?branch=bet)](https://github.com/777lotto/nvim-config/actions/workflows/ci.yml)
[![Neovim](https://img.shields.io/badge/Neovim-0.12%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![Release](https://img.shields.io/github/v/release/777lotto/nvim-config)](https://github.com/777lotto/nvim-config/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A reproducible, keyboard-first Neovim IDE configuration for Debian Linux. The
current client/development machine runs XFCE on Debian; the remote runtime is
a headless Debian server accessed over SSH. The config uses Neovim's current Lua
APIs, lazy.nvim for plugins, Mason for external tools, and a committed lockfile
for repeatable installs.

Requires Neovim 0.12 or newer. The leader key is `<Space>`.

## Highlights

- LSP completion, navigation, refactoring, hover help, and diagnostics.
- Treesitter highlighting, indentation, text objects, and structural movement.
- Telescope search, nvim-tree and Oil navigation, bufferline, lualine, and
  which-key discovery.
- Diagnostics shown as signs, underlines, virtual text, current-line virtual
  lines, floating detail, native location/quickfix lists, and Trouble panels.
- Project-aware Prettier formatting through conform.nvim.
- Markdown rendering, Marksman, Prettier, and markdownlint-cli2.
- A dependency-free custom
  [GitPanel](https://github.com/777lotto/git-panel.nvim) for Git workflows.
- [MCP Buff](https://github.com/777lotto/mcp-buff) for reviewing brokered
  Cloudflare write tickets through an operator-controlled loopback tunnel.
- A clean-worktree, fast-forward-only whole-config updater available from the
  shell and inside Neovim.
- Automatic clipboard policy: native X11 integration on the local XFCE client
  and copy-only OSC 52 when Neovim is running over SSH.

## Supported environment

| Platform | Status | CI |
| --- | --- | --- |
| Debian 13 desktop / XFCE | Supported | Core policy smoke test |
| Debian 13 headless / SSH | Supported | OSC 52 / SSH policy smoke test |
| macOS | Historical / experimental | Not currently blocking releases |

The active topology is:

```text
Debian XFCE client (Thunar + Xfce Terminal + xclip)
                         │
                         └── SSH ──> headless Debian server running Neovim
```

KDE, Konsole, and macOS are not current runtime targets. The former macOS state
is preserved by the signed `archive/macos-before-unification` tag while portable
behavior continues to live in the same production codebase.

Neovim's terminal and file explorers remain desktop-independent: ToggleTerm
uses Neovim's configured shell, while nvim-tree and Oil run inside Neovim. The
desktop launcher used by Thunar is a separate XFCE concern because it creates
the process before this configuration loads.

## Language coverage

| Language | Structure / highlighting | LSP | Formatter / linter |
| --- | --- | --- | --- |
| Lua | Treesitter | `lua_ls` | — |
| JavaScript, JSX | Treesitter | `ts_ls` | Prettier |
| TypeScript, TSX | Treesitter | `ts_ls` | Prettier |
| HTML | Treesitter | `html` | Prettier |
| CSS | Treesitter | `cssls` | Prettier |
| JSON, JSONC | Treesitter | `jsonls` + SchemaStore | Prettier |
| Python | Treesitter | `pyright` | — |
| Markdown, MDX | Treesitter + render-markdown | `marksman` | Prettier + markdownlint-cli2 |
| XML | Treesitter | — | — |

Prettier is also configured for JSON5, SCSS, Less, Vue, GraphQL, Handlebars,
Angular HTML, and YAML. It is deliberately not assigned to Lua, Python, C, XML,
or plain text because Prettier does not parse those languages. Those can receive
their own formatters later (for example StyLua or Ruff) without changing the
Prettier policy.

## Requirements

| Need | Purpose | Debian setup |
| --- | --- | --- |
| Neovim 0.12+ | Editor and current Treesitter APIs | Current upstream build |
| Git and curl | Config, lazy.nvim, Mason | `apt install git curl ca-certificates` |
| GitHub CLI (optional) | Create and publish a remote from GitPanel | `apt install gh`, then `gh auth login` |
| C compiler | Treesitter parser builds | `apt install build-essential` |
| Node 22+ and npm | Web LSPs, Prettier, markdownlint | Node 24 LTS recommended; 22 is the CI floor |
| ripgrep | Telescope live grep | `apt install ripgrep` |
| Python 3 | Python tooling/providers | `apt install python3` |
| unzip and tar | Mason packages | `apt install unzip tar` |
| Xfce Terminal and xclip | Client terminal and local X11 clipboard | `apt install xfce4-terminal xclip` on the XFCE client |
| Nerd Font | File/type icons | Configure Xfce Terminal on the client |

Mason installs the required tree-sitter CLI, LSP servers, Prettier, and
markdownlint-cli2. A C compiler is still needed to build parsers.

## Install

On a fresh Debian machine:

```sh
git clone https://github.com/777lotto/nvim-config.git \
  "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
"${XDG_CONFIG_HOME:-$HOME/.config}/nvim/bootstrap.sh"
```

The installer follows the repository's GitHub default branch unless
`NVIM_CONFIG_BRANCH` is set explicitly. It is safe to rerun, but intentionally
does not pull an existing checkout. Bootstrap provisions the checkout already
on disk, restores plugins from `lazy-lock.json`, installs Mason tools, builds
Treesitter parsers, and links `nvim-config` into `~/.local/bin` when that path is
free.

The account-wide branch convention is `bet` for production and `bluff` for
integration. Fresh clones therefore receive `bet`; to test the current staging
state explicitly:

```sh
NVIM_CONFIG_BRANCH=bluff ~/.config/nvim/bootstrap.sh
```

For a manual install, clone to `~/.config/nvim`, then run
`~/.config/nvim/bin/nvim-config sync` and `:checkhealth`.

## Updating and health checks

Use the maintenance command after the initial install:

```sh
nvim-config doctor
nvim-config update
```

`update` refuses a dirty worktree or detached HEAD, reads the current branch's
configured upstream, fetches that existing remote, and permits only a
fast-forward. It never rewrites a remote URL, SSH host, tunnel, branch, or
network setting. After a successful pull, it restores/cleans lazy.nvim plugins
only when plugin inputs changed, refreshes Mason packages only when the managed
tool inventory changed, and updates Treesitter parsers only when parser inputs
changed. Restart Neovim after it completes.

Inside Neovim, `:NvimConfigUpdate` runs the same command asynchronously and
opens its report without blocking the editor. `:NvimConfigDoctor` checks Git,
Neovim, Node/npm, supporting executables, upstream state, and worktree
cleanliness. `nvim-config sync --latest` is the explicit manual path for
refreshing unpinned Mason tools and parsers without changing plugin lock policy.

## Repository layout

```text
.
├── .github/                         # CI, issue forms, and PR guidance
├── init.lua                         # intentionally tiny startup entrypoint
├── lua/
│   ├── config/
│   │   ├── environment.lua          # environment detection and clipboard policy
│   │   ├── options.lua              # environment-independent editor options
│   │   ├── keymaps.lua              # global mappings and edit commands
│   │   ├── diagnostics.lua          # one diagnostic presentation policy
│   │   ├── autocmds.lua             # general editor automation
│   │   ├── toolchain.lua             # compatibility and managed-tool manifest
│   │   ├── update.lua                # asynchronous editor maintenance commands
│   │   └── lazy.lua                 # lazy.nvim bootstrap and plugin import
│   └── plugins/                     # lazy.nvim specs grouped by concern
│       ├── ui.lua
│       ├── navigation.lua
│       ├── treesitter.lua
│       ├── lsp.lua
│       ├── diagnostics.lua
│       ├── languages.lua
│       ├── editing.lua
│       ├── git.lua
│       ├── operations.lua            # MCP Buff operator panel
│       └── ...
├── docs/
│   ├── architecture.md
│   ├── maintenance.md
│   ├── repository-strategy.md
│   └── troubleshooting.md
├── scripts/ci/                      # dependency-light validation scripts
├── bin/nvim-config                  # doctor, update, and dependency sync CLI
├── lazy-lock.json                   # exact plugin commits
├── bootstrap.sh
└── CHANGELOG.md
```

`init.lua` only establishes startup order. lazy.nvim automatically merges the
plugin specs returned by every file under `lua/plugins/`, so adding a feature
does not require editing a central plugin table.

See [Architecture and UI layers](docs/architecture.md) for how themes,
highlight groups, Treesitter, LSP, linting, diagnostics, and renderers interact.
See [Configuration maintenance](docs/maintenance.md) for updater safety,
latest-tested dependency policy, CI lanes, and release dispatches.

## Diagnostics

Diagnostics are available through several complementary views:

| View | Use |
| --- | --- |
| Sign column + underline | Persistent severity/location cue |
| Virtual text | Compact message beside each affected line |
| Current-line virtual lines | Full message below the line being inspected |
| `<leader>xf` | Rounded floating details at the cursor |
| `<leader>xl` | Current-buffer location list |
| `<leader>xq` | Project quickfix list |
| `<leader>xb` | Current-buffer Trouble panel |
| `<leader>xx` | Project Trouble panel |

## Formatting

conform.nvim runs Prettier on save only for filetypes mapped to Prettier.
`<leader>cf` formats the current buffer or visual selection manually. A
project-local `node_modules/.bin/prettier` takes precedence over Mason's
fallback, so repositories can control their own Prettier version and config.

Formatting and linting are separate: a formatter rewrites layout; a linter
reports questionable or invalid code as diagnostics.

## Sessions and quitting

The `persistence.nvim` session commands remember the working directory, open
buffers, windows, and tab layout. They do not save unsaved file contents and do
not affect Git.

| Key | Action |
| --- | --- |
| `<leader>qq` | Quit the current window |
| `<leader>qa` | Quit all Neovim windows |
| `<leader>qs` | Restore the saved session for the current directory |
| `<leader>ql` | Restore the most recently used session |
| `<leader>qd` | Stop persistence from saving this particular session |

The session mappings remain because they solve a different problem from
quitting and are safely grouped under the same discoverable `q` prefix.

## Terminals

| Key / command | Action |
| --- | --- |
| `<leader>tt` | Open a new, independent terminal buffer (every use creates another) |
| `<C-\>` | Show or hide one persistent floating terminal |
| `:FloatTerminal` | Show or hide that same persistent floating terminal |

The floating terminal is a ToggleTerm buffer displayed in a Neovim floating
window. Toggling the window closed only hides it: its shell and any commands
running inside it continue until the shell exits or Neovim ends. Ordinary
`<leader>tt` terminals are separate listed buffers, so they appear in the
bufferline bar and can run concurrently with each other and with the float.

## Git workflows

- `<leader>gg`: custom GitPanel tab.
- `<leader>gG`: custom GitPanel split.

[git-panel.nvim](https://github.com/777lotto/git-panel.nvim) is developed and
released independently, while `lazy-lock.json` pins the exact tested commit for
this configuration. In a local-only repository, `P` can create and push a
GitHub repository through the optional authenticated `gh` CLI, or attach an
existing remote URL for another Git host.

## Brokered write review

- `<leader>mb`: open MCP Buff's Cloudflare write-ticket review panel.

The plugin endpoint is fixed to `http://127.0.0.1:8792`. This repository does
not create, modify, or persist an SSH tunnel; tunnel lifecycle and routing stay
under the workstation network runbook. Closing the external tunnel revokes
reachability without a Neovim configuration change.

## Project search and replace

`<leader>sw` opens Telescope Live Grep. Search remains regex-capable; press
`<C-r>` inside the picker to replace the current prompt as exact,
case-sensitive text across the project. Replacement text is entered in a
centered floating prompt, followed by a second confirmation showing the match
and file counts. The action refuses to run while a matching buffer has unsaved
changes.

## Themes and rendered files

Catppuccin currently provides the colorscheme. lualine uses `theme = "auto"`,
so it follows colorscheme changes made at runtime. render-markdown.nvim owns
Markdown-specific decorations but expresses them through highlight groups and
normally follows the active colorscheme; changing the theme does not require
rewriting the renderer.

Neovim applies `:highlight` and `nvim_set_hl()` changes immediately, so a
live theme workshop with sample buffers is feasible. The architecture document
describes how that plugin should be separated from the colorscheme itself.

## Reproducibility

`lazy-lock.json` pins exact plugin commits and belongs in Git. Public installs
therefore reproduce the latest version that passed this repository's tests,
not an unreviewed moving target. A scheduled workflow runs `:Lazy update`,
validates the result, and opens a focused PR into `bluff`; GitPanel and MCP Buff
release dispatches can target only their own lock entry.

Mason package names deliberately omit a version, which already means the
latest registry release—there is no useful `--latest` suffix to add. The
central inventory lives in `lua/config/toolchain.lua`; `MasonToolsUpdateSync`
updates installed entries. CI exercises current Node-backed tools on Node 22
(floor), Node 24 (recommended), and Node 26 (canary). Node 20 is no longer a
supported runtime. The standard `.nvmrc` selects the recommended Node major
while still allowing its newest compatible patch release.

## Environment policy

`lua/config/environment.lua` keeps machine-dependent behavior in one place.
The default `NVIM_CLIPBOARD=auto` policy selects Neovim's native provider on a
local desktop and copy-only OSC 52 when `SSH_TTY` or `SSH_CONNECTION` indicates
an SSH session. Set `NVIM_CLIPBOARD=native` or `NVIM_CLIPBOARD=osc52` to override
that decision for a particular launch. Run `:EnvironmentInfo` to see the
desktop, terminal, SSH agent socket, and clipboard policy Neovim inherited.

Automatic detection is intentionally limited to behavior Neovim controls.
When `gpgconf` is available, Neovim routes child Git and SSH processes through
the GPG agent's Java Card socket. A session-wide `SSH_AUTH_SOCK` setting is still
recommended so other XFCE applications inherit the same agent. See
[Troubleshooting](docs/troubleshooting.md) for the launcher and Java Card checks.

Production, integration, release, and platform policy are documented in
[Repository strategy](docs/repository-strategy.md).

## Discoverability

Press `<leader>?` for all mappings or `<leader>sk` to search them. Useful
starting points are `<leader>ff` (files), `<leader>sw` (project grep), `<leader>fe`
(file explorer), `<leader>tt` (new terminal buffer), `<C-\>` (persistent
floating terminal), and `<leader>u` (undo tree).

Common terminal, LSP, and clipboard checks are collected in
[Troubleshooting](docs/troubleshooting.md).

## Contributing and releases

Development and release recommendations—including branches, signed tags,
GitHub Releases, CI, rulesets, and the published GitPanel integration—live in
[Repository strategy](docs/repository-strategy.md). User-visible changes are
tracked in [CHANGELOG.md](CHANGELOG.md).

Contributions are welcome under the workflow in [CONTRIBUTING.md](CONTRIBUTING.md).
Actionable work is tracked in [Issues](https://github.com/777lotto/nvim-config/issues)
and the public [Neovim Workspace](https://github.com/users/777lotto/projects/5).
Questions, setup showcases, and exploratory ideas belong in
[Discussions](https://github.com/777lotto/nvim-config/discussions).
The configuration is available under the [MIT License](LICENSE).
