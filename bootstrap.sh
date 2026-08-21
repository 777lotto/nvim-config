#!/usr/bin/env bash
# Install this Neovim configuration on a fresh machine. Updating an existing
# checkout is intentionally delegated to bin/nvim-config so bootstrap never
# mixes repository mutation with provisioning.
set -euo pipefail

REPO_URL="${NVIM_CONFIG_REPO:-https://github.com/777lotto/nvim-config.git}"
BRANCH="${NVIM_CONFIG_BRANCH:-}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
CLI_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"

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

command -v git >/dev/null 2>&1 || die "git is required"
command -v nvim >/dev/null 2>&1 || die "Neovim is required"

if [ -d "$CONFIG_DIR/.git" ]; then
  log "Using the existing checkout at $CONFIG_DIR (bootstrap does not pull)"
elif [ -e "$CONFIG_DIR" ] && [ -n "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
  nvim_config_backup="$CONFIG_DIR.bak.$(date +%Y%m%d%H%M%S)"
  warn "$CONFIG_DIR exists and is not a Git repository; moving it to $nvim_config_backup"
  mv "$CONFIG_DIR" "$nvim_config_backup"
  log "Cloning $REPO_URL into $CONFIG_DIR"
  clone_config
else
  log "Cloning $REPO_URL into $CONFIG_DIR"
  clone_config
fi

[ -x "$CONFIG_DIR/bin/nvim-config" ] || die "missing executable: $CONFIG_DIR/bin/nvim-config"

mkdir -p "$CLI_DIR"
nvim_config_link="$CLI_DIR/nvim-config"
if [ ! -e "$nvim_config_link" ] && [ ! -L "$nvim_config_link" ]; then
  ln -s "$CONFIG_DIR/bin/nvim-config" "$nvim_config_link"
  log "Installed nvim-config command at $nvim_config_link"
elif [ -L "$nvim_config_link" ] && [ "$(readlink "$nvim_config_link")" = "$CONFIG_DIR/bin/nvim-config" ]; then
  log "nvim-config command is already installed"
else
  warn "$nvim_config_link already exists; leaving it unchanged"
  warn "Use $CONFIG_DIR/bin/nvim-config directly or adjust PATH yourself"
fi

"$CONFIG_DIR/bin/nvim-config" doctor
"$CONFIG_DIR/bin/nvim-config" sync

log "Installation complete. Restart Neovim, then use 'nvim-config update' for future updates."
