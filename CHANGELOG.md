# Changelog

All notable Backtrace changes are documented here. The project follows semantic versioning where practical during early development.

## [Unreleased]

## [0.2.0] - 2026-08-12

### Added

- Multiple Claude Code config directories in one list, so work and personal histories are searchable together. `~/.claude` and whatever `CLAUDE_CONFIG_DIR` points at are read by default; every other profile is added explicitly in Settings.
- A Settings section listing each config directory with its origin and session count, plus add, remove, and restore. Directories are added by typing a path, which is checked as it is typed and resolves `~`, bare names, quotes, and a trailing `projects` folder.
- A "Claude Code Profiles" sidebar section, shown once a second config directory exists, with per-profile session counts.
- A "Claude Code profile" field in session details for sessions outside the default directory.

### Fixed

- Sessions no longer disappear when `CLAUDE_CONFIG_DIR` moves the config directory. The variable is now read from an interactive login shell, including `.zprofile` and `.zshrc`, when the app's own environment does not contain it.
- Resume commands for sessions outside the default config directory now set `CLAUDE_CONFIG_DIR`, so Claude Code can find the session instead of reporting it as missing.
- `CODEX_HOME` is resolved through the interactive login shell as well, for the same reason.
- Adding, removing, or restoring a Claude Code config directory during a scan now queues a follow-up scan instead of leaving the UI stale.
- Claude Code sessions with the same session ID in different config directories remain distinct, preserving the correct profile and resume command.

## [0.1.4] - 2026-07-23

### Added

- Persistent, color-coded tags with multiple tags per session.
- Tag chips in session rows and details, tag-aware search, and sidebar filters with session counts.
- Tag creation, assignment, renaming, and deletion without modifying assistant history files.

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
