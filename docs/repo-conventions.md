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

All public repos in the org (as of 2026-08-03):

- Issue and PR creation is restricted to collaborators
  (`issueCreationPolicy` / `pullRequestCreationPolicy` = `COLLABORATORS_ONLY`,
  the permanent GraphQL repo setting — not the temporary REST
  `interaction-limits` API).
- The `contributors` team has Write (`push`) access on every repo, which is
  the minimum permission level `COLLABORATORS_ONLY` honors (Triage is not
  enough).

Use `scripts/grant-repo-access.sh <repo> --team <slug> [--user <login>]` to
apply both to a repo (new or existing) — it's idempotent, safe to re-run, and
what keeps this policy uniform across the org.

**Exception: `kaappi/community`.** It intentionally leaves issue and PR
creation open to everyone (`ALL`, not `COLLABORATORS_ONLY`) — it's the entry
point for governance, Code of Conduct, and security-policy discussions, which
shouldn't require org membership. Don't run `grant-repo-access.sh` against it
expecting to apply the standard policy.

### Teams

- `contributors` — Write access on every repo; the one `grant-repo-access.sh`
  manages.
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
