#!/usr/bin/env bash
# bootstrap.sh — provision this Neovim config on a fresh Debian machine.
# Idempotent: safe to re-run. Clones/updates the repo into ~/.config/nvim, then
# installs plugins pinned by lazy-lock.json, builds Treesitter parsers, and
# installs the Mason tools & LSP servers — all headlessly and synchronously.
set -euo pipefail

# ---- configuration (override via env) ---------------------------------------
REPO_URL="${NVIM_CONFIG_REPO:-https://github.com/777lotto/nvim-config.git}"
# Empty means "use the repository's default branch". Set NVIM_CONFIG_BRANCH
# only when intentionally installing another branch.
BRANCH="${NVIM_CONFIG_BRANCH:-}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[1;31mXX\033[0m  %s\n' "$*" >&2; exit 1; }

clone_config() {
  if [ -n "$BRANCH" ]; then
    git clone --branch "$BRANCH" "$REPO_URL" "$CONFIG_DIR"
  else
    git clone "$REPO_URL" "$CONFIG_DIR"
  fi
}

# ---- 0. prerequisites -------------------------------------------------------
command -v git  >/dev/null || die "git is required."
command -v nvim >/dev/null || die "Neovim not found. Install >= 0.12.0 first. On Debian, build a tagged stable release from source or use another current upstream build."

# nvim-treesitter's main branch requires Neovim >= 0.12.0.
ver="$(nvim --version | sed -nE '1s/^NVIM v([0-9]+\.[0-9]+\.[0-9]+).*/\1/p')"
[ -n "$ver" ] || die "Could not parse the installed Neovim version."
IFS=. read -r major minor patch <<< "$ver"
if (( major == 0 && minor < 12 )); then
  die "Neovim $ver found; this config needs >= 0.12.0."
fi
log "Neovim $ver OK."

# Soft-check the tools plugins/Mason shell out to (warn, do not fail).
#   NOTE: ts_ls (typescript-language-server 5.x) needs Node >= 20. Debian
#   'bookworm' ships Node 18 -> use NodeSource or Debian 'trixie' (Node 20).
for t in rg node npm python3 cc unzip curl tar; do
  command -v "$t" >/dev/null || warn "'$t' missing — some features/installs may fail. Debian: sudo apt install ripgrep nodejs npm python3 build-essential unzip curl tar"
done
command -v gh >/dev/null || warn "'gh' missing — GitPanel cannot create GitHub repositories directly. Optional: sudo apt install gh; gh auth login"

# ---- 1. clone or update the config (idempotent) -----------------------------
if [ -d "$CONFIG_DIR/.git" ]; then
  log "Existing repo at $CONFIG_DIR — pulling."
  git -C "$CONFIG_DIR" pull --ff-only
elif [ -e "$CONFIG_DIR" ] && [ -n "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
  backup="$CONFIG_DIR.bak.$(date +%Y%m%d%H%M%S)"
  warn "$CONFIG_DIR exists and is not a git repo — backing up to $backup"
  mv "$CONFIG_DIR" "$backup"
  log "Cloning $REPO_URL -> $CONFIG_DIR"
  clone_config
else
  log "Cloning $REPO_URL -> $CONFIG_DIR"
  clone_config
fi

# ---- 2. install plugins at the PINNED commits (lazy-lock.json) --------------
# 'restore' checks every plugin out to the SHA recorded in lazy-lock.json, so
# the result is reproducible. We deliberately do NOT use 'Lazy sync', which
# would UPDATE plugins to latest and REWRITE the committed lockfile. init.lua
# self-bootstraps lazy.nvim on this first headless run.
log "Installing plugins from lazy-lock.json (Lazy restore)…"
nvim --headless "+Lazy! restore" +qa

# ---- 3. install Mason CLI tools ---------------------------------------------
# nvim-treesitter main requires tree-sitter-cli >= 0.26.1. Debian 13's package
# is older, so Mason installs a current upstream binary before parser builds.
# mason-tool-installer's *Sync command blocks until every tool is available.
log "Installing Mason CLI tools (tree-sitter-cli, prettier, markdownlint-cli2)…"
NVIM_TREESITTER_SKIP_INSTALL=1 nvim --headless "+MasonToolsInstallSync" +qa

# ---- 4. build Treesitter parsers synchronously ------------------------------
# The main branch removed TSInstallSync; wait on its Lua install task instead.
# Keep this list in sync with lua/plugins/treesitter.lua.
if command -v cc >/dev/null; then
  log "Building Treesitter parsers…"
  NVIM_TREESITTER_SKIP_INSTALL=1 nvim --headless \
    "+lua local ok = require('nvim-treesitter').install({ 'c', 'lua', 'vim', 'vimdoc', 'query', 'javascript', 'typescript', 'tsx', 'python', 'html', 'xml', 'css', 'json', 'markdown', 'markdown_inline' }):wait(300000); if not ok then vim.cmd('cquit 1') end" \
    +qa || warn "Some parsers failed to build; they will retry on first launch."
else
  warn "No C compiler — skipping parser build; parsers build on first interactive launch once cc exists."
fi

# ---- 5. install Mason LSP servers -------------------------------------------
# Mason registry names mirroring mason-lspconfig.ensure_installed in
# lua/plugins/lsp.lua:
#   lua_ls -> lua-language-server (standalone, no Node)
#   pyright -> pyright                        (Node)
#   ts_ls  -> typescript-language-server      (Node >= 20)
#   html   -> html-lsp                        (Node)
#   cssls  -> css-lsp                         (Node)
#   jsonls -> json-lsp                        (Node)
#   marksman -> marksman (standalone, no Node)
# (Keep this list in sync with lua/plugins/lsp.lua if you add servers.)
log "Installing Mason LSP servers…"
nvim --headless "+MasonInstall lua-language-server pyright typescript-language-server html-lsp css-lsp json-lsp marksman" +qa

log "Done. Launch 'nvim', then run :checkhealth / :Lazy / :Mason to verify."
