#!/usr/bin/env bash
set -euo pipefail

nvim_config_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
nvim_config_test_root="$(mktemp -d "${TMPDIR:-/tmp}/nvim-dev-fleet.XXXXXX")"
trap 'rm -rf -- "$nvim_config_test_root"' EXIT

nvim_config_remote_root="$nvim_config_test_root/remotes"
nvim_config_dev_root="$nvim_config_test_root/dev"
nvim_config_fake_mise="$nvim_config_test_root/mise"
nvim_config_mise_log="$nvim_config_test_root/mise.log"
mkdir --parents "$nvim_config_remote_root"

cat > "$nvim_config_fake_mise" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case " $* " in
  *" exec "*)
    printf '%s\n' exec >> "$NVIM_DEV_MISE_LOG"
    if [ "${NVIM_DEV_MISE_FAIL_EXEC:-0}" = 1 ]; then exit 23; fi
    fake_root=
    for fake_argument in "$@"; do fake_root=$fake_argument; done
    mkdir -p "$fake_root/target/release" "$fake_root/python/.venv/bin"
    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' \
      > "$fake_root/target/release/agent-manager-broker"
    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' \
      > "$fake_root/python/.venv/bin/python"
    chmod +x \
      "$fake_root/target/release/agent-manager-broker" \
      "$fake_root/python/.venv/bin/python"
    ;;
  *)
    printf '%s\n' install >> "$NVIM_DEV_MISE_LOG"
    ;;
esac
EOF
chmod +x "$nvim_config_fake_mise"

nvim_config_fleet=(
  agent-manager.nvimz
  git-panel.nvim
  mcp-buff
  UX-foundation.nvim
  UX-styling.nvim
  UX-chrome.nvim
)
nvim_config_agent_manager_publisher=

for nvim_config_name in "${nvim_config_fleet[@]}"; do
  nvim_config_remote="$nvim_config_remote_root/$nvim_config_name.git"
  nvim_config_publisher="$nvim_config_test_root/publisher-$nvim_config_name"
  git init --bare --quiet --initial-branch=bluff "$nvim_config_remote"
  git init --quiet --initial-branch=bluff "$nvim_config_publisher"
  printf '%s\n' bluff > "$nvim_config_publisher/branch.txt"
  if [ "$nvim_config_name" = agent-manager.nvimz ]; then
    nvim_config_agent_manager_publisher=$nvim_config_publisher
    cat > "$nvim_config_publisher/mise.toml" <<'EOF'
[tools]
python = "3.13.15"
rust = { version = "1.98.0", profile = "minimal" }
uv = "0.12.7"
EOF
    printf '%s\n' /target/ /python/.venv/ > "$nvim_config_publisher/.gitignore"
  fi
  git -C "$nvim_config_publisher" add .
  git -C "$nvim_config_publisher" \
    -c user.name='nvim-config CI' \
    -c user.email='ci@example.invalid' \
    -c commit.gpgsign=false \
    commit --quiet --message='test: seed bluff'
  git -C "$nvim_config_publisher" remote add origin "$nvim_config_remote"
  git -C "$nvim_config_publisher" push --quiet --set-upstream origin bluff
done

NVIM_DEV_DIR="$nvim_config_dev_root" \
NVIM_DEV_GIT_BASE="$nvim_config_remote_root" \
NVIM_DEV_MISE="$nvim_config_fake_mise" \
NVIM_DEV_MISE_LOG="$nvim_config_mise_log" \
  "$nvim_config_root/scripts/dev-plugins.sh" clone

for nvim_config_name in "${nvim_config_fleet[@]}"; do
  test "$(git -C "$nvim_config_dev_root/$nvim_config_name" branch --show-current)" = bluff
  test "$(cat "$nvim_config_dev_root/$nvim_config_name/branch.txt")" = bluff
done
test -x "$nvim_config_dev_root/agent-manager.nvimz/target/release/agent-manager-broker"
test -x "$nvim_config_dev_root/agent-manager.nvimz/python/.venv/bin/python"
test "$(cat "$nvim_config_dev_root/agent-manager.nvimz/target/.nvim-dev-runtime.commit")" = \
  "$(git -C "$nvim_config_dev_root/agent-manager.nvimz" rev-parse HEAD)"
test "$(wc -l < "$nvim_config_mise_log" | tr -d ' ')" = 2

# An already-current fleet still verifies the runtime but does not invoke its
# bootstrap again.
NVIM_DEV_DIR="$nvim_config_dev_root" \
NVIM_DEV_GIT_BASE="$nvim_config_remote_root" \
NVIM_DEV_MISE="$nvim_config_fake_mise" \
NVIM_DEV_MISE_LOG="$nvim_config_mise_log" \
  "$nvim_config_root/scripts/dev-plugins.sh" sync
test "$(wc -l < "$nvim_config_mise_log" | tr -d ' ')" = 2

# Advancing Agent Manager invalidates the commit stamp. A failed build leaves
# the old stamp in place, and the next invocation retries the install/exec
# pair even though Git is already current.
nvim_config_old_stamp="$(
  cat "$nvim_config_dev_root/agent-manager.nvimz/target/.nvim-dev-runtime.commit"
)"
printf '%s\n' updated > "$nvim_config_agent_manager_publisher/runtime.txt"
git -C "$nvim_config_agent_manager_publisher" add runtime.txt
git -C "$nvim_config_agent_manager_publisher" \
  -c user.name='nvim-config CI' \
  -c user.email='ci@example.invalid' \
  -c commit.gpgsign=false \
  commit --quiet --message='test: advance Agent Manager runtime'
git -C "$nvim_config_agent_manager_publisher" push --quiet
if NVIM_DEV_DIR="$nvim_config_dev_root" \
  NVIM_DEV_GIT_BASE="$nvim_config_remote_root" \
  NVIM_DEV_MISE="$nvim_config_fake_mise" \
  NVIM_DEV_MISE_LOG="$nvim_config_mise_log" \
  NVIM_DEV_MISE_FAIL_EXEC=1 \
  "$nvim_config_root/scripts/dev-plugins.sh" sync; then
  echo "Fleet sync accepted a failed Agent Manager bootstrap" >&2
  exit 1
fi
test -f "$nvim_config_dev_root/agent-manager.nvimz/runtime.txt"
test "$(wc -l < "$nvim_config_mise_log" | tr -d ' ')" = 4
test "$(cat "$nvim_config_dev_root/agent-manager.nvimz/target/.nvim-dev-runtime.commit")" = \
  "$nvim_config_old_stamp"

NVIM_DEV_DIR="$nvim_config_dev_root" \
NVIM_DEV_GIT_BASE="$nvim_config_remote_root" \
NVIM_DEV_MISE="$nvim_config_fake_mise" \
NVIM_DEV_MISE_LOG="$nvim_config_mise_log" \
  "$nvim_config_root/scripts/dev-plugins.sh" sync
test "$(wc -l < "$nvim_config_mise_log" | tr -d ' ')" = 6
test "$(cat "$nvim_config_dev_root/agent-manager.nvimz/target/.nvim-dev-runtime.commit")" = \
  "$(git -C "$nvim_config_dev_root/agent-manager.nvimz" rev-parse HEAD)"

printf '%s\n' dirty > "$nvim_config_dev_root/mcp-buff/dirty.txt"
if NVIM_DEV_DIR="$nvim_config_dev_root" \
  NVIM_DEV_GIT_BASE="$nvim_config_remote_root" \
  NVIM_DEV_MISE="$nvim_config_fake_mise" \
  NVIM_DEV_MISE_LOG="$nvim_config_mise_log" \
  "$nvim_config_root/scripts/dev-plugins.sh" sync; then
  echo "Fleet sync accepted a dirty plugin checkout" >&2
  exit 1
fi
for nvim_config_name in "${nvim_config_fleet[@]}"; do
  test "$(git -C "$nvim_config_dev_root/$nvim_config_name" branch --show-current)" = bluff
done

rm -- "$nvim_config_dev_root/mcp-buff/dirty.txt"
git -C "$nvim_config_dev_root/mcp-buff" switch --quiet -c feature/probe
if NVIM_DEV_DIR="$nvim_config_dev_root" \
  NVIM_DEV_GIT_BASE="$nvim_config_remote_root" \
  NVIM_DEV_MISE="$nvim_config_fake_mise" \
  NVIM_DEV_MISE_LOG="$nvim_config_mise_log" \
  "$nvim_config_root/scripts/dev-plugins.sh" sync; then
  echo "Fleet sync switched a checkout away from its explicit branch" >&2
  exit 1
fi
test "$(git -C "$nvim_config_dev_root/mcp-buff" branch --show-current)" = feature/probe

printf '%s\n' "Development plugin bluff integration passed"
