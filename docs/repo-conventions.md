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

## Code style

- **Zig** (core): enforced by `zig fmt`, checked in CI
- **Scheme** (libraries): 2-space indentation, standard R7RS style

## CI

Ecosystem libraries use the reusable workflow from `kaappi/.github`. See
[ci-architecture.md](ci-architecture.md).

## Licensing

All repos use the MIT license. Use the `add-license.scm` script in this repo
to generate LICENSE files.
