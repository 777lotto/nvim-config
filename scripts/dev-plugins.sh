#!/usr/bin/env bash
# Fleet operations over the gitignored dev/ plugin checkouts that lazy.nvim's
# dev mode resolves. Every entry is an independent repository with its own
# lockfile pin and release flow; dev/ only organizes them on disk, holds either
# real clones or symlinks to canonical ones, and is never committed.
set -euo pipefail

# Resolve a symlink to this script the way bin/nvim-config does, so a shim on
# PATH still finds the repository the script actually lives in.
dev_plugins_source="${BASH_SOURCE[0]}"
while [ -h "$dev_plugins_source" ]; do
  dev_plugins_dirname="$(cd -P "$(dirname "$dev_plugins_source")" >/dev/null 2>&1 && pwd)"
  dev_plugins_source="$(readlink "$dev_plugins_source")"
  [[ "$dev_plugins_source" != /* ]] && dev_plugins_source="$dev_plugins_dirname/$dev_plugins_source"
done
dev_plugins_root="$(cd -P "$(dirname "$dev_plugins_source")/.." && pwd)"
dev_plugins_dir="${NVIM_DEV_DIR:-$dev_plugins_root/dev}"
dev_plugins_base="${NVIM_DEV_GIT_BASE:-https://github.com/777lotto}"
dev_plugins_branch="${NVIM_DEV_GIT_BRANCH:-$("$dev_plugins_root/bin/nvim-config" channel --no-color)}"

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

# dev/ lives inside this repository's own working tree, so `rev-parse` alone
# would happily walk up out of an empty or half-cloned entry and answer for the
# config repository instead. Require the entry to be a checkout root.
dev_plugins_is_repo() {
  local top
  top="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" || return 1
  [ -n "$top" ] || return 1
  [ "$(cd -P "$1" >/dev/null 2>&1 && pwd)" = "$(cd -P "$top" >/dev/null 2>&1 && pwd)" ]
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
    git clone --branch "$dev_plugins_branch" -- "$dev_plugins_base/$name.git" "$path"
  done
}

dev_plugins_sync() {
  local name path target_ref branch_holder physical_path failed=0
  dev_plugins_clone

  # Fetch and validate the complete fleet before switching any checkout. A
  # network or missing-branch failure therefore leaves every existing local
  # branch untouched, and a rerun safely resumes after missing clones appear.
  for name in "${dev_plugins_fleet[@]}"; do
    path="$dev_plugins_dir/$name"
    if ! dev_plugins_present "$path"; then
      warn "$name: absent after clone"
      failed=1
      continue
    fi
    if ! dev_plugins_is_repo "$path"; then
      warn "$name: not a Git checkout"
      failed=1
      continue
    fi
    if [ -n "$(git -C "$path" status --porcelain)" ]; then
      warn "$name: refusing to switch a dirty checkout; commit or stash it first"
      failed=1
      continue
    fi
    target_ref="refs/remotes/origin/$dev_plugins_branch"
    log "$name: fetching $dev_plugins_branch"
    if ! git -C "$path" fetch --prune origin \
      "+refs/heads/$dev_plugins_branch:$target_ref"; then
      warn "$name: could not fetch origin/$dev_plugins_branch"
      failed=1
      continue
    fi
    if ! git -C "$path" show-ref --verify --quiet "$target_ref"; then
      warn "$name: origin/$dev_plugins_branch does not exist"
      failed=1
      continue
    fi
    if git -C "$path" show-ref --verify --quiet "refs/heads/$dev_plugins_branch" \
      && ! git -C "$path" merge-base --is-ancestor "refs/heads/$dev_plugins_branch" "$target_ref" \
      && ! git -C "$path" merge-base --is-ancestor "$target_ref" "refs/heads/$dev_plugins_branch"; then
      warn "$name: local $dev_plugins_branch and origin/$dev_plugins_branch diverged"
      failed=1
    fi
    branch_holder="$(git -C "$path" worktree list --porcelain | awk \
      -v target="refs/heads/$dev_plugins_branch" \
      '$1 == "worktree" { worktree=$2 } $1 == "branch" && $2 == target { print worktree }')"
    physical_path="$(cd -P "$path" && pwd)"
    if [ -n "$branch_holder" ] && [ "$branch_holder" != "$physical_path" ]; then
      warn "$name: $dev_plugins_branch is already checked out at $branch_holder"
      failed=1
    fi
  done
  [ "$failed" -eq 0 ] || die "fleet preflight failed; no existing checkout branch was switched"

  for name in "${dev_plugins_fleet[@]}"; do
    path="$dev_plugins_dir/$name"
    target_ref="refs/remotes/origin/$dev_plugins_branch"
    log "$name: selecting $dev_plugins_branch"
    if git -C "$path" show-ref --verify --quiet "refs/heads/$dev_plugins_branch"; then
      git -C "$path" switch "$dev_plugins_branch"
    else
      git -C "$path" switch --track -c "$dev_plugins_branch" "origin/$dev_plugins_branch"
    fi
    git -C "$path" branch --set-upstream-to="origin/$dev_plugins_branch" "$dev_plugins_branch" >/dev/null
    if git -C "$path" merge-base --is-ancestor HEAD "$target_ref"; then
      git -C "$path" merge --ff-only "$target_ref"
    elif git -C "$path" merge-base --is-ancestor "$target_ref" HEAD; then
      warn "$name: local $dev_plugins_branch is ahead; no local commits were changed"
    fi
  done
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
  pull)   dev_plugins_sync ;;
  sync)   dev_plugins_sync ;;
  status) dev_plugins_status ;;
  check)  dev_plugins_check ;;
  *) die "usage: dev-plugins.sh clone|pull|sync|status|check" ;;
esac
