#!/usr/bin/env bash
set -euo pipefail

# Opens a repo to outside contributors and puts the guards in place that
# make that safe for a single-maintainer org. Every step is idempotent, so
# re-running against a repo that is already open is a no-op.
#
# What it sets, per repo:
#
#   1. Issue and PR creation policy: ALL (the permanent GraphQL
#      `issueCreationPolicy` / `pullRequestCreationPolicy` settings, not the
#      temporary REST `interaction-limits`). Reverses grant-repo-access.sh.
#   2. Branch protection on the default branch: one approving review,
#      code-owner review required, stale reviews dismissed on push, and the
#      last push must be approved by someone other than the pusher. The
#      existing required status checks are preserved verbatim, and
#      `enforce_admins` is left as it was (off everywhere today): GitHub
#      refuses self-approval, so an enforced rule would lock the sole
#      maintainer out of merging their own PRs.
#   3. Fork PR workflow approval: every outside contributor, not only
#      first-timers. One merged docs PR would otherwise let an account run
#      the full CI matrix (macOS, QEMU) on every later PR unattended.
#   4. Default GITHUB_TOKEN permissions: read, and it may not approve PRs
#      (an approval from a workflow would satisfy rule 2 on its own).
#   5. Private vulnerability reporting: on. The seeded SECURITY.md tells
#      reporters to use it, and the button is absent until this is set.
#   6. Wiki: off (any signed-in user can edit a public repo's wiki by
#      default). Delete head branches on merge: on.
#
# Rule 2 is only as strong as the repo's CODEOWNERS file: without one the
# code-owner requirement is vacuous and any collaborator with Write could
# approve on the maintainer's behalf. The script warns when the file is
# missing on the default branch; seed it with `kaappi add-codeowners.scm
# <repo-path>` and merge that before relying on the rule.
#
# Usage:
#   ./open-repo-access.sh <repo> ...
#   ./open-repo-access.sh                 # all repos in repos.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS_JSON="$SCRIPT_DIR/../repos.json"
ORG="kaappi"

if [[ $# -gt 0 ]]; then
  repos=("$@")
else
  mapfile -t repos < <(jq -r '.[].name' "$REPOS_JSON")
fi

for repo in "${repos[@]}"; do
  echo "== $ORG/$repo =="

  meta=$(gh api "repos/$ORG/$repo" 2>/dev/null) || {
    echo "  skip: could not read repo"
    continue
  }
  branch=$(jq -r '.default_branch' <<< "$meta")
  repo_id=$(jq -r '.node_id' <<< "$meta")

  # 1. Creation policy.
  gh api graphql -f query='
    mutation($id: ID!) {
      updateRepository(input: {
        repositoryId: $id,
        hasIssuesEnabled: true,
        issueCreationPolicy: ALL,
        hasPullRequestsEnabled: true,
        pullRequestCreationPolicy: ALL
      }) {
        repository { issueCreationPolicy pullRequestCreationPolicy }
      }
    }' -f id="$repo_id" \
    --jq '"  creation policy: issues=\(.data.updateRepository.repository.issueCreationPolicy) prs=\(.data.updateRepository.repository.pullRequestCreationPolicy)"'

  # 2. Branch protection. PUT replaces the whole resource, so carry the
  #    existing checks and flags across and change only the review block.
  #    A check with no app_id is sent as -1, which is how the API spells
  #    "any source" (the DCO app registered before app_id existed here).
  existing=$(gh api "repos/$ORG/$repo/branches/$branch/protection" 2>/dev/null) || existing='{}'
  body=$(jq -c '
    {
      required_status_checks: (
        if .required_status_checks then
          { strict: (.required_status_checks.strict // false),
            checks: [ .required_status_checks.checks[]
                      | { context: .context, app_id: (.app_id // -1) } ] }
        else null end),
      enforce_admins: (.enforce_admins.enabled // false),
      required_pull_request_reviews: {
        dismiss_stale_reviews: true,
        require_code_owner_reviews: true,
        required_approving_review_count: 1,
        require_last_push_approval: true
      },
      restrictions: null,
      required_linear_history: (.required_linear_history.enabled // false),
      allow_force_pushes: (.allow_force_pushes.enabled // false),
      allow_deletions: (.allow_deletions.enabled // false),
      required_conversation_resolution: (.required_conversation_resolution.enabled // false),
      lock_branch: (.lock_branch.enabled // false)
    }' <<< "$existing")
  gh api --method PUT "repos/$ORG/$repo/branches/$branch/protection" --input - <<< "$body" \
    --jq '"  protection[\(.url | split("/")[-2])]: reviews=\(.required_pull_request_reviews.required_approving_review_count) codeowners=\(.required_pull_request_reviews.require_code_owner_reviews) dismiss_stale=\(.required_pull_request_reviews.dismiss_stale_reviews) checks=\([.required_status_checks.checks[]?.context] | join(","))"'

  # 3. Fork PR workflow approval.
  gh api --method PUT "repos/$ORG/$repo/actions/permissions/fork-pr-contributor-approval" \
    -f approval_policy=all_external_contributors >/dev/null
  echo "  fork PR workflows: approval for all external contributors"

  # 4. Workflow token.
  gh api --method PUT "repos/$ORG/$repo/actions/permissions/workflow" --input - <<< \
    '{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}' >/dev/null
  echo "  GITHUB_TOKEN: read, cannot approve PRs"

  # 5. Private vulnerability reporting.
  gh api --method PUT "repos/$ORG/$repo/private-vulnerability-reporting" >/dev/null
  echo "  private vulnerability reporting: on"

  # 6. Wiki off, delete branch on merge.
  gh api --method PATCH "repos/$ORG/$repo" -F has_wiki=false -F delete_branch_on_merge=true \
    --jq '"  wiki=\(.has_wiki) delete_branch_on_merge=\(.delete_branch_on_merge)"'

  # CODEOWNERS presence (the file rule 2 depends on).
  if gh api "repos/$ORG/$repo/contents/.github/CODEOWNERS?ref=$branch" >/dev/null 2>&1 \
     || gh api "repos/$ORG/$repo/contents/CODEOWNERS?ref=$branch" >/dev/null 2>&1; then
    echo "  CODEOWNERS: present"
  else
    echo "  WARNING: no CODEOWNERS on $branch -- code-owner review is vacuous until one merges"
  fi
done
