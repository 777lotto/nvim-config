#!/usr/bin/env bash
set -euo pipefail

root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
export GH_TOKEN=fixture GITHUB_REPOSITORY=fixture/config
export TESTED_COMMIT=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

# Mock the API boundary; the production script runs unchanged and cannot
# contact GitHub. No credentials or repository mutations are involved.
gh() {
  local path="$1"
  if [[ "$path" == --method ]]; then
    path="$3"
  elif [[ "$path" == api ]]; then
    shift
    gh "$@"
    return
  elif [[ "$path" == --paginate ]]; then
    path="$2"
  fi
  case "$path" in
    repos/fixture/config/pulls)
      if [[ "$SCENARIO" == stale ]]; then
        printf '[]\n'
      else
        jq -n --arg sha "$TESTED_COMMIT" --arg branch "$REFRESH_BRANCH" '[{number: 1, draft: false,
          head: {sha: $sha, ref: $branch, repo: {full_name: "fixture/config"}}, base: {ref: "bluff"}}]'
      fi
      ;;
    repos/fixture/config/pulls/1)
      jq -n --arg state "$SCENARIO" '{base: {sha: "base"}, mergeable_state: $state}'
      ;;
    repos/fixture/config/pulls/1/files)
      if [[ "$SCENARIO" == extra_file ]]; then
        printf '[[{"filename":"lazy-lock.json","status":"modified"},{"filename":"init.lua","status":"modified"}]]\n'
      else
        printf '[[{"filename":"lazy-lock.json","status":"modified"}]]\n'
      fi
      ;;
    repos/fixture/config/contents/lazy-lock.json\?ref=*)
      local commit=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb branch=bluff
      if [[ "$path" != *ref=base ]]; then
        commit="$TESTED_COMMIT"
        case "$SCENARIO" in
          branch_change) branch=other ;;
          invalid_pin) commit=invalid ;;
          dropped_pin) printf '{}' | base64; return ;;
        esac
      fi
      jq -n --arg commit "$commit" --arg branch "$branch" \
        '{plugin: {branch: $branch, commit: $commit}}' | base64
      ;;
    repos/fixture/config/pulls/1/update-branch)
      [[ "$*" == *"expected_head_sha=$TESTED_COMMIT"* ]]
      printf '{"message":"updated"}\n'
      ;;
    repos/fixture/config/pulls/1/merge)
      [[ "$*" == *"sha=$TESTED_COMMIT"* && "$*" == *merge_method=merge* ]]
      if [[ "$SCENARIO" == protected ]]; then return 1; fi
      printf '{"merged":true}\n'
      ;;
    *) echo "Unexpected API call: $*" >&2; return 1 ;;
  esac
}
export -f gh

# Exercise every publisher accepted by dependency-update.yml, the scheduled
# refresh, and the legacy branch. A single-plugin fixture missed curate-review
# being accepted by refresh but rejected by merge (PR #68).
for target in curate-review agent-manager.nvimz git-panel.nvim mcp-buff \
  UX-chrome.nvim UX-foundation.nvim UX-styling.nvim all ''; do
  export REFRESH_BRANCH="agent/dependency-refresh${target:+-$target}"
  for SCENARIO in clean stale behind extra_file branch_change invalid_pin dropped_pin protected; do
    export SCENARIO
    status=0
    output="$(bash "$root/scripts/ci/merge-dependencies.sh" 2>&1)" || status=$?
    if case "$SCENARIO" in
      clean) [[ "$status" == 0 && "$output" == *'Merged dependency PR'* ]] ;;
      stale) [[ "$status" == 0 && "$output" == *'nothing to merge'* ]] ;;
      behind) [[ "$status" == 0 && "$output" == *'waiting for its new CI run'* ]] ;;
      *) [[ "$status" != 0 && "$output" != *'Merged dependency PR'* ]] ;;
    esac; then
      continue
    fi
    printf 'Dependency merge fixture failed: %s (%s, exit %s)\n%s\n' \
      "$REFRESH_BRANCH" "$SCENARIO" "$status" "$output" >&2
    exit 1
  done
done
export SCENARIO=clean
if GH_TOKEN='' bash "$root/scripts/ci/merge-dependencies.sh" >/dev/null 2>&1; then
  echo "Missing credential was accepted" >&2
  exit 1
fi
for REFRESH_BRANCH in agent/dependency-refresh-untrusted \
  agent/dependency-refresh-curate-review-untrusted agent/dependency-refresh-curate-review/untrusted; do
  if bash "$root/scripts/ci/merge-dependencies.sh" >/dev/null 2>&1; then
    echo "Unknown refresh branch was accepted: $REFRESH_BRANCH" >&2
    exit 1
  fi
done
echo "Dependency merge API fixtures passed"
