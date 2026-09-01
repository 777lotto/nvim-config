#!/usr/bin/env bash
set -euo pipefail

nvim_config_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
nvim_config_test_root="$(mktemp -d "${TMPDIR:-/tmp}/nvim-dev-fleet.XXXXXX")"
trap 'rm -rf -- "$nvim_config_test_root"' EXIT

nvim_config_remote_root="$nvim_config_test_root/remotes"
nvim_config_dev_root="$nvim_config_test_root/dev"
mkdir --parents "$nvim_config_remote_root"

nvim_config_fleet=(
  git-panel.nvim
  mcp-buff
  UX-foundation.nvim
  UX-styling.nvim
  UX-chrome.nvim
)

for nvim_config_name in "${nvim_config_fleet[@]}"; do
  nvim_config_remote="$nvim_config_remote_root/$nvim_config_name.git"
  nvim_config_publisher="$nvim_config_test_root/publisher-$nvim_config_name"
  git init --bare --quiet --initial-branch=bet "$nvim_config_remote"
  git init --quiet --initial-branch=bet "$nvim_config_publisher"
  printf '%s\n' bet > "$nvim_config_publisher/channel.txt"
  git -C "$nvim_config_publisher" add channel.txt
  git -C "$nvim_config_publisher" \
    -c user.name='nvim-config CI' \
    -c user.email='ci@example.invalid' \
    -c commit.gpgsign=false \
    commit --quiet --message='test: seed bet'
  git -C "$nvim_config_publisher" remote add origin "$nvim_config_remote"
  git -C "$nvim_config_publisher" push --quiet --set-upstream origin bet
  git -C "$nvim_config_publisher" switch --quiet -c bluff
  printf '%s\n' bluff > "$nvim_config_publisher/channel.txt"
  git -C "$nvim_config_publisher" add channel.txt
  git -C "$nvim_config_publisher" \
    -c user.name='nvim-config CI' \
    -c user.email='ci@example.invalid' \
    -c commit.gpgsign=false \
    commit --quiet --message='test: seed bluff'
  git -C "$nvim_config_publisher" push --quiet --set-upstream origin bluff
done

# Agent Manager is specification-only and deliberately outside the runtime
# fleet. Model the real repository with only bet published: a bluff sync must
# ignore this checkout rather than blocking the installed plugins.
nvim_config_deferred_name=agent-manager.nvimz
nvim_config_deferred_remote="$nvim_config_remote_root/$nvim_config_deferred_name.git"
nvim_config_deferred_publisher="$nvim_config_test_root/publisher-$nvim_config_deferred_name"
git init --bare --quiet --initial-branch=bet "$nvim_config_deferred_remote"
git init --quiet --initial-branch=bet "$nvim_config_deferred_publisher"
printf '%s\n' bet > "$nvim_config_deferred_publisher/channel.txt"
git -C "$nvim_config_deferred_publisher" add channel.txt
git -C "$nvim_config_deferred_publisher" \
  -c user.name='nvim-config CI' \
  -c user.email='ci@example.invalid' \
  -c commit.gpgsign=false \
  commit --quiet --message='test: seed deferred repository'
git -C "$nvim_config_deferred_publisher" remote add origin "$nvim_config_deferred_remote"
git -C "$nvim_config_deferred_publisher" push --quiet --set-upstream origin bet
git clone --quiet --branch bet -- "$nvim_config_deferred_remote" \
  "$nvim_config_dev_root/$nvim_config_deferred_name"

NVIM_DEV_DIR="$nvim_config_dev_root" \
NVIM_DEV_GIT_BASE="$nvim_config_remote_root" \
NVIM_DEV_GIT_BRANCH=bluff \
  "$nvim_config_root/scripts/dev-plugins.sh" sync

for nvim_config_name in "${nvim_config_fleet[@]}"; do
  test "$(git -C "$nvim_config_dev_root/$nvim_config_name" branch --show-current)" = bluff
  test "$(cat "$nvim_config_dev_root/$nvim_config_name/channel.txt")" = bluff
done
test "$(git -C "$nvim_config_dev_root/$nvim_config_deferred_name" branch --show-current)" = bet
test "$(cat "$nvim_config_dev_root/$nvim_config_deferred_name/channel.txt")" = bet

NVIM_DEV_DIR="$nvim_config_dev_root" \
NVIM_DEV_GIT_BASE="$nvim_config_remote_root" \
NVIM_DEV_GIT_BRANCH=bet \
  "$nvim_config_root/scripts/dev-plugins.sh" sync

for nvim_config_name in "${nvim_config_fleet[@]}"; do
  test "$(git -C "$nvim_config_dev_root/$nvim_config_name" branch --show-current)" = bet
  test "$(cat "$nvim_config_dev_root/$nvim_config_name/channel.txt")" = bet
done
test "$(git -C "$nvim_config_dev_root/$nvim_config_deferred_name" branch --show-current)" = bet

printf '%s\n' dirty > "$nvim_config_dev_root/mcp-buff/dirty.txt"
if NVIM_DEV_DIR="$nvim_config_dev_root" \
  NVIM_DEV_GIT_BASE="$nvim_config_remote_root" \
  NVIM_DEV_GIT_BRANCH=bluff \
  "$nvim_config_root/scripts/dev-plugins.sh" sync; then
  echo "Fleet sync accepted a dirty plugin checkout" >&2
  exit 1
fi
for nvim_config_name in "${nvim_config_fleet[@]}"; do
  test "$(git -C "$nvim_config_dev_root/$nvim_config_name" branch --show-current)" = bet
done
test "$(git -C "$nvim_config_dev_root/$nvim_config_deferred_name" branch --show-current)" = bet

printf '%s\n' "Development plugin channel integration passed"
