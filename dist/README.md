# Backtrace distribution artifacts

This directory intentionally remains under version control so users can inspect and download the exact build described by the repository README.

## Current build

- Version: `0.2.0`
- Build: `7`
- Minimum macOS: `14.0`
- Architecture: Apple Silicon (`arm64`)
- Signing: ad-hoc
- Apple notarization: not notarized

| Artifact | Purpose |
| --- | --- |
| `Backtrace.dmg` | Recommended drag-to-install disk image |
| `Backtrace.app` | Uncompressed macOS application bundle |

SHA-256:

```text
5ae6c51cefe6908538b615ae3bfcde85158977c17cfce571513c4c1c78903c67  Backtrace.dmg
b6ca2dbb71e824ae6c47503c37f88d9cdc58999eb0fb89656f96e15b5106c61c  Backtrace.app/Contents/MacOS/Backtrace
```

Release executables are stripped before signing so compiler metadata does not expose paths from the build machine.

Rebuild both artifacts from the repository root with `make dmg`. Rebuilding may produce a different DMG checksum even when the source is unchanged because filesystem-image metadata can vary.
