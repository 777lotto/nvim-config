# Neovim configuration

A reproducible, keyboard-first Neovim IDE configuration for Debian Linux. The
current client/development machine runs XFCE on Debian; the deployment target is
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
- Git signs, Diffview, Neogit, Lazygit, and the dependency-free custom
  [GitPanel](local-plugins/git-panel.nvim/README.md).
- Automatic clipboard policy: native X11 integration on the local XFCE client
  and copy-only OSC 52 when Neovim is running over SSH.

## Supported environment

The active topology is:

```text
Debian XFCE client (Thunar + Xfce Terminal + xclip)
                         │
                         └── SSH ──> headless Debian server running Neovim
```

KDE, Konsole, and macOS are not current runtime targets. The repository retains
an older `MacOS` branch only as history while the branch layout is consolidated.

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
| Node 20+ and npm | Web LSPs, Prettier, markdownlint | Debian 13 packages or NodeSource |
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
`NVIM_CONFIG_BRANCH` is set explicitly. It is safe to rerun: it pulls an
existing checkout, restores plugins from `lazy-lock.json`, installs Mason
tools, and builds Treesitter parsers.

To install a particular branch:

```sh
NVIM_CONFIG_BRANCH=my-branch ~/.config/nvim/bootstrap.sh
```

For a manual install, clone to `~/.config/nvim`, open Neovim, run
`:Lazy restore`, `:MasonToolsInstall`, and `:checkhealth`.

## Repository layout

```text
.
├── init.lua                         # intentionally tiny startup entrypoint
├── lua/
│   ├── config/
│   │   ├── environment.lua          # environment detection and clipboard policy
│   │   ├── options.lua              # environment-independent editor options
│   │   ├── keymaps.lua              # global mappings and edit commands
│   │   ├── diagnostics.lua          # one diagnostic presentation policy
│   │   ├── autocmds.lua             # general editor automation
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
│       └── ...
├── local-plugins/
│   └── git-panel.nvim/              # reusable, independently publishable plugin
├── docs/
│   ├── architecture.md
│   ├── repository-strategy.md
│   └── troubleshooting.md
├── lazy-lock.json                   # exact plugin commits
├── bootstrap.sh
└── CHANGELOG.md
```

`init.lua` only establishes startup order. lazy.nvim automatically merges the
plugin specs returned by every file under `lua/plugins/`, so adding a feature
does not require editing a central plugin table.

See [Architecture and UI layers](docs/architecture.md) for how themes,
highlight groups, Treesitter, LSP, linting, diagnostics, and renderers interact.

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

## Git workflows

- `<leader>gg`: custom GitPanel tab.
- `<leader>gG`: custom GitPanel split.
- `<leader>gd`: working-tree Diffview.
- `<leader>gn`: Neogit power-user popups.
- `<leader>gl`: Lazygit.
- `<leader>gh` / `<leader>gf`: repository / current-file history.

GitPanel now lives in a normal plugin package with a lightweight
`plugin/git-panel.lua` command layer and its implementation under
`lua/git_panel/`. It can be split into a separate repository without asking
users to extract code from this config. In a local-only repository, `P` can
create and push a GitHub repository through the optional authenticated `gh`
CLI, or attach an existing remote URL for another Git host.

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

`lazy-lock.json` pins plugin commits and belongs in Git. Use `:Lazy restore`
to reproduce those versions. Use `:Lazy update` only when intentionally
upgrading, then test and commit the resulting lockfile.

Mason's `ensure_installed` lists guarantee which tools are present but do not
pin their versions.

## Environment policy

`lua/config/environment.lua` keeps machine-dependent behavior in one place.
The default `NVIM_CLIPBOARD=auto` policy selects Neovim's native provider on a
local desktop and copy-only OSC 52 when `SSH_TTY` or `SSH_CONNECTION` indicates
an SSH session. Set `NVIM_CLIPBOARD=native` or `NVIM_CLIPBOARD=osc52` to override
that decision for a particular launch. Run `:EnvironmentInfo` to see the
desktop, terminal, SSH agent socket, and clipboard policy Neovim inherited.

Automatic detection is intentionally limited to behavior Neovim controls.
Thunar launchers and graphical-session variables such as `SSH_AUTH_SOCK` must be
configured in XFCE before Neovim starts. See [Troubleshooting](docs/troubleshooting.md)
for the launcher and Java Card checks.

The recommended migration from the current `debian` / historical `MacOS`
branches to one `main` branch is documented in
[Repository strategy](docs/repository-strategy.md).

## Discoverability

Press `<leader>?` for all mappings or `<leader>sk` to search them. Useful
starting points are `<leader>ff` (files), `<leader>fg` (grep), `<leader>fe`
(file explorer), `<C-\>` (terminal), `<leader>sr` (project replace), and
`<leader>u` (undo tree).

Common terminal, LSP, and clipboard checks are collected in
[Troubleshooting](docs/troubleshooting.md).

## Contributing and releases

Development and release recommendations—including branch consolidation, tags,
GitHub Releases, CI, rulesets, and extracting GitPanel—live in
[Repository strategy](docs/repository-strategy.md). User-visible changes are
tracked in [CHANGELOG.md](CHANGELOG.md).

A license has not yet been selected. Choose one before advertising either this
configuration or GitPanel for public reuse.
