#!/usr/bin/env bash
set -euo pipefail

# Enables GitHub Issues (where not already on) and sets issue creation to
# collaborators-only for kaappi core + the ecosystem library repos.
#
# This uses the permanent GraphQL `issueCreationPolicy` repository setting
# (COLLABORATORS_ONLY / ALL) -- not the REST `interaction-limits` API, which
# is a separate, temporary (max 6 month) restriction. issueCreationPolicy is
# not yet exposed over REST, only GraphQL.
#
# Usage: ./enable-collaborator-issues.sh

ORG="kaappi"
REPOS=(
  kaappi
  kaappi-cli kaappi-json kaappi-csv kaappi-toml kaappi-yaml
  kaappi-log kaappi-template kaappi-test kaappi-bdd kaappi-mpl
  kaappi-net kaappi-crypto kaappi-math kaappi-http kaappi-email
  kaappi-pg kaappi-sqlite kaappi-redis kaappi-web kaappi-examples
)

for repo in "${REPOS[@]}"; do
  echo "== $ORG/$repo =="

  repo_id=$(gh api graphql -f query='
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) { id }
    }' -f owner="$ORG" -f name="$repo" --jq '.data.repository.id' 2>/dev/null) || {
    echo "  skip: could not resolve repository id"
    continue
  }

  gh api graphql -f query='
    mutation($id: ID!) {
      updateRepository(input: {
        repositoryId: $id,
        hasIssuesEnabled: true,
        issueCreationPolicy: COLLABORATORS_ONLY
      }) {
        repository { hasIssuesEnabled issueCreationPolicy }
      }
    }' -f id="$repo_id" \
    --jq '"  hasIssuesEnabled=\(.data.updateRepository.repository.hasIssuesEnabled) issueCreationPolicy=\(.data.updateRepository.repository.issueCreationPolicy)"'
done
