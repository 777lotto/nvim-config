#!/usr/bin/env bash
set -euo pipefail

nvim_config_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
nvim_config_test_root="$(mktemp -d "${TMPDIR:-/tmp}/nvim-ux-integration.XXXXXX")"
trap 'rm -rf -- "$nvim_config_test_root"' EXIT

nvim_config_installed="${XDG_CONFIG_HOME:-${HOME:?HOME is required}/.config}/nvim/dev"
nvim_config_foundation="${UX_FOUNDATION_ROOT:-$nvim_config_installed/UX-foundation.nvim}"
nvim_config_styling="${UX_STYLING_ROOT:-$nvim_config_installed/UX-styling.nvim}"
nvim_config_chrome="${UX_CHROME_ROOT:-$nvim_config_installed/UX-chrome.nvim}"
nvim_config_source_dev="${NVIM_CONFIG_SOURCE_DEV_ROOT:-$nvim_config_installed}"
nvim_config_dev="$nvim_config_test_root/dev"
mkdir --parents "$nvim_config_dev"

for nvim_config_entry in \
  "UX-foundation.nvim:$nvim_config_foundation" \
  "UX-styling.nvim:$nvim_config_styling" \
  "UX-chrome.nvim:$nvim_config_chrome"; do
  nvim_config_name=${nvim_config_entry%%:*}
  nvim_config_path=${nvim_config_entry#*:}
  [ -d "$nvim_config_path" ] || {
    printf 'Missing UX source for %s: %s\n' "$nvim_config_name" "$nvim_config_path" >&2
    exit 1
  }
  ln -s "$nvim_config_path" "$nvim_config_dev/$nvim_config_name"
done

for nvim_config_name in agent-manager.nvimz git-panel.nvim mcp-buff; do
  [ -e "$nvim_config_source_dev/$nvim_config_name" ] || {
    printf 'Missing account-owned source: %s/%s\n' "$nvim_config_source_dev" "$nvim_config_name" >&2
    exit 1
  }
  ln -s "$(readlink -f "$nvim_config_source_dev/$nvim_config_name")" \
    "$nvim_config_dev/$nvim_config_name"
done

run_ux() {
  env NVIM_CONFIG_ROOT="$nvim_config_root" \
    NVIM_DEV_DIR="$nvim_config_dev" \
    NVIM_CONFIG_USE_DEV=1 \
    NVIM_CONFIG_VERIFY_LOCK=1 \
    NVIM_TOOLCHAIN_SYNC=1 \
    NVIM_TREESITTER_SKIP_INSTALL=1 \
    nvim --headless \
      --cmd 'lua vim.opt.runtimepath:prepend(vim.env.NVIM_CONFIG_ROOT)' \
      -u "$nvim_config_root/init.lua" "$@"
}

run_ux -l "$nvim_config_root/scripts/ci/test-ux.lua" "$nvim_config_root"
run_ux -l "$nvim_config_root/scripts/ci/benchmark-ux.lua"

nvim_config_startup_max=0
for nvim_config_run in 1 2 3; do
  nvim_config_startup_file="$nvim_config_test_root/startup-$nvim_config_run.log"
  run_ux --startuptime "$nvim_config_startup_file" +quitall
  nvim_config_startup_ms="$(awk \
    '/--- NVIM STARTED ---/ { value=$1 } END { print int(value + 0.5) }' \
    "$nvim_config_startup_file")"
  [ "$nvim_config_startup_ms" -gt "$nvim_config_startup_max" ] &&
    nvim_config_startup_max=$nvim_config_startup_ms
done
printf 'UX benchmark: full config startup     %d ms max (3 runs; budget 1000 ms)\n' \
  "$nvim_config_startup_max"
test "$nvim_config_startup_max" -le 1000

printf '%s\n' "UX integration and performance checks passed"
