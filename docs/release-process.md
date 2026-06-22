# Release Process

## Core interpreter (kaappi/kaappi)

Releases are automated via `release.yml`, triggered by pushing a version tag.

### Steps

1. Update `CHANGELOG.md` with the new version section
2. Update `pub const version` in `src/main.zig`
3. Commit: `git commit -m "Release vX.Y.Z"`
4. Tag: `git tag vX.Y.Z`
5. Push: `git push && git push --tags`

### What happens

The release workflow:
1. Builds binaries for 4 platforms (macOS aarch64, Linux x86_64/aarch64/riscv64)
2. Generates SHA256SUMS
3. Extracts the changelog section for the version
4. Creates a GitHub Release with binaries and changelog

## Ecosystem libraries

No formal release process yet. Libraries are used via thottam which clones
from `main`. When versioning is needed:

1. Update the README with the version
2. Tag: `git tag vX.Y.Z`
3. Push the tag

## Docker builder image (ci-images)

Pushed to `ghcr.io/kaappi/builder` automatically on every push to `main`.
Tagged as `latest` and `zig-<version>`.
