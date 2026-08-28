#!/usr/bin/env bash
set -euo pipefail

nvim_config_source_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
nvim_config_test_root="$(mktemp -d)"
trap 'rm -rf -- "$nvim_config_test_root"' EXIT

nvim_config_remote="$nvim_config_test_root/remote.git"
nvim_config_publisher="$nvim_config_test_root/publisher"
nvim_config_consumer="$nvim_config_test_root/consumer"

git init --bare --initial-branch=bet "$nvim_config_remote" >/dev/null
mkdir --parents "$nvim_config_publisher"
git -C "$nvim_config_source_root" archive --format=tar HEAD |
  tar --extract --file=- --directory="$nvim_config_publisher"
git -C "$nvim_config_publisher" init --quiet --initial-branch=bet
git -C "$nvim_config_publisher" add .
git -C "$nvim_config_publisher" \
  -c user.name='nvim-config CI' \
  -c user.email='ci@example.invalid' \
  -c commit.gpgsign=false \
  commit --quiet --message='test: seed updater fixture'
git -C "$nvim_config_publisher" remote add origin "$nvim_config_remote"
git -C "$nvim_config_publisher" push --quiet --set-upstream origin bet
git clone --quiet --branch bet "$nvim_config_remote" "$nvim_config_consumer"

printf '%s\n' "safe updater integration probe" > "$nvim_config_publisher/docs/update-probe.txt"
git -C "$nvim_config_publisher" add docs/update-probe.txt
git -C "$nvim_config_publisher" \
  -c user.name='nvim-config CI' \
  -c user.email='ci@example.invalid' \
  -c commit.gpgsign=false \
  commit --quiet --message='test: advance updater fixture'
git -C "$nvim_config_publisher" push --quiet

nvim_config_remote_before="$(git -C "$nvim_config_consumer" remote get-url origin)"
NVIM_CONFIG_DIR="$nvim_config_consumer" \
  "$nvim_config_consumer/bin/nvim-config" update --no-color
test -f "$nvim_config_consumer/docs/update-probe.txt"
test "$(git -C "$nvim_config_consumer" remote get-url origin)" = "$nvim_config_remote_before"
test -z "$(git -C "$nvim_config_consumer" status --porcelain --untracked-files=all)"

printf '%s\n' "dirty worktree probe" > "$nvim_config_consumer/dirty-probe"
if NVIM_CONFIG_DIR="$nvim_config_consumer" \
  "$nvim_config_consumer/bin/nvim-config" update --no-color; then
  echo "Updater accepted a dirty worktree" >&2
  exit 1
fi

bash "$nvim_config_source_root/scripts/ci/test-mise.sh" "$nvim_config_source_root"

printf '%s\n' "Whole-config updater integration passed"
