#!/usr/bin/env bash
set -euo pipefail

: "${GH_TOKEN:?DEPENDENCY_UPDATE_TOKEN is required for dependency adoption}"
: "${GITHUB_REPOSITORY:?}"
: "${TESTED_COMMIT:?}"
[[ "$TESTED_COMMIT" =~ ^[0-9a-f]{40}$ ]]

api="repos/$GITHUB_REPOSITORY"
owner="${GITHUB_REPOSITORY%%/*}"
pulls="$(gh api --method GET "$api/pulls" \
  -f state=open -f base=bluff -f "head=$owner:agent/dependency-refresh")"
number="$(jq -r --arg sha "$TESTED_COMMIT" --arg repo "$GITHUB_REPOSITORY" '
  [.[] | select(.head.sha == $sha and .head.repo.full_name == $repo and
    .base.ref == "bluff" and .draft == false)] |
  if length == 1 then .[0].number else empty end' <<< "$pulls")"
if [[ -z "$number" ]]; then
  echo "No open dependency PR matches the completed CI commit; nothing to merge."
  exit 0
fi

pull="$(gh api "$api/pulls/$number")"
files="$(gh api --paginate "$api/pulls/$number/files" --slurp)"
if ! jq -e 'add | length == 1 and
  .[0].filename == "lazy-lock.json" and .[0].status == "modified"' \
  <<< "$files" >/dev/null; then
  echo "Dependency auto-merge accepts only a modified lazy-lock.json." >&2
  exit 1
fi

# Inspect data through the API: no checkout, build, or execution of PR code.
base_sha="$(jq -r '.base.sha' <<< "$pull")"
base_lock="$(gh api "$api/contents/lazy-lock.json?ref=$base_sha" --jq .content | base64 --decode)"
head_lock="$(gh api "$api/contents/lazy-lock.json?ref=$TESTED_COMMIT" --jq .content | base64 --decode)"
if ! jq -en --argjson before "$base_lock" --argjson after "$head_lock" '
  ($before | type == "object") and ($after | type == "object") and
  (($before | keys) == ($after | keys)) and
  all($after | keys[]; . as $name |
    ($after[$name] | type == "object") and
    ($after[$name].commit | type == "string" and test("^[0-9a-f]{40}$")) and
    (($before[$name] | del(.commit)) == ($after[$name] | del(.commit))))' >/dev/null; then
  echo "Dependency auto-merge accepts only commit changes to existing pins." >&2
  exit 1
fi

# Strict branch protection remains authoritative. Updating a behind branch
# starts new PR CI; this invocation must not merge that untested new head.
if [[ "$(jq -r '.mergeable_state' <<< "$pull")" == behind ]]; then
  gh api --method PUT "$api/pulls/$number/update-branch" \
    -f "expected_head_sha=$TESTED_COMMIT"
  echo "Updated the dependency branch; waiting for its new CI run."
  exit 0
fi

result="$(gh api --method PUT "$api/pulls/$number/merge" \
  -f merge_method=merge -f "sha=$TESTED_COMMIT")"
jq -e '.merged == true' <<< "$result" >/dev/null
echo "Merged dependency PR #$number at tested commit $TESTED_COMMIT."
