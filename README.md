# kaappi/infra

Infrastructure and tooling for the [kaappi](https://github.com/kaappi) GitHub
organization. Repo-maintenance scripts are written in Kaappi Scheme;
GitHub API automation (access control, triage, review) is written in bash
against the `gh` CLI.

## Structure

```
scripts/           Org maintenance and automation scripts
  add-license.scm             Generate MIT LICENSE files across repos (Scheme)
  add-community-files.scm     Seed CODE_OF_CONDUCT.md/SECURITY.md from kaappi/community (Scheme)
  add-dco-config.scm           Seed .github/dco.yml (DCO2 app config) across repos (Scheme)
  audit-repos.scm              Check repos for required files (Scheme)
  grant-repo-access.sh         Set collaborators-only issue/PR policy + grant team/user access
  enable-collaborator-issues.sh  Superseded by grant-repo-access.sh; kept for reference
  require-dco-check.sh         Require the DCO status check on a repo's branch protection
  triage-issues.sh             Claude-assisted issue labeling and duplicate detection
  review-prs.sh                Claude-assisted PR review comments
templates/         Templates used by scripts
  LICENSE-MIT        MIT license template with {{YEAR}} placeholder
  dco.yml            DCO2 GitHub App config template
docs/              Operational documentation
  repo-conventions.md   Standards for all kaappi repos
  ci-architecture.md    How the reusable CI workflow works
  release-process.md    Release workflow for core and ecosystem
labels.json        Standard label definitions for all repos (used by triage-issues.sh)
repos.json         Inventory of org repos and their categories (used by triage-issues.sh, review-prs.sh)
```

## Running scripts

Scheme scripts require the [Kaappi](https://github.com/kaappi/kaappi) interpreter with
[kaappi-cli](https://github.com/kaappi/kaappi-cli) installed via thottam. Bash
scripts require the [`gh` CLI](https://cli.github.com/), authenticated with an
account that has org admin rights (needed to update repo-level issue/PR
creation policy).

```bash
# Generate LICENSE files for repos that don't have one
kaappi scripts/add-license.scm ../kaappi-cli ../kaappi-json ../kaappi-net

# Audit repos for required files
kaappi scripts/audit-repos.scm

# Restrict issue/PR creation to collaborators and grant a team write access
./scripts/grant-repo-access.sh kaappi-json --team contributors

# Seed DCO2 app config and require its check on branch protection
kaappi scripts/add-dco-config.scm ../kaappi-json
./scripts/require-dco-check.sh kaappi-json

# Claude-assisted issue triage / PR review across all repos in repos.json
./scripts/triage-issues.sh
./scripts/review-prs.sh
```

See [docs/repo-conventions.md](docs/repo-conventions.md) for the org's
access-control policy.

## Reusable CI workflow

The shared ecosystem CI workflow lives in
[kaappi/.github](https://github.com/kaappi/.github) at
`.github/workflows/ecosystem-ci.yml`. See [docs/ci-architecture.md](docs/ci-architecture.md)
for usage.

## Related

- [kaappi/community](https://github.com/kaappi/community) — governance,
  maintainers, and the canonical `CODE_OF_CONDUCT.md`/`SECURITY.md` this repo
  seeds into others
- [kaappi/.github](https://github.com/kaappi/.github) — org profile, reusable
  workflows, community health file defaults
- [kaappi/ci-images](https://github.com/kaappi/ci-images) — Docker builder images

## License

MIT
