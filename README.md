# Neovim configuration

[![CI](https://github.com/777lotto/nvim-config/actions/workflows/ci.yml/badge.svg?branch=bluff)](https://github.com/777lotto/nvim-config/actions/workflows/ci.yml)
[![Neovim](https://img.shields.io/badge/Neovim-0.12.2%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![Release](https://img.shields.io/github/v/release/777lotto/nvim-config)](https://github.com/777lotto/nvim-config/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A reproducible, keyboard-first Neovim IDE configuration for Debian Linux. The
current client/development machine runs XFCE on Debian; the remote runtime is
a headless Debian server accessed over SSH. The config uses Neovim's current Lua
APIs, lazy.nvim for plugins, Mason for external tools, and a committed lockfile
for repeatable installs.

Requires Neovim 0.12.2 or newer. The leader key is `<Space>`.

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
- [Agent Manager](https://github.com/777lotto/agent-manager.nvimz) for native,
  keyboard-first Codex and Claude sessions inside Neovim.
- [MCP Buff](https://github.com/777lotto/mcp-buff) for reviewing brokered
  Cloudflare write tickets through an operator-controlled loopback tunnel.
- Guarded UX Foundation, Styling, and Chrome integration. Chrome registers its
  complete contract while Bufferline, Lualine, and native surfaces remain the
  physical owners during the compatibility soak.
- A clean-worktree, fast-forward-only whole-config updater available from the
  shell and inside Neovim.
- Automatic clipboard policy: native X11 integration on the local XFCE client
  and copy-only OSC 52 when Neovim is running over SSH.

## Supported environment

| Platform                 | Status                    | CI                              |
| ------------------------ | ------------------------- | ------------------------------- |
| Debian 13 desktop / XFCE | Supported                 | Core policy smoke test          |
| Debian 13 headless / SSH | Supported                 | OSC 52 / SSH policy smoke test  |
| macOS                    | Historical / experimental | Not currently blocking releases |

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

| Language        | Structure / highlighting                         | LSP                    | Formatter / linter           |
| --------------- | ------------------------------------------------ | ---------------------- | ---------------------------- |
| Lua             | Treesitter                                       | `lua_ls`               | —                            |
| JavaScript, JSX | Treesitter                                       | `ts_ls`                | Prettier                     |
| TypeScript, TSX | Treesitter                                       | `ts_ls`                | Prettier                     |
| HTML            | Treesitter                                       | `html`                 | Prettier                     |
| CSS             | Treesitter                                       | `cssls`                | Prettier                     |
| JSON, JSONC     | Treesitter                                       | `jsonls` + SchemaStore | Prettier                     |
| Python          | Treesitter                                       | `pyright`              | —                            |
| Markdown, MDX   | Treesitter + render-markdown                     | `marksman`             | Prettier + markdownlint-cli2 |
| XML             | Treesitter                                       | —                      | —                            |
| Bash / shell    | Treesitter + Mise file-task injections           | —                      | —                            |
| TOML            | Treesitter + Mise `run` injections               | —                      | —                            |
| KDL             | Treesitter (including embedded Mise usage specs) | —                      | —                            |

Prettier is also configured for JSON5, SCSS, Less, Vue, GraphQL, Handlebars,
Angular HTML, and YAML. It is deliberately not assigned to Lua, Python, C, XML,
or plain text because Prettier does not parse those languages. Those can receive
their own formatters later (for example StyLua or Ruff) without changing the
Prettier policy.

### Optional Mise highlighting

Mise configuration receives syntax-aware embedded highlighting without making
Mise an editor dependency. Single-line `run` strings and multiline strings
without a shebang use Bash; multiline `env` and direct-interpreter shebangs use
the named language. The predicate recognizes Mise's default project, local,
environment, grouped `config.toml`, and non-hidden `conf.d/*.toml` paths. A
generic TOML file with a `run` key is intentionally left as TOML.

Bash file tasks highlight `#MISE`, `#[MISE]`, and `# [MISE]` bodies as TOML,
and the corresponding `USAGE` forms as KDL. Consecutive USAGE directives are
parsed as one multi-node KDL region on Neovim 0.12. Mise itself remains an
optional external command: startup, bootstrap, and `nvim-config doctor` do not
invoke or require it. The managed Bash, TOML, and KDL parsers are installed by
bootstrap or `nvim-config sync` and updated by `nvim-config sync --latest`.

## Requirements

| Need                    | Purpose                                          | Debian setup                                          |
| ----------------------- | ------------------------------------------------ | ----------------------------------------------------- |
| Neovim 0.12.2+          | Editor, UX contract, and current Treesitter APIs | Current upstream build                                |
| Git and curl            | Config, lazy.nvim, Mason                         | `apt install git curl ca-certificates`                |
| GitHub CLI (optional)   | Create and publish a remote from GitPanel        | `apt install gh`, then `gh auth login`                |
| C compiler              | Treesitter parser builds                         | `apt install build-essential`                         |
| Node 22+ and npm        | Web LSPs, Prettier, markdownlint                 | Node 24 LTS recommended; 22 is the CI floor           |
| ripgrep                 | Telescope live grep                              | `apt install ripgrep`                                 |
| Python 3                | Python tooling/providers                         | `apt install python3`                                 |
| unzip and tar           | Mason packages                                   | `apt install unzip tar`                               |
| Xfce Terminal and xclip | Client terminal and local X11 clipboard          | `apt install xfce4-terminal xclip` on the XFCE client |
| Nerd Font               | File/type icons                                  | Configure Xfce Terminal on the client                 |

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
does not pull or switch an existing checkout. Bootstrap provisions the checkout
already on disk, restores plugins from `lazy-lock.json`, installs Mason tools,
builds Treesitter parsers, and links `nvim-update` and `nvim-config` into
`~/.local/bin` when those paths are free.

The account-wide default branch is `bluff`. Fresh clones receive it directly,
and every account-owned plugin spec explicitly targets `bluff` as well.
`NVIM_CONFIG_BRANCH` remains available only for deliberately cloning a
different config branch on a fresh install; it does not change plugin branches
or persist separate channel state.

For a manual install, clone to `~/.config/nvim`, then run
`~/.config/nvim/bin/nvim-config sync` and `:checkhealth`.

## Updating and health checks

Routine maintenance is one command:

```sh
nvim-update
```

`nvim-update` refuses dirty, detached, or divergent checkouts, fetches the
configured upstream of the current config branch, and permits only a
fast-forward. When an opt-in `dev/` fleet exists, it also requires every
account-owned plugin checkout to be clean and on `bluff`, fast-forwards the
fleet, and compile-checks its Lua sources. An ordinary install continues to
use only exact lockfile pins. The updater never switches branches or rewrites a
remote URL, SSH host, tunnel, or network setting.
After a successful pull, it reconciles only the dependency classes affected by
changed files. Restart Neovim after it completes.

Inside Neovim, `:NvimUpdate` runs the same command asynchronously and opens its
report without blocking the editor; `:NvimConfigUpdate` remains an alias.
Restart Neovim after a successful update.
`nvim-config doctor` and `:NvimConfigDoctor` check Git, Neovim, Node/npm,
supporting executables, upstream state, and worktree
cleanliness. `nvim-config sync --latest` is the explicit manual path for
refreshing unpinned Mason tools and parsers without changing plugin lock policy.

## Repository layout

```text
.
├── .github/                         # CI, issue forms, and PR guidance
├── after/queries/                   # query extensions for embedded languages
├── init.lua                         # intentionally tiny startup entrypoint
├── lua/
│   ├── config/
│   │   ├── environment.lua          # environment detection and clipboard policy
│   │   ├── mise.lua                 # Mise path predicate; no CLI dependency
│   │   ├── options.lua              # environment-independent editor options
│   │   ├── keymaps.lua              # global mappings and edit commands
│   │   ├── diagnostics.lua          # one diagnostic presentation policy
│   │   ├── autocmds.lua             # general editor automation
│   │   ├── toolchain.lua             # compatibility and managed-tool manifest
│   │   ├── update.lua               # asynchronous editor maintenance commands
│   │   ├── ux_baselines.lua         # exact third-party setup rollback inputs
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
│       ├── operations.lua            # Agent Manager and MCP Buff
│       ├── ux.lua                    # guarded Foundation/Styling/Chrome integration
│       └── ...
├── docs/
│   ├── architecture.md
│   ├── maintenance.md
│   ├── repository-strategy.md
│   └── troubleshooting.md
├── scripts/ci/                      # dependency-light validation scripts
├── bin/nvim-config                  # doctor, update, and dependency sync CLI
├── bin/nvim-update                  # single routine guarded update command
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

## Leader shortcut organization

Pressing `<leader>` (`Space`) opens an alphabetized which-key menu. Lowercase
categories appear first, followed by uppercase categories; case deliberately
distinguishes `w` (word) from `W` (window), `s` (search) from `S` (session),
and `t` is left unused while `T` owns terminals.

| Prefix       | which-key label | Scope                                                  |
| ------------ | --------------- | ------------------------------------------------------ |
| `<leader>a`  | `(a)gent`       | Agent sessions and brokered review                     |
| `<leader>am` | `(m)anager`     | Agent Manager workspace, startup, and prompts          |
| `<leader>b`  | `(b)uffer`      | Buffer bar creation, selection, movement, and deletion |
| `<leader>c`  | `(c)ode`        | Code actions, formatting, and rendered Markdown        |
| `<leader>d`  | `(d)iagnostic`  | Diagnostic and TODO views                              |
| `<leader>e`  | `(e)dit`        | Selection, indentation, lines, comments, and lists     |
| `<leader>f`  | `(f)ile`        | Files, save, rename, undo, and redo                    |
| `<leader>g`  | `(g)it`         | GitPanel plus branch, commit, and status pickers       |
| `<leader>n`  | `(n)avigate`    | Lines, paragraphs, brackets, and jump history          |
| `<leader>q`  | `(q)uit`        | Quit the current window or all windows                 |
| `<leader>s`  | `(s)earch`      | Buffer, help, keymap, TODO, and workspace search       |
| `<leader>w`  | `(w)ord`        | Word occurrences, selection, case, and symbol rename   |
| `<leader>S`  | `(S)ession`     | Restore or suppress persistence sessions               |
| `<leader>T`  | `(T)erminal`    | New, split, and persistent floating terminals          |
| `<leader>W`  | `(W)indow`      | Split, focus, close, equalize, and maximize windows    |

Keep current and future Agent Manager actions under `<leader>am`; `<leader>ar`
is reserved for the brokered MCP Buff review panel.

The most frequently used file and agent mappings are:

| Key           | Action                                                                        |
| ------------- | ----------------------------------------------------------------------------- |
| `<leader>amm` | Open Agent Manager                                                            |
| `<leader>amc` | Start a Codex agent                                                           |
| `<leader>ams` | Send a prompt through Agent Manager                                           |
| `<leader>ar`  | Open MCP Buff                                                                 |
| `<leader>fe`  | Toggle the file explorer                                                      |
| `<leader>ff`  | Find files                                                                    |
| `<leader>fh`  | Open undo history                                                             |
| `<leader>fn`  | Rename the current file after checking for unsaved changes and name conflicts |
| `<leader>fo`  | Open a recent file                                                            |
| `<leader>fr`  | Redo                                                                          |
| `<leader>fs`  | Save the current file                                                         |
| `<leader>fu`  | Undo                                                                          |
| `<leader>fS`  | Save all files                                                                |

The bufferline across the top is a buffer bar, not native Neovim tabs.
All of its leader mappings therefore live under `b`:

| Key                           | Action                                       |
| ----------------------------- | -------------------------------------------- |
| `<leader>ba`                  | Switch to the alternate buffer               |
| `<leader>bb`                  | Browse buffers with Telescope                |
| `<leader>bc`                  | Create a buffer                              |
| `<leader>bd`                  | Delete the current buffer                    |
| `<leader>bf` / `<leader>bl`   | Go to the first / last buffer                |
| `<leader>bn` / `<leader>bp`   | Go to the next / previous buffer             |
| `<leader>bo`                  | Delete other buffers                         |
| `<leader>bs`                  | Select a buffer by its displayed letter      |
| `<leader>bmf` / `<leader>bml` | Move the buffer to the first / last position |
| `<leader>bmn` / `<leader>bmp` | Move the buffer right / left                 |

## Diagnostics

Diagnostics are available through several complementary views:

| View                       | Use                                         |
| -------------------------- | ------------------------------------------- |
| Sign column + underline    | Persistent severity/location cue            |
| Virtual text               | Compact message beside each affected line   |
| Current-line virtual lines | Full message below the line being inspected |
| `<leader>db`               | Current-buffer Trouble panel                |
| `<leader>df`               | Rounded floating details at the cursor      |
| `<leader>dl`               | Current-buffer location list                |
| `<leader>dp`               | Project Trouble panel                       |
| `<leader>dq`               | Project quickfix list                       |
| `<leader>ds`               | Search diagnostics with Telescope           |
| `<leader>dt`               | TODO Trouble panel                          |

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

| Key          | Action                                               |
| ------------ | ---------------------------------------------------- |
| `<leader>qa` | Quit all Neovim windows                              |
| `<leader>qq` | Quit the current window                              |
| `<leader>Sd` | Stop persistence from saving this particular session |
| `<leader>Sl` | Restore the most recently used session               |
| `<leader>Sr` | Restore the saved session for the current directory  |

Sessions and quitting remain separate because they solve different problems:
lowercase `q` exits windows, while uppercase `S` manages persisted layouts.

## Terminals

| Key / command    | Action                                              |
| ---------------- | --------------------------------------------------- |
| `<leader>Tf`     | Show or hide the persistent floating terminal       |
| `<leader>Th`     | Open a new terminal in a horizontal split           |
| `<leader>Tn`     | Open a new, independent terminal buffer             |
| `<leader>Tv`     | Open a new terminal in a vertical split             |
| `<C-\>`          | Show or hide one persistent floating terminal       |
| `:FloatTerminal` | Show or hide that same persistent floating terminal |

The floating terminal is a ToggleTerm buffer displayed in a Neovim floating
window. Toggling the window closed only hides it: its shell and any commands
running inside it continue until the shell exits or Neovim ends. Ordinary
`<leader>Tn`, `<leader>Th`, and `<leader>Tv` terminals are separate listed
buffers, so they appear in the buffer bar and can run concurrently with each
other and with the float.

## Git workflows

- `<leader>gb`: Telescope Git branches.
- `<leader>gc`: Telescope Git commits.
- `<leader>gg`: custom GitPanel tab.
- `<leader>gs`: Telescope Git status.
- `<leader>gG`: custom GitPanel split.

[git-panel.nvim](https://github.com/777lotto/git-panel.nvim) is developed and
released independently, while `lazy-lock.json` pins the exact tested commit for
this configuration. In a local-only repository, `P` can create and push a
GitHub repository through the optional authenticated `gh` CLI, or attach an
existing remote URL for another Git host.

GitPanel exposes `:GitPanelConnection` and `:GitPanelDoctor` for selecting and
diagnosing preconfigured GitHub connections. Inside `zemrip-ai`, the installed
`gh-agent` command identifies the credential-free agent plane: GitPanel strips
the broker's `github/git` remote prefix and uses anonymous curl against
`http://10.77.0.1:8790/github/api`; the host broker injects a short-lived,
repository-scoped credential upstream. GitPanel never receives or stores it.

When `~/.local/bin/gh-app` is executable instead, GitPanel uses that
repository-scoped App wrapper for GitHub API data and comments, and uses the
public `signed_git` backend for pull-request merges through the existing signed
Git/SSH setup. Other installations retain standard GitHub CLI and public REST
profiles.

## Agent workspace

`<leader>amm` opens Agent Manager, `<leader>amc` starts its Codex provider,
and `<leader>ams` opens native prompt input for the selected agent. The same
actions are available as `:AgentManager`, `:AgentManagerStart codex`, and
`:AgentManagerSend`; steering, interrupt, health, and close commands are also
lazy-loadable. Starting the workspace or provider does not send a model turn,
while submitting a prompt can consume provider quota.

## Brokered write review

- `<leader>ar`: open MCP Buff's Cloudflare write-ticket review panel.

The plugin endpoint is fixed to `http://127.0.0.1:8792`. This repository does
not expose the broker or connect to the container. Opening `:McpBuff` creates a
loopback-only, panel-scoped SSH forward through the dedicated `zemrip-server`
alias, which resolves to the server's WireGuard address. It then reads
`zemrip/mcp/admin-capability` from the Toughbook's local `pass` store. Closing
the panel revokes the forward and clears the in-memory capability.

WireGuard is an always-on prerequisite managed outside Neovim. MCP Buff neither
changes it nor falls back to `zemrip-server-lan`. The approval UI therefore
runs on this Toughbook; agents in `zemrip-ai` post tickets, and the broker on
`zemrip-server` executes only a locally reviewed decision.

## Project search and replace

`<leader>sw` opens Telescope Live Grep. `<leader>sb` searches the current
buffer, `<leader>ss` searches the word under the cursor or selected text, and
`<leader>sr` resumes the previous Telescope picker. Project search remains
regex-capable; press `<C-r>` inside the picker to replace the current prompt
as exact, case-sensitive text across the project. Replacement text is entered
in a centered floating prompt, followed by a second confirmation showing the
match and file counts. The action refuses to run while a matching buffer has
unsaved changes.

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
local desktop. In an SSH session it uses the one-way Toughbook clipboard bridge
when `~/.local/bin/toughbook-copy` is installed, with copy-only OSC 52 as the
portable fallback. Set `NVIM_CLIPBOARD=native`, `NVIM_CLIPBOARD=bridge`, or
`NVIM_CLIPBOARD=osc52` to override that decision for a particular launch. Run
`:EnvironmentInfo` to see the desktop, terminal, SSH agent socket, and clipboard
policy Neovim inherited.

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
(file explorer), `<leader>bb` (buffers), `<leader>Tn` (new terminal buffer),
`<C-\>` (persistent floating terminal), and `<leader>fh` (undo history).

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
