#!/usr/bin/env bash
set -euo pipefail

nvim_config_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
nvim_config_test_root="$(mktemp -d "${TMPDIR:-/tmp}/nvim-config-mise.XXXXXX")"
trap 'rm -rf -- "$nvim_config_test_root"' EXIT

fail() {
  printf 'Mise integration test failed: %s\n' "$*" >&2
  exit 1
}

for nvim_config_command in cc curl env git head mktemp node npm nvim sed sort tar; do
  command -v "$nvim_config_command" >/dev/null 2>&1 || fail "missing command: $nvim_config_command"
done

nvim_config_nvim="$(
  nvim --headless --clean '+lua io.write(vim.v.progpath)' +qa 2>/dev/null
)"
[ -x "$nvim_config_nvim" ] || fail "could not resolve the Neovim executable"
nvim_config_env="$(command -v env)"
nvim_config_node="$(node -p 'process.execPath')"
[ -x "$nvim_config_node" ] || fail "could not resolve the Node executable"
PATH="$(dirname "$nvim_config_node"):$PATH"
nvim_config_treesitter_commit="$(
  sed -nE 's/.*"nvim-treesitter".*"commit": "([0-9a-f]+)".*/\1/p' \
    "$nvim_config_root/lazy-lock.json"
)"
[ -n "$nvim_config_treesitter_commit" ] || fail "could not read the nvim-treesitter lock commit"

if [ -n "${NVIM_TREESITTER_ROOT:-}" ]; then
  nvim_config_treesitter_root="$(cd "$NVIM_TREESITTER_ROOT" && pwd -P)"
  if git -C "$nvim_config_treesitter_root" rev-parse HEAD >/dev/null 2>&1; then
    nvim_config_treesitter_actual="$(git -C "$nvim_config_treesitter_root" rev-parse HEAD)"
    [ "$nvim_config_treesitter_actual" = "$nvim_config_treesitter_commit" ] ||
      fail "NVIM_TREESITTER_ROOT does not match lazy-lock.json"
  fi
else
  nvim_config_treesitter_archive="$nvim_config_test_root/nvim-treesitter.tar.gz"
  curl --fail --location --retry 3 --silent --show-error \
    "https://github.com/nvim-treesitter/nvim-treesitter/archive/$nvim_config_treesitter_commit.tar.gz" \
    --output "$nvim_config_treesitter_archive"
  tar --extract --gzip --file "$nvim_config_treesitter_archive" \
    --directory "$nvim_config_test_root"
  nvim_config_treesitter_root="$nvim_config_test_root/nvim-treesitter-$nvim_config_treesitter_commit"
fi
[ -f "$nvim_config_treesitter_root/lua/nvim-treesitter/init.lua" ] ||
  fail "invalid nvim-treesitter source: $nvim_config_treesitter_root"

if [ -n "${NVIM_TREE_SITTER_CLI:-}" ]; then
  [ -x "$NVIM_TREE_SITTER_CLI" ] || fail "NVIM_TREE_SITTER_CLI is not executable"
  nvim_config_tree_sitter_dir="$(cd "$(dirname "$NVIM_TREE_SITTER_CLI")" && pwd -P)"
  PATH="$nvim_config_tree_sitter_dir:$PATH"
fi

nvim_config_cli_supported=0
if command -v tree-sitter >/dev/null 2>&1; then
  nvim_config_cli_version="$(tree-sitter --version | sed -nE 's/.* ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p')"
  if [ -n "$nvim_config_cli_version" ] &&
    [ "$(printf '%s\n%s\n' 0.26.1 "$nvim_config_cli_version" | sort -V | head -n 1)" = "0.26.1" ]; then
    nvim_config_cli_supported=1
  fi
fi

if [ "$nvim_config_cli_supported" -eq 0 ]; then
  nvim_config_cli_prefix="$nvim_config_test_root/tree-sitter-cli"
  npm install --silent --no-audit --no-fund --no-save \
    --prefix "$nvim_config_cli_prefix" 'tree-sitter-cli@^0.26.1'
  PATH="$nvim_config_cli_prefix/node_modules/.bin:$PATH"
fi
export PATH

mkdir --parents \
  "$nvim_config_test_root/xdg/config" \
  "$nvim_config_test_root/xdg/data" \
  "$nvim_config_test_root/xdg/cache" \
  "$nvim_config_test_root/xdg/state" \
  "$nvim_config_test_root/no-mise-bin"

XDG_CONFIG_HOME="$nvim_config_test_root/xdg/config" \
XDG_DATA_HOME="$nvim_config_test_root/xdg/data" \
XDG_CACHE_HOME="$nvim_config_test_root/xdg/cache" \
XDG_STATE_HOME="$nvim_config_test_root/xdg/state" \
NVIM_TREESITTER_TEST_ROOT="$nvim_config_treesitter_root" \
NVIM_TEST_INSTALL_MISE_PARSERS=1 \
  "$nvim_config_nvim" --headless --clean \
    --cmd 'lua vim.opt.runtimepath:prepend(vim.env.NVIM_TREESITTER_TEST_ROOT)' \
    -l "$nvim_config_root/scripts/ci/test-mise.lua" "$nvim_config_root"

XDG_CONFIG_HOME="$nvim_config_test_root/xdg/config" \
XDG_DATA_HOME="$nvim_config_test_root/xdg/data" \
XDG_CACHE_HOME="$nvim_config_test_root/xdg/cache" \
XDG_STATE_HOME="$nvim_config_test_root/xdg/state" \
NVIM_TREESITTER_TEST_ROOT="$nvim_config_treesitter_root" \
  "$nvim_config_nvim" --headless --clean \
    --cmd 'lua vim.opt.runtimepath:prepend(vim.env.NVIM_TREESITTER_TEST_ROOT)' \
    -l "$nvim_config_root/scripts/ci/test-mise.lua" "$nvim_config_root"

if PATH="$nvim_config_test_root/no-mise-bin" command -v mise >/dev/null 2>&1; then
  fail "the Mise-free PATH unexpectedly contains mise"
fi
"$nvim_config_env" -u SSH_CONNECTION -u SSH_TTY \
  "PATH=$nvim_config_test_root/no-mise-bin" \
  "$nvim_config_nvim" --headless --clean \
  -l "$nvim_config_root/scripts/ci/smoke-core.lua" "$nvim_config_root" native

printf 'Mise-free core startup passed\n'
