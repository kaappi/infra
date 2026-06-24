# CI Architecture

## Overview

Every ecosystem repo has its own `.github/workflows/ci.yml` that runs on push
and PR to `main`. A centralized nightly workflow in `kaappi/.github` tests all
ecosystem packages against the latest kaappi binary.

## Per-repo CI

### Pure Scheme libraries

Repos with no native C code run on `ubuntu-latest` (cheapest runner).

```yaml
# kaappi-json/.github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: mlugg/setup-zig@v2
        with:
          version: 0.16.0
      - name: Build Kaappi
        run: |
          git clone --depth 1 https://github.com/kaappi/kaappi.git /tmp/kaappi
          cd /tmp/kaappi && zig build
      - name: Run tests
        run: |
          for f in tests/*.scm; do
            echo "=== $f ==="
            /tmp/kaappi/zig-out/bin/kaappi --coverage-xml coverage.xml --lib-path lib "$f"
          done
      - name: Upload to Codecov
        if: github.event_name == 'push'
        uses: codecov/codecov-action@v5
        with:
          files: coverage.xml
          fail_ci_if_error: false
```

Pure Scheme repos: kaappi-cli, kaappi-json, kaappi-csv, kaappi-toml,
kaappi-yaml, kaappi-log, kaappi-template, kaappi-test, kaappi-email.

### Native FFI libraries

Repos with C code (`csrc/` + `Makefile`) run on both `ubuntu-latest` and
`macos-latest` via an OS matrix to catch platform-specific FFI issues.

```yaml
# kaappi-crypto/.github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v4
      - uses: mlugg/setup-zig@v2
        with:
          version: 0.16.0
      - name: Install dependencies (Linux)
        if: runner.os == 'Linux'
        run: sudo apt-get update && sudo apt-get install -y libssl-dev
      - name: Build Kaappi
        run: |
          git clone --depth 1 https://github.com/kaappi/kaappi.git /tmp/kaappi
          cd /tmp/kaappi && zig build
      - name: Build native library
        run: make
      - name: Run tests
        run: |
          for f in tests/*.scm; do
            echo "=== $f ==="
            /tmp/kaappi/zig-out/bin/kaappi --coverage-xml coverage.xml --lib-path lib "$f"
          done
        env:
          LD_LIBRARY_PATH: .
          DYLD_LIBRARY_PATH: .
      - name: Upload to Codecov
        if: github.event_name == 'push' && matrix.os == 'ubuntu-latest'
        uses: codecov/codecov-action@v5
        with:
          files: coverage.xml
          fail_ci_if_error: false
```

Native FFI repos: kaappi-net, kaappi-crypto, kaappi-http, kaappi-pg,
kaappi-redis, kaappi-sqlite, kaappi-web.

### Platform-specific dependencies

| Repo | Linux (`apt-get`) | macOS |
|------|-------------------|-------|
| kaappi-net | libssl-dev | (pre-installed) |
| kaappi-crypto | libssl-dev | (pre-installed) |
| kaappi-http | libssl-dev (for kaappi-net dep) | (pre-installed) |
| kaappi-pg | libpq-dev | `brew install postgresql@14` |
| kaappi-redis | libssl-dev (for kaappi-net dep) | (pre-installed) |
| kaappi-sqlite | libsqlite3-dev | (pre-installed) |
| kaappi-web | libssl-dev (for kaappi-net dep) | (pre-installed) |

### Shared library paths

Set both `LD_LIBRARY_PATH` (Linux) and `DYLD_LIBRARY_PATH` (macOS) via the
`env:` block on the test step. The runner ignores the irrelevant variable.

## Coverage

### Procedure-level coverage (ecosystem repos)

Every repo passes `--coverage-xml coverage.xml` to the kaappi invocation.
This writes a Cobertura XML file reporting which exported procedures were
called. The `codecov/codecov-action@v5` step uploads it to Codecov.

Coverage uploads run only on push to `main` (not PRs) and only from one
matrix leg (`ubuntu-latest`) to avoid duplicate reports.

Results at `codecov.io/gh/kaappi/<repo-name>`.

### Zig source coverage (core repo)

The core repo's CI has a separate `coverage` job that runs kcov on unit tests
and the R7RS test suite (Linux only, needs DWARF debug info). The kcov
Cobertura XML is uploaded to Codecov.

## Nightly ecosystem tests

`.github/.github/workflows/nightly.yml` in the `kaappi/.github` repo runs all
16 ecosystem packages against the latest kaappi binary from `main`.

**Schedule:** daily at 05:17 UTC (10:47 AM IST).

**Manual trigger:**
```bash
cd .github
gh workflow run nightly.yml
gh run watch
```

**How it works:**
1. Builds kaappi once and uploads the binary as an artifact
2. Four parallel job groups test all packages:

| Group | Packages | Notes |
|-------|----------|-------|
| `pure-libs` | cli, json, csv, toml, yaml, log, template, test | No native build or services |
| `native-libs` | net, crypto | Need `make`, no services |
| `dep-libs` | email, http, web | Depend on other kaappi-* repos |
| `service-libs` | redis, pg, sqlite | Need Redis or PostgreSQL |

3. Each test runs with `--coverage --coverage-xml` and uploads to Codecov
4. A final `summary` job fails the run if any group had failures

Each group uses `fail-fast: false` so one failure doesn't mask others.

## Adding a new ecosystem repo

1. Create `.github/workflows/ci.yml` using the appropriate template above
2. If pure Scheme: use `ubuntu-latest`, single OS
3. If native FFI: use OS matrix (`ubuntu-latest` + `macos-latest`)
4. Add `--coverage-xml coverage.xml` to the test command
5. Add the Codecov upload step
6. Add a matrix entry to `nightly.yml` in the appropriate group
7. Add the repo to `infra/repos.json`

## Build conventions

- Use plain `zig build` (ReleaseSafe is the default, no need for `-Doptimize`)
- Use `mlugg/setup-zig@v2` with `version: 0.16.0`
- Use `actions/checkout@v4`
- Use `codecov/codecov-action@v5`

## Bumping the Zig version

Update the `version` in each repo's CI workflow. For repos using the nightly
workflow, also update `nightly.yml` in `kaappi/.github`.
