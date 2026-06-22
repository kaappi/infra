# CI Architecture

## Overview

Ecosystem libraries share a reusable GitHub Actions workflow defined in the
[kaappi/.github](https://github.com/kaappi/.github) repository at
`.github/workflows/ecosystem-ci.yml`.

Each ecosystem repo calls it with repo-specific inputs, reducing its `ci.yml`
to ~15 lines.

## Reusable workflow inputs

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `zig-version` | string | `"0.16.0"` | Zig toolchain version |
| `has-native-build` | boolean | `false` | Run `make` in the repo root |
| `dependencies` | string | `""` | Space-separated kaappi-* repos to clone |
| `test-files` | string | `""` | Space-separated .scm test files |
| `test-expression` | string | `""` | Inline Scheme expression (smoke tests) |
| `service` | string | `""` | `redis` or `postgresql` |

Dependencies are cloned to `/tmp/<name>`. If a dependency has a Makefile, it is
built automatically.

## Example: pure Scheme library

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
    uses: kaappi/.github/.github/workflows/ecosystem-ci.yml@main
    with:
      test-files: tests/test-json.scm
```

## Example: native library with dependencies and a service

```yaml
# kaappi-redis/.github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  test:
    uses: kaappi/.github/.github/workflows/ecosystem-ci.yml@main
    with:
      has-native-build: true
      dependencies: kaappi-net
      test-files: tests/test-resp.scm tests/test-commands.scm
      service: redis
```

## What the workflow does

1. Checks out the calling repo
2. Installs Zig
3. Clones and builds `kaappi/kaappi` from source
4. Clones each dependency; runs `make` if a Makefile exists
5. Runs `make` in the repo root (if `has-native-build`)
6. Starts a service (if `service` is set)
7. Constructs `--lib-path` and `DYLD_LIBRARY_PATH`/`LD_LIBRARY_PATH` from the
   dependency list
8. Runs each test file with the kaappi interpreter

## Bumping the Zig version

Update the `zig-version` default in `ecosystem-ci.yml`. All repos that don't
override the input pick up the new version automatically.

## Adding a new ecosystem repo

1. Create `.github/workflows/ci.yml` calling the reusable workflow
2. Set `test-files` to your test file paths
3. Set `dependencies` if your library depends on other kaappi-* packages
4. Set `has-native-build: true` if you have a Makefile
5. Set `service` if tests need Redis or PostgreSQL
