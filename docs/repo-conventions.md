# Repo Conventions

Standards that all repositories in the kaappi org should follow.

## Required files

| File | Core | Ecosystem | Infra/Docs | Meta |
|------|:----:|:---------:|:----------:|:----:|
| LICENSE (MIT) | yes | yes | yes | yes |
| README.md | yes | yes | yes | yes |
| kaappi.pkg | - | yes | - | - |
| .github/workflows/ | yes | yes | yes | - |
| CHANGELOG.md | yes | - | - | - |

## Branches

- Default branch: `main`
- No long-lived feature branches — merge promptly

## Commits

- Short imperative subject line (e.g. "Add vector-sort procedure")
- Optional body explaining _why_, not _what_
- Every commit must carry a `Signed-off-by` trailer (DCO — see
  [developercertificate.org](https://developercertificate.org/)), added with
  `git commit -s`. Enforced by the [DCO2](https://github.com/cncf/dco2)
  GitHub App, installed org-wide. `templates/dco.yml` is the app's config
  template; seed a repo that doesn't have its own copy with
  `scripts/add-dco-config.scm <repo-path> ...` (never overwrites an existing
  `.github/dco.yml`).

## Code style

- **Zig** (core): enforced by `zig fmt`, checked in CI
- **Scheme** (libraries): 2-space indentation, standard R7RS style

## Community files

`CODE_OF_CONDUCT.md` and `SECURITY.md` are canonically maintained in
[kaappi/community](https://github.com/kaappi/community). Use
`scripts/add-community-files.scm <repo-path> ...` to seed a repo that doesn't
have them yet — it never overwrites an existing file, so a repo with its own
security model (e.g. `kaappi/kaappi`'s sandbox/FFI threat model) keeps its
customized `SECURITY.md`.

Org-wide governance and the maintainer list also live in
[kaappi/community](https://github.com/kaappi/community) (`GOVERNANCE.md`,
`MAINTAINERS.md`) rather than in any individual repo.

## Access control

All public repos in the org (as of 2026-09-10):

- **Issue and PR creation is open to everyone** (`issueCreationPolicy` /
  `pullRequestCreationPolicy` = `ALL`, the permanent GraphQL repo setting —
  not the temporary REST `interaction-limits` API). No org membership is
  needed to file an issue or open a PR from a fork.
- **Merging needs the maintainer.** Branch protection on the default branch
  requires one approving review and a code-owner review, dismisses stale
  reviews when new commits are pushed, and requires the last push to be
  approved by someone other than the pusher. `.github/CODEOWNERS` routes
  every path to the maintainer, so "one approval" cannot be satisfied by
  another collaborator. `enforce_admins` stays off: GitHub refuses
  self-approval, so the sole maintainer merges their own PRs through the
  admin bypass.
- **CI on fork PRs waits for maintainer approval** for every outside
  contributor, not only first-timers. The default `GITHUB_TOKEN` is
  read-only and cannot approve PRs.
- **Private vulnerability reporting is on** (the seeded `SECURITY.md`
  tells reporters to use it), the wiki is off, and head branches are
  deleted on merge.

`scripts/open-repo-access.sh <repo> ...` applies all of the above to a repo
(new or existing) and is idempotent; `kaappi scripts/add-codeowners.scm
<repo-path>` seeds the CODEOWNERS file the review rule depends on. The
previous policy (`COLLABORATORS_ONLY`, in force 2026-08-03 to 2026-09-10)
is what `scripts/grant-repo-access.sh` sets; it is kept for re-closing a
repo, not for routine use.

Why open: the project has one maintainer and cannot carry every change
itself. Why the guards: opening the door is safe only when nothing merges
without that maintainer and no outside account can run the CI matrix
unattended. The contribution rules that protect review time (tests run
first, explain the change, disclose AI assistance, one change per PR, a
KEP before anything large) live in each repo's `CONTRIBUTING.md` and in
[kaappi/community](https://github.com/kaappi/community).

### Teams

- `contributors` — Write access on repos where it was granted under the
  old policy. Write is no longer needed to contribute, and it lets a member
  approve reviews, which CODEOWNERS is what neutralizes. Grant it only to
  someone who is meant to merge.
- `release`, `admin` — created for future use, currently empty with no repo
  permissions granted. Not yet wired into any process; see
  [kaappi/community's GOVERNANCE.md](https://github.com/kaappi/community/blob/main/GOVERNANCE.md)
  before assuming a role for them.

## CI

Ecosystem libraries use the reusable workflow from `kaappi/.github`. See
[ci-architecture.md](ci-architecture.md).

## Licensing

All repos use the MIT license. Use the `add-license.scm` script in this repo
to generate LICENSE files.
