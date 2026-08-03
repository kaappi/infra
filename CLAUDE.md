# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Org-wide infrastructure and tooling for the `kaappi` GitHub org: repo-maintenance
scripts, the Claude Code dev harness (skills/agents/hooks) shared across all
`kaappi-*` repos, and operational docs describing conventions that live outside
any single repo. This repo is also a Claude Code **plugin** (`.claude-plugin/`),
installed as `kaappi-dev` — its `skills/`, `agents/`, and `hooks/` are available
to Claude Code sessions in every repo, not just this one.

This directory sits inside the multi-repo `kaappi/` workspace (see the parent
`../CLAUDE.md`) but is its own independent git repo.

## Running the scripts

Scheme scripts need the `kaappi` interpreter with `kaappi-cli` on the lib path
(via thottam). Bash scripts need the `gh` CLI, authenticated as an account with
org admin rights (required for repo-level issue/PR policy changes).

```bash
# Generate LICENSE files for repos that don't have one
kaappi scripts/add-license.scm ../kaappi-cli ../kaappi-json ../kaappi-net

# Audit repos for required files (per repos.json "expect" lists)
kaappi scripts/audit-repos.scm [base-dir]   # base-dir defaults to ..

# Apply collaborators-only issue/PR policy + grant a team/user write access
./scripts/grant-repo-access.sh <repo> [--team <slug>]... [--user <login>]... [--permission <level>]

# Claude-assisted issue triage / PR review across repos.json (or specific repos)
./scripts/triage-issues.sh [repo ...]
./scripts/review-prs.sh [repo ...]
```

There is no test suite or build step in this repo — `audit-repos.scm`'s exit
code (0 = all expected files present) is the closest thing to a check, and is
safe to run any time.

## Architecture

### Two audiences, two languages

- **Scheme** (`scripts/*.scm`) — read-only or additive operations on the local
  checkouts under `../` (generating files, auditing structure). Run through
  the `kaappi` interpreter itself, so they double as dogfooding.
- **Bash + `gh`** (`scripts/*.sh`) — GitHub API operations (repo settings,
  team/collaborator permissions, issue/PR automation) that need `gh api graphql`
  or REST calls Scheme has no client for.

### The `claude -p` pattern (triage-issues.sh, review-prs.sh)

Both automation scripts follow the same shape: iterate repos from `repos.json`,
find untouched issues/PRs via `gh`, then spawn `claude -p "<prompt>" --allowedTools "<scoped list>" --permission-mode dontAsk` per item. Two things make this
safe to run unattended:

- **Idempotency via markers, not state files.** `review-prs.sh` tags its first
  comment line with `<!-- claude-review: sha=<head_sha> -->` and greps existing
  comments for that marker before reviewing — so it only re-reviews PRs that
  got new commits, with no external state to go stale. `triage-issues.sh`
  instead scopes its `gh issue list` query to `is:open no:label`, which is
  naturally idempotent (a labeled issue drops out of the query).
- **`--allowedTools` is the actual security boundary**, not the prompt.
  `triage-issues.sh` never grants `gh issue close` or file-editing tools;
  `review-prs.sh` never grants `gh pr review` (approve/request-changes) or
  `gh pr merge` — only `gh pr comment`. The prompts also explicitly tell the
  spawned Claude to treat the issue/PR body as untrusted data. Both boundaries
  matter: the allowedTools list is what actually prevents an adversarial issue
  body from taking a destructive action.

If you add a new automation script in this family, follow both patterns:
scope `--allowedTools` to the minimum needed, and give it an idempotency check
that doesn't require persisted state.

### Config-driven, not hardcoded

`repos.json` (org inventory + per-repo expected-files list, keyed by category:
`core`/`ecosystem`/`tooling`/`infra`/`docs`/`meta`) and `labels.json` (standard
label set) are the two sources of truth consumed by the scripts above. When
onboarding a new repo, add it to `repos.json` rather than editing script logic.

Note: several skills (`ci-check`, `pull-all`, `repo-status`, `test-ecosystem`)
hardcode their own repo lists in bash `for` loops rather than reading
`repos.json`, and `docs/ci-architecture.md`'s nightly-workflow table lists
package counts that predate later additions (`kaappi-bdd`, `kaappi-mpl`,
`kaappi-math`). These lists drift independently — when adding a new repo,
check whether it needs adding to `repos.json` *and* to the affected skills'
hardcoded loops, per the "Adding a new ecosystem repo" checklist in
`docs/ci-architecture.md`.

### The plugin surface (`skills/`, `agents/`, `hooks/`)

- `skills/*/SKILL.md` — slash commands available in any repo where this
  plugin is installed (`/repo-status`, `/pull-all`, `/test-ecosystem`,
  `/coverage-report`, `/ci-check`, `/release-ecosystem`, `/new-ecosystem-lib`).
  Each is a plain instructions file the agent executes, not a script.
- `agents/ecosystem-reviewer.md` — a subagent for reviewing `kaappi-*` library
  code against ecosystem conventions (R7RS style, `.sld` export correctness,
  `kaappi.pkg` fields, FFI type signatures against `ffi.zig`'s supported set).
- `hooks/bash-guard.sh` — a `PreToolUse` hook (wired via `hooks/hooks.json`)
  that blocks specific destructive Bash patterns (`rm -rf /`, `sudo`,
  `git push --force`, `git tag -d`, `git reset --hard`) org-wide, independent
  of whatever guard the target repo's own `.claude/hooks/` might have.

## Key docs

- `docs/repo-conventions.md` — required files per repo category, branch/commit
  conventions, and the access-control policy (`COLLABORATORS_ONLY` issue/PR
  creation + `contributors` team at Write access — Triage is *not* sufficient
  for GitHub to honor that policy, which is why `grant-repo-access.sh` defaults
  `--permission` to `push`).
- `docs/ci-architecture.md` — per-repo CI templates (pure Scheme vs. native FFI
  matrix), the nightly cross-ecosystem test workflow (lives in `kaappi/.github`,
  not here), and the steps for wiring up a new repo's CI.
- `docs/release-process.md` — release steps for the core interpreter, ecosystem
  libraries, and the `ci-images` Docker image.
