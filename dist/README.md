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
c485a6b3f73bdf9f0ab4c8b09d58eca9360dafdf8674adb09724c4800fca6692  Backtrace.dmg
2f9f37a96f3f33b43cb24970235c06d09cb775cf258dceaf1fd19000fcba2a13  Backtrace.app/Contents/MacOS/Backtrace
```

Release executables are stripped before signing so compiler metadata does not expose paths from the build machine.

Rebuild both artifacts from the repository root with `make dmg`. Rebuilding may produce a different DMG checksum even when the source is unchanged because filesystem-image metadata can vary.
