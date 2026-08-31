#!/usr/bin/env bash
set -euo pipefail

nvim_config_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"

bash -n \
  "$nvim_config_root/bootstrap.sh" \
  "$nvim_config_root/bin/nvim-config" \
  "$nvim_config_root/bin/nvim-update" \
  "$nvim_config_root/scripts/dev-plugins.sh" \
  "$nvim_config_root"/scripts/ci/*.sh
if command -v shellcheck >/dev/null 2>&1 && shellcheck --version >/dev/null 2>&1; then
  shellcheck \
    "$nvim_config_root/bootstrap.sh" \
    "$nvim_config_root/bin/nvim-config" \
    "$nvim_config_root/bin/nvim-update" \
    "$nvim_config_root/scripts/dev-plugins.sh" \
    "$nvim_config_root"/scripts/ci/*.sh
fi

nvim --headless --clean -l "$nvim_config_root/scripts/ci/check-lua.lua" "$nvim_config_root"
NVIM_CONFIG_CHANNEL=bet NVIM_CLIPBOARD=native \
  nvim --headless --clean -l "$nvim_config_root/scripts/ci/smoke-core.lua" \
    "$nvim_config_root" native
NVIM_CONFIG_CHANNEL=bet NVIM_CLIPBOARD=osc52 SSH_TTY=/dev/pts/0 \
  nvim --headless --clean -l "$nvim_config_root/scripts/ci/smoke-core.lua" \
    "$nvim_config_root" osc52

"$nvim_config_root/scripts/ci/test-dev-plugins.sh" "$nvim_config_root"
"$nvim_config_root/scripts/ci/test-update.sh" "$nvim_config_root"
"$nvim_config_root/scripts/ci/test-ux.sh" "$nvim_config_root"

git -C "$nvim_config_root" diff --check
printf '%s\n' "nvim-config verification passed"
