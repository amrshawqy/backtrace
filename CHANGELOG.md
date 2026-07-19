# Changelog

All notable Backtrace changes are documented here. The project follows semantic versioning where practical during early development.

## [0.1.3] - 2026-07-19

### Fixed

- Session selection now changes immediately while the previous conversation is still loading.
- Superseded transcript reads and OpenCode export processes are cancelled promptly.
- Conversation messages render lazily to prevent large previews from blocking the interface when loading completes.

## [0.1.2] - 2026-07-19

### Added

- Persistent System, Light, and Dark appearance selection in Settings.
- A visible, session-local loading state while conversation previews are read.

### Fixed

- Kept session selection responsive while large transcripts load in the background.
- Prevented monochrome assistant marks from becoming invisible in selected rows.

## [0.1.1] - 2026-07-19

### Added

- Official Codex, Claude, Grok, and OpenCode provider marks.
- Full date, time, and timezone tooltips for session timestamps.
- New Backtrace application artwork based on connected session checkpoints.

### Changed

- Session dates use minute precision and never display seconds.
- Removed the last-updated counter from the sidebar footer.
- Improved assistant artwork rendering across light and dark appearances.
- Stripped release executables before signing to remove build-machine paths and compiler symbols.

## [0.1.0] - 2026-07-19

### Added

- Native macOS session browser for Codex, Claude Code, Grok Build, and OpenCode.
- Automatic assistant detection and local session discovery.
- Search, pinning, tracked folders, metadata, bounded conversation previews, and resume-command copying.
- Read-only local architecture with no third-party runtime or package dependencies.
