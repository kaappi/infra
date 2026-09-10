#!/usr/bin/env bash
set -euo pipefail

# Makes a repo's CI required on its default branch, so a PR cannot merge
# with a red (or missing) CI run. Companion to open-repo-access.sh, which
# adds the review rules but leaves the required-checks list as it finds it
# -- and on most ecosystem repos that list was just "DCO".
#
# The contexts to require are taken from the jobs of the repo's most recent
# workflow run triggered by a pull_request event. That is deliberately not
# "the checks on main": a push-only job (a deploy, a benchmark upload) that
# never reports on a PR would sit at "Expected -- waiting for status" and
# make every PR permanently unmergeable. Pass `--check <name>` to name the
# contexts yourself instead (repeatable); the derived list is skipped then.
#
# Merges into the existing required checks via the required_status_checks
# sub-resource, so reviews, admin enforcement, and everything else stay as
# they are. Safe to re-run.
#
# Usage:
#   ./require-ci-checks.sh <repo> [--check <context>]...
#   ./require-ci-checks.sh                 # all repos in repos.json, derived

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS_JSON="$SCRIPT_DIR/../repos.json"
ORG="kaappi"

repos=()
checks=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) checks+=("$2"); shift 2 ;;
    *) repos+=("$1"); shift ;;
  esac
done
if [[ ${#repos[@]} -eq 0 ]]; then
  if [[ ${#checks[@]} -gt 0 ]]; then
    echo "--check needs a repo" >&2; exit 1
  fi
  mapfile -t repos < <(jq -r '.[].name' "$REPOS_JSON")
fi

for repo in "${repos[@]}"; do
  echo "== $ORG/$repo =="

  branch=$(gh api "repos/$ORG/$repo" --jq '.default_branch' 2>/dev/null) || {
    echo "  skip: could not read repo"
    continue
  }

  if [[ ${#checks[@]} -gt 0 ]]; then
    wanted=("${checks[@]}")
  else
    run_id=$(gh run list --repo "$ORG/$repo" --event pull_request --limit 1 \
      --json databaseId --jq '.[0].databaseId // empty' 2>/dev/null || true)
    if [[ -z "$run_id" ]]; then
      echo "  skip: no pull_request workflow run to derive contexts from (use --check)"
      continue
    fi
    mapfile -t wanted < <(gh api "repos/$ORG/$repo/actions/runs/$run_id/jobs" \
      --jq '.jobs[] | select(.conclusion != "skipped") | .name')
    if [[ ${#wanted[@]} -eq 0 ]]; then
      echo "  skip: latest pull_request run $run_id reported no jobs"
      continue
    fi
  fi

  existing=$(gh api "repos/$ORG/$repo/branches/$branch/protection/required_status_checks" 2>/dev/null) || {
    echo "  skip: no branch protection yet (run open-repo-access.sh / require-dco-check.sh first)"
    continue
  }

  merged=$(jq -c --argjson add "$(printf '%s\n' "${wanted[@]}" | jq -R . | jq -s .)" \
    '{strict: .strict, contexts: ((.contexts + $add) | unique)}' <<< "$existing")
  added=$(jq -r --argjson add "$(printf '%s\n' "${wanted[@]}" | jq -R . | jq -s .)" \
    '$add - .contexts | join(", ")' <<< "$existing")

  if [[ -z "$added" ]]; then
    echo "  already required: $(jq -r '.contexts | join(", ")' <<< "$existing")"
    continue
  fi
  gh api --method PATCH "repos/$ORG/$repo/branches/$branch/protection/required_status_checks" \
    --input - <<< "$merged" >/dev/null
  echo "  added: $added"
  echo "  now required: $(jq -r '.contexts | join(", ")' <<< "$merged")"
done
