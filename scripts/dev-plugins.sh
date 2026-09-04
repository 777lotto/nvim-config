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
dev_plugins_branch=bluff
dev_plugins_mise="${NVIM_DEV_MISE:-mise}"

# Keep this fleet limited to repositories that nvim-config actually loads.
# lazy.nvim matches a dev plugin by its spec name, so these directory names are
# case-sensitive and must equal the repository names exactly.
dev_plugins_fleet=(
  agent-manager.nvimz
  git-panel.nvim
  mcp-buff
  UX-foundation.nvim
  UX-styling.nvim
  UX-chrome.nvim
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

dev_plugins_command_available() {
  if [[ "$1" == */* ]]; then
    [ -x "$1" ]
  else
    command -v "$1" >/dev/null 2>&1
  fi
}

dev_plugins_agent_manager_healthy() {
  local path=$1
  local broker="$path/target/release/agent-manager-broker"
  local python="$path/python/.venv/bin/python"
  [ -x "$broker" ] \
    && [ -x "$python" ] \
    && "$broker" contract-info >/dev/null 2>&1 \
    && "$python" -B -I -c 'import agent_manager_claude_worker, claude_agent_sdk' \
      >/dev/null 2>&1
}

# Agent Manager is the one fleet plugin with a compiled broker and locked
# worker environment. Keep a commit stamp beside its ignored Cargo output so a
# no-op fleet sync performs only the cheap behavioral checks below. A missing,
# stale, or unhealthy runtime is rebuilt from the exact tool versions declared
# by that checkout. The stamp is written only after both runtime probes pass,
# making an interrupted or failed bootstrap safe to retry.
dev_plugins_bootstrap_agent_manager() {
  local path="$dev_plugins_dir/agent-manager.nvimz"
  local commit branch stamp recorded tool_output stamp_tmp
  local -a tool_specs

  dev_plugins_is_repo "$path" || die "agent-manager.nvimz: not a Git checkout"
  [ -z "$(git -C "$path" status --porcelain)" ] \
    || die "agent-manager.nvimz: refusing to bootstrap a dirty checkout"
  branch="$(git -C "$path" symbolic-ref --quiet --short HEAD || true)"
  [ "$branch" = "$dev_plugins_branch" ] \
    || die "agent-manager.nvimz: expected $dev_plugins_branch, found ${branch:-detached HEAD}"

  commit="$(git -C "$path" rev-parse HEAD)"
  stamp="$path/target/.nvim-dev-runtime.commit"
  recorded="$(cat "$stamp" 2>/dev/null || true)"
  if [ "$recorded" = "$commit" ] && dev_plugins_agent_manager_healthy "$path"; then
    log "agent-manager.nvimz: source runtime is current (${commit:0:12})"
    return
  fi

  dev_plugins_command_available "$dev_plugins_mise" \
    || die "agent-manager.nvimz: Mise is required to bootstrap its source runtime"
  tool_output="$(
    nvim --headless --clean -l "$dev_plugins_root/scripts/agent-manager-tools.lua" \
      "$path/mise.toml"
  )" || die "agent-manager.nvimz: could not read its pinned tool versions"
  mapfile -t tool_specs <<< "$tool_output"
  [ "${#tool_specs[@]}" -eq 3 ] \
    || die "agent-manager.nvimz: expected Rust, Python, and uv tool pins"

  log "agent-manager.nvimz: bootstrapping source runtime (${commit:0:12})"
  "$dev_plugins_mise" -C "${TMPDIR:-/tmp}" install "${tool_specs[@]}"
  # The inner shell receives the checkout as positional argument 1; expansion
  # must happen there, after Mise has placed the pinned tools on PATH.
  # shellcheck disable=SC2016
  "$dev_plugins_mise" -C "${TMPDIR:-/tmp}" exec "${tool_specs[@]}" -- \
    bash -c '
      set -euo pipefail
      agent_manager_root=$1
      cd "$agent_manager_root/python"
      uv sync --frozen --all-groups
      cd "$agent_manager_root"
      cargo build --release --locked -p agent-manager-broker
    ' bash "$path"

  dev_plugins_agent_manager_healthy "$path" \
    || die "agent-manager.nvimz: source runtime verification failed"
  [ "$(git -C "$path" rev-parse HEAD)" = "$commit" ] \
    || die "agent-manager.nvimz: checkout changed during source runtime bootstrap"
  mkdir -p "$path/target"
  stamp_tmp="$(mktemp "$path/target/.nvim-dev-runtime.commit.tmp.XXXXXX")"
  printf '%s\n' "$commit" > "$stamp_tmp"
  chmod 0600 "$stamp_tmp"
  mv -- "$stamp_tmp" "$stamp"
  log "agent-manager.nvimz: source runtime verified"
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
  local name path branch target_ref failed=0
  dev_plugins_clone

  # Fetch and validate the complete fleet before fast-forwarding any checkout.
  # A network, dirty-tree, or branch mismatch therefore leaves every existing
  # checkout untouched, and a rerun safely resumes after missing clones appear.
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
      warn "$name: refusing to update a dirty checkout; commit or stash it first"
      failed=1
      continue
    fi
    branch="$(git -C "$path" symbolic-ref --quiet --short HEAD || true)"
    if [ "$branch" != "$dev_plugins_branch" ]; then
      warn "$name: expected $dev_plugins_branch, found ${branch:-detached HEAD}; switch it explicitly first"
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
  done
  [ "$failed" -eq 0 ] || die "fleet preflight failed; no existing checkout was updated"

  for name in "${dev_plugins_fleet[@]}"; do
    path="$dev_plugins_dir/$name"
    target_ref="refs/remotes/origin/$dev_plugins_branch"
    log "$name: fast-forwarding $dev_plugins_branch"
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
  clone)  dev_plugins_clone; dev_plugins_bootstrap_agent_manager ;;
  pull)   dev_plugins_sync; dev_plugins_bootstrap_agent_manager ;;
  sync)   dev_plugins_sync; dev_plugins_bootstrap_agent_manager ;;
  status) dev_plugins_status ;;
  check)  dev_plugins_check ;;
  *) die "usage: dev-plugins.sh clone|pull|sync|status|check" ;;
esac
