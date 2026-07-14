#!/usr/bin/env bash
# bootstrap.sh — provision this Neovim config on a fresh machine (macOS or Debian).
# Idempotent: safe to re-run. Clones/updates the repo into ~/.config/nvim, then
# installs plugins pinned by lazy-lock.json, builds Treesitter parsers, and
# installs the Mason tools & LSP servers — all headlessly and synchronously.
set -euo pipefail

# ---- configuration (override via env) ---------------------------------------
REPO_URL="${NVIM_CONFIG_REPO:-https://github.com/777sudo/nvim-config.git}"
BRANCH="${NVIM_CONFIG_BRANCH:-main}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[1;31mXX\033[0m  %s\n' "$*" >&2; exit 1; }

# ---- 0. prerequisites -------------------------------------------------------
command -v git  >/dev/null || die "git is required."
command -v nvim >/dev/null || die "Neovim not found. Install >= 0.11 first. On Debian the apt build is usually too old — use the release tarball/AppImage or the neovim-ppa/unstable PPA."

# This config uses Neovim 0.11 features -> require >= 0.11.
ver="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
major="${ver%%.*}"; minor="${ver##*.}"
if [ "$major" -eq 0 ] && [ "$minor" -lt 11 ]; then
  die "Neovim $ver found; this config needs >= 0.11."
fi
log "Neovim $ver OK."

# Soft-check the tools plugins/Mason shell out to (warn, do not fail).
#   NOTE: ts_ls (typescript-language-server 5.x) needs Node >= 20. Debian
#   'bookworm' ships Node 18 -> use NodeSource or Debian 'trixie' (Node 20).
for t in rg node npm python3 cc make unzip curl; do
  command -v "$t" >/dev/null || warn "'$t' missing — some features/installs may fail. Debian: sudo apt install ripgrep nodejs npm python3 build-essential unzip curl"
done

# ---- 1. clone or update the config (idempotent) -----------------------------
if [ -d "$CONFIG_DIR/.git" ]; then
  log "Existing repo at $CONFIG_DIR — pulling."
  git -C "$CONFIG_DIR" pull --ff-only
elif [ -e "$CONFIG_DIR" ] && [ -n "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
  backup="$CONFIG_DIR.bak.$(date +%Y%m%d%H%M%S)"
  warn "$CONFIG_DIR exists and is not a git repo — backing up to $backup"
  mv "$CONFIG_DIR" "$backup"
  log "Cloning $REPO_URL -> $CONFIG_DIR"
  git clone --branch "$BRANCH" "$REPO_URL" "$CONFIG_DIR"
else
  log "Cloning $REPO_URL -> $CONFIG_DIR"
  git clone --branch "$BRANCH" "$REPO_URL" "$CONFIG_DIR"
fi

# ---- 2. install plugins at the PINNED commits (lazy-lock.json) --------------
# 'restore' checks every plugin out to the SHA recorded in lazy-lock.json, so
# the result is reproducible. We deliberately do NOT use 'Lazy sync', which
# would UPDATE plugins to latest and REWRITE the committed lockfile. init.lua
# self-bootstraps lazy.nvim on this first headless run.
log "Installing plugins from lazy-lock.json (Lazy restore)…"
nvim --headless "+Lazy! restore" +qa

# ---- 3. build Treesitter parsers synchronously ------------------------------
# ensure_installed only auto-installs parsers ASYNC on first launch (and +qa can
# quit before they finish). TSInstallSync builds them now and blocks. Needs a C
# compiler + make (build-essential on Debian, Xcode CLT on macOS).
# Keep this list in sync with ensure_installed in init.lua (treesitter block).
TS_PARSERS="c lua vim vimdoc query javascript typescript tsx python html xml css markdown markdown_inline"
if command -v cc >/dev/null && command -v make >/dev/null; then
  log "Building Treesitter parsers (TSInstallSync)…"
  nvim --headless "+TSInstallSync $TS_PARSERS" +qa || warn "Some parsers failed to build; they will retry on first launch."
else
  warn "No C compiler/make — skipping parser build; parsers build on first interactive launch once cc/make exist."
fi

# ---- 4. install Mason CLI tools (prettier, markdownlint-cli2) ---------------
# mason-tool-installer's *Sync command blocks until finished.
log "Installing Mason CLI tools (prettier, markdownlint-cli2)…"
nvim --headless "+MasonToolsInstallSync" +qa

# ---- 5. install Mason LSP servers -------------------------------------------
# Mason registry names mirroring mason-lspconfig.ensure_installed in init.lua:
#   lua_ls -> lua-language-server (standalone, no Node)
#   pyright -> pyright                        (Node)
#   ts_ls  -> typescript-language-server      (Node >= 20)
#   html   -> html-lsp                        (Node)
#   cssls  -> css-lsp                         (Node)
#   marksman -> marksman (standalone, no Node)
# (Keep this list in sync with init.lua if you add servers.)
log "Installing Mason LSP servers…"
nvim --headless "+MasonInstall lua-language-server pyright typescript-language-server html-lsp css-lsp marksman" +qa

log "Done. Launch 'nvim', then run :checkhealth / :Lazy / :Mason to verify."
