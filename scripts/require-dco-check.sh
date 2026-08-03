#!/usr/bin/env bash
set -euo pipefail

# Ensures the "DCO" status check (from the DCO2 GitHub App -- see
# github.com/cncf/dco2) is required on a repo's default branch.
#
# Repos with no branch protection yet get minimal protection: just the DCO
# check, nothing else (no required reviews, no admin enforcement, no
# restrictions) -- this only adds the DCO gate, it doesn't change how merges
# work otherwise.
#
# Repos that already have branch protection (e.g. kaappi/kaappi's CI-matrix
# required checks) get "DCO" merged into their existing required-checks list
# via the required_status_checks sub-resource, which updates only that field
# and leaves reviews/restrictions/everything else untouched.
#
# Safe to re-run: skips a repo that already requires the check.
#
# Usage:
#   ./require-dco-check.sh <repo> ...
#   ./require-dco-check.sh                # all repos in repos.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS_JSON="$SCRIPT_DIR/../repos.json"
ORG="kaappi"
CHECK="DCO"

if [[ $# -gt 0 ]]; then
  repos=("$@")
else
  mapfile -t repos < <(jq -r '.[].name' "$REPOS_JSON")
fi

for repo in "${repos[@]}"; do
  echo "== $ORG/$repo =="

  branch=$(gh api "repos/$ORG/$repo" --jq '.default_branch' 2>/dev/null) || {
    echo "  skip: could not read repo"
    continue
  }

  existing=$(gh api "repos/$ORG/$repo/branches/$branch/protection/required_status_checks" 2>/dev/null) || existing=""

  if [[ -z "$existing" ]]; then
    gh api --method PUT "repos/$ORG/$repo/branches/$branch/protection" --input - <<EOF >/dev/null
{
  "required_status_checks": {"strict": false, "contexts": ["$CHECK"]},
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null
}
EOF
    echo "  created branch protection, required: $CHECK"
  elif echo "$existing" | jq -e --arg c "$CHECK" '.contexts | index($c)' >/dev/null; then
    echo "  already required: $CHECK"
  else
    body=$(echo "$existing" | jq -c --arg c "$CHECK" '{strict: .strict, contexts: (.contexts + [$c])}')
    gh api --method PATCH "repos/$ORG/$repo/branches/$branch/protection/required_status_checks" \
      --input - <<< "$body" >/dev/null
    echo "  added to existing required checks: $CHECK"
  fi
done
