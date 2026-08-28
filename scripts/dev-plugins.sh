#!/usr/bin/env bash
# Fleet operations over the gitignored dev/ plugin checkouts that lazy.nvim's
# dev mode resolves. Every entry is an independent repository with its own
# lockfile pin and release flow; dev/ only organizes them on disk, holds either
# real clones or symlinks to canonical ones, and is never committed.
set -euo pipefail

dev_plugins_root="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dev_plugins_dir="$dev_plugins_root/dev"
dev_plugins_base="${NVIM_DEV_GIT_BASE:-https://github.com/777lotto}"
dev_plugins_branch="${NVIM_DEV_GIT_BRANCH:-bluff}"

# lazy.nvim matches a dev plugin by its spec name, so these directory names are
# case-sensitive and must equal the repository names exactly.
dev_plugins_fleet=(
  git-panel.nvim
  mcp-buff
  UX-foundation.nvim
  UX-styling.nvim
  UX-chrome.nvim
  agent-manager.nvimz
)

log()  { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }
die()  { printf 'XX  %s\n' "$*" >&2; exit 1; }

# A symlink to a canonical clone counts as present: that is the workstation
# layout, while a standalone machine keeps real clones in the same place.
dev_plugins_present() {
  [ -e "$1" ] || [ -L "$1" ]
}

dev_plugins_is_repo() {
  git -C "$1" rev-parse --git-dir >/dev/null 2>&1
}

dev_plugins_clone() {
  mkdir -p "$dev_plugins_dir"
  local name path
  for name in "${dev_plugins_fleet[@]}"; do
    path="$dev_plugins_dir/$name"
    if dev_plugins_present "$path"; then
      log "$name: already present"
      continue
    fi
    log "$name: cloning $dev_plugins_base/$name.git ($dev_plugins_branch)"
    git clone --branch "$dev_plugins_branch" "$dev_plugins_base/$name.git" "$path"
  done
}

dev_plugins_pull() {
  local name path failed=0
  for name in "${dev_plugins_fleet[@]}"; do
    path="$dev_plugins_dir/$name"
    if ! dev_plugins_present "$path"; then
      warn "$name: absent; run 'mise run plugins:clone' first"
      failed=1
      continue
    fi
    if ! dev_plugins_is_repo "$path"; then
      warn "$name: not a Git checkout"
      failed=1
      continue
    fi
    if [ -n "$(git -C "$path" status --porcelain)" ]; then
      warn "$name: refusing to pull a dirty checkout; commit or stash it first"
      failed=1
      continue
    fi
    log "$name: fast-forwarding"
    if ! git -C "$path" pull --ff-only; then
      warn "$name: not fast-forwardable; resolve the divergence in its own checkout"
      failed=1
    fi
  done
  [ "$failed" -eq 0 ] || die "one or more dev plugins were left untouched"
}

dev_plugins_status() {
  local name path branch dirty upstream counts ahead behind
  for name in "${dev_plugins_fleet[@]}"; do
    path="$dev_plugins_dir/$name"
    if ! dev_plugins_present "$path"; then
      printf '%-22s absent\n' "$name"
      continue
    fi
    if ! dev_plugins_is_repo "$path"; then
      printf '%-22s not a Git checkout\n' "$name"
      continue
    fi
    branch="$(git -C "$path" rev-parse --abbrev-ref HEAD)"
    dirty="$(git -C "$path" status --porcelain | wc -l | tr -d ' ')"
    upstream="$(git -C "$path" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
    if [ -z "$upstream" ]; then
      printf '%-22s %-16s dirty=%-4s no upstream\n' "$name" "$branch" "$dirty"
      continue
    fi
    counts="$(git -C "$path" rev-list --left-right --count "$upstream...HEAD")"
    behind="$(printf '%s' "$counts" | cut -f1)"
    ahead="$(printf '%s' "$counts" | cut -f2)"
    printf '%-22s %-16s dirty=%-4s ahead=%-4s behind=%s\n' "$name" "$branch" "$dirty" "$ahead" "$behind"
  done
}

dev_plugins_check() {
  local name path checker label failed=0
  for name in "${dev_plugins_fleet[@]}"; do
    path="$dev_plugins_dir/$name"
    if ! dev_plugins_present "$path"; then
      warn "$name: absent; run 'mise run plugins:clone' first"
      failed=1
      continue
    fi
    # -L follows the symlink layout. A docs-only repository has no Lua at all
    # and is skipped rather than failing the checker's empty-input guard.
    if [ -z "$(find -L "$path" -path '*/.git' -prune -o -name '*.lua' -print -quit)" ]; then
      log "$name: no Lua sources; skipped"
      continue
    fi
    if [ -f "$path/scripts/check-lua.lua" ]; then
      checker="$path/scripts/check-lua.lua"
      label="its own checker"
    else
      checker="$dev_plugins_root/scripts/ci/check-lua.lua"
      label="the config's checker"
    fi
    log "$name: compiling with $label"
    if ! nvim --headless --clean -l "$checker" "$path"; then
      failed=1
    fi
  done
  [ "$failed" -eq 0 ] || die "Lua compilation failed for at least one dev plugin"
}

case "${1:-}" in
  clone)  dev_plugins_clone ;;
  pull)   dev_plugins_pull ;;
  status) dev_plugins_status ;;
  check)  dev_plugins_check ;;
  *) die "usage: dev-plugins.sh clone|pull|status|check" ;;
esac
