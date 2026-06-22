# kaappi/infra

Infrastructure and tooling for the [kaappi](https://github.com/kaappi) GitHub
organization. Scripts are written in Kaappi Scheme.

## Structure

```
scripts/           Kaappi Scheme scripts for org maintenance
  add-license.scm    Generate MIT LICENSE files across repos
  audit-repos.scm    Check repos for required files (LICENSE, README, CI, etc.)
templates/         Templates used by scripts
  LICENSE-MIT        MIT license template with {{YEAR}} placeholder
docs/              Operational documentation
  repo-conventions.md   Standards for all kaappi repos
  ci-architecture.md    How the reusable CI workflow works
  release-process.md    Release workflow for core and ecosystem
labels.json        Standard label definitions for all repos
repos.json         Inventory of org repos and their categories
```

## Running scripts

Scripts require the [Kaappi](https://github.com/kaappi/kaappi) interpreter with
[kaappi-cli](https://github.com/kaappi/kaappi-cli) installed via thottam.

```bash
# Generate LICENSE files for repos that don't have one
kaappi scripts/add-license.scm ../kaappi-cli ../kaappi-json ../kaappi-net

# Audit repos for required files
kaappi scripts/audit-repos.scm
```

## Reusable CI workflow

The shared ecosystem CI workflow lives in
[kaappi/.github](https://github.com/kaappi/.github) at
`.github/workflows/ecosystem-ci.yml`. See [docs/ci-architecture.md](docs/ci-architecture.md)
for usage.

## Related

- [kaappi/.github](https://github.com/kaappi/.github) — org profile, reusable
  workflows, community health files
- [kaappi/ci-images](https://github.com/kaappi/ci-images) — Docker builder images

## License

MIT
