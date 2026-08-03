#!/usr/bin/env bash
set -euo pipefail

# Restricts issue and pull request creation on a single repo to collaborators
# only, then grants Write access to selected teams and/or members so they can
# actually create issues/PRs under that restriction. Triage-level access is
# NOT enough -- GitHub's COLLABORATORS_ONLY policy checks for Write.
#
# Uses the permanent GraphQL `issueCreationPolicy` / `pullRequestCreationPolicy`
# repository settings (COLLABORATORS_ONLY / ALL) -- not the REST
# `interaction-limits` API, which is a separate, temporary (max 6 month)
# restriction. Safe to re-run: every step is idempotent.
#
# Usage:
#   ./grant-repo-access.sh <repo> [--team <slug>]... [--user <login>]... [--permission <level>]
#
# --permission accepts pull/triage/push/maintain/admin (default: push, i.e.
# "Write" in the GitHub UI -- the minimum level COLLABORATORS_ONLY honors).
#
# Examples:
#   ./grant-repo-access.sh kaappi --team contributors --user mbaiju
#   ./grant-repo-access.sh kaappi-json --user someuser --permission maintain
#   ./grant-repo-access.sh kaappi-net   # just apply the collaborators-only policy

ORG="kaappi"
PERMISSION="push"
TEAMS=()
USERS=()

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <repo> [--team <slug>]... [--user <login>]... [--permission <level>]" >&2
  exit 1
fi

REPO="$1"; shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --team) TEAMS+=("$2"); shift 2 ;;
    --user) USERS+=("$2"); shift 2 ;;
    --permission) PERMISSION="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

echo "== $ORG/$REPO =="

repo_id=$(gh api graphql -f query='
  query($owner: String!, $name: String!) {
    repository(owner: $owner, name: $name) { id }
  }' -f owner="$ORG" -f name="$REPO" --jq '.data.repository.id')

gh api graphql -f query='
  mutation($id: ID!) {
    updateRepository(input: {
      repositoryId: $id,
      hasIssuesEnabled: true,
      issueCreationPolicy: COLLABORATORS_ONLY,
      hasPullRequestsEnabled: true,
      pullRequestCreationPolicy: COLLABORATORS_ONLY
    }) {
      repository {
        hasIssuesEnabled issueCreationPolicy
        hasPullRequestsEnabled pullRequestCreationPolicy
      }
    }
  }' -f id="$repo_id" \
  --jq '"  issues: enabled=\(.data.updateRepository.repository.hasIssuesEnabled) policy=\(.data.updateRepository.repository.issueCreationPolicy)\n  prs:    enabled=\(.data.updateRepository.repository.hasPullRequestsEnabled) policy=\(.data.updateRepository.repository.pullRequestCreationPolicy)"'

if [[ ${#TEAMS[@]} -gt 0 ]]; then
  for team in "${TEAMS[@]}"; do
    gh api --method PUT "orgs/$ORG/teams/$team/repos/$ORG/$REPO" -f permission="$PERMISSION"
    echo "  team '$team' -> $PERMISSION"
  done
fi

if [[ ${#USERS[@]} -gt 0 ]]; then
  for user in "${USERS[@]}"; do
    gh api --method PUT "repos/$ORG/$REPO/collaborators/$user" -f permission="$PERMISSION"
    echo "  user '$user' -> $PERMISSION"
  done
fi
