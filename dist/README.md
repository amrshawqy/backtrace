# Backtrace distribution artifacts

This directory intentionally remains under version control so users can inspect and download the exact build described by the repository README.

## Current build

- Version: `0.1.3`
- Build: `5`
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
b393958e24eef9d08801275b1865092118e1403b1685002f20848ba097d157bf  Backtrace.dmg
475409368e1023a3aaddfab7b2bcfb4f51d423e8b8285f516bb0e06ea894fe54  Backtrace.app/Contents/MacOS/Backtrace
```

Release executables are stripped before signing so compiler metadata does not expose paths from the build machine.

Rebuild both artifacts from the repository root with `make dmg`. Rebuilding may produce a different DMG checksum even when the source is unchanged because filesystem-image metadata can vary.
