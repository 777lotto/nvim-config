# Neovim config

A single-file (`init.lua`) IDE setup for **JavaScript/TypeScript, HTML/CSS, Python, Markdown, and Lua**.
Requires **Neovim ≥ 0.11.4** (LuaJIT). Managed with [lazy.nvim](https://github.com/folke/lazy.nvim); tools/LSPs via [Mason](https://github.com/mason-org/mason.nvim). Leader is `<Space>`.

## Features

Catppuccin theme · Telescope (find/grep) · nvim-tree (float) · bufferline · lualine ·
nvim-cmp + LuaSnip · LSP via Mason (`lua_ls`, `pyright`, `ts_ls`, `html`, `cssls`, `marksman`) ·
conform.nvim (prettier) + nvim-lint (markdownlint-cli2) · Treesitter · gitsigns / neogit /
diffview / lazygit · a dependency-free custom **GitPanel** (`<leader>gg`) · toggleterm (`<C-\>`) ·
trouble · which-key · spectre.

## Requirements

| Need | Why | macOS | Debian |
|------|-----|-------|--------|
| Neovim ≥ 0.11.4 | the config itself | `brew install neovim` | **apt build is too old** — use the [release tarball/AppImage](https://github.com/neovim/neovim/releases) or the `neovim-ppa/unstable` PPA |
| git, curl | lazy.nvim / Mason | preinstalled / brew | `apt install git curl ca-certificates` |
| C compiler + make | Treesitter parsers | Xcode CLT | `apt install build-essential` |
| ripgrep | Telescope live-grep | `brew install ripgrep` | `apt install ripgrep` |
| fd *(optional)* | Telescope file finder (falls back to `rg`/`find`) | `brew install fd` | `apt install fd-find` → binary is **`fdfind`** |
| node + npm | `pyright`, `ts_ls`, `html`, `cssls`, prettier, markdownlint-cli2 | `brew install node` | see Node note ↓ |
| python3 | pyright runtime / providers | preinstalled | `apt install python3` |
| unzip | Mason unpacks some servers | preinstalled | `apt install unzip` |
| A Nerd Font | icons (devicons/lualine/bufferline) | in your terminal | in your **local** terminal (see clipboard note) |

**Debian one-liner (current stable, *trixie* / Debian 13):**

```sh
sudo apt update && sudo apt install -y \
  git curl ca-certificates build-essential ripgrep fd-find \
  nodejs npm python3 unzip xclip wl-clipboard fontconfig
```

### Node version note
`ts_ls` (typescript-language-server 5.x) requires **Node ≥ 20**.
- **Debian 13 (trixie, current stable):** apt Node is 20.x — fine. `lazygit` is also `apt install`-able.
- **Debian 12 (bookworm):** apt Node is 18 → install Node 20 from [NodeSource](https://github.com/nodesource/distributions), and install `lazygit` from its [GitHub release](https://github.com/jesseduffield/lazygit/releases) (not in bookworm apt).

`lua_ls` and `marksman` are standalone binaries and need **no** Node.

## Quick start (fresh machine)

```sh
NVIM_CONFIG_REPO=<your-repo-url> bash bootstrap.sh
```

`bootstrap.sh` is idempotent. It verifies Neovim ≥ 0.11, clones/updates the repo into
`~/.config/nvim` (backing up any pre-existing non-repo config), then runs headlessly:
`Lazy! restore` (plugins at pinned commits) → `TSUpdateSync` (build parsers) →
`MasonToolsInstallSync` (prettier, markdownlint-cli2) → `MasonInstall` (LSP servers).

**Manual install:** clone the repo to `~/.config/nvim`, launch `nvim` (lazy.nvim
self-bootstraps), then `:Lazy restore`, `:TSUpdateSync`, `:MasonToolsInstall`, `:checkhealth`.

## Reproducibility

`lazy-lock.json` pins **every plugin to an exact commit** and **is committed**. Reproduce a
machine with `:Lazy restore` (**not** `:Lazy sync` — sync updates plugins *and* rewrites the
lockfile, silently drifting your "reproducible" install).

**Update workflow:** `:Lazy update` → commit the regenerated `lazy-lock.json` → push. Other
machines `git pull` then `:Lazy restore` to land on identical versions. Roll back a bad update
by restoring an older `lazy-lock.json` and running `:Lazy restore`.

> Caveat: Mason pins *which* tools install (`ensure_installed`) but not their versions — Mason
> always fetches the latest server/formatter release.

## Clipboard / SSH

When `$SSH_TTY` is set, yanks route to the **local** terminal via OSC 52 (Konsole-friendly);
paste stays on the terminal's own paste (e.g. `Ctrl+Shift+V`). On a **local Linux GUI** the
config uses the system clipboard, which needs a provider: **`xclip`/`xsel` (X11)** or
**`wl-clipboard` (Wayland)** — both are in the apt line above.

## Keymaps

Leader = `<Space>`; press `<leader>?` for the full which-key list. Highlights: `<leader>ff`/`<leader>fg`
files/grep · `<leader>e` file tree · `<C-\>` floating terminal · `<leader>gg` custom Git panel ·
`<leader>gl` lazygit · `<leader>gn` neogit · `<leader>xx` diagnostics (trouble) · `<leader>cf`
format · `<leader>sr` search/replace (spectre) · `<leader>t…` bufferline (tab bar).

## Platform notes

Tested on macOS and Debian Linux (not Windows). On Debian, watch the Neovim version (apt is too
old) and install a Nerd Font in your local terminal.

## Repo layout

`init.lua` (the whole config) · `lazy-lock.json` (pinned plugins, committed) · `.gitignore` ·
`bootstrap.sh` · `README.md`.
