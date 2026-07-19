# Contributing to Backtrace

Thank you for helping improve Backtrace. The project aims to remain native, lightweight, private, and easy to audit.

## Before starting

- Search existing issues before opening a new one.
- Use a feature request for behavior changes that affect the UI or provider contract.
- For a new assistant integration, describe its executable name, local history layout, and documented resume command.
- Do not post private transcripts, credentials, customer data, or unredacted local paths.

## Development setup

Requirements are macOS 14 or later and Xcode 16 or later.

```bash
git clone https://github.com/amrshawqy/backtrace.git
cd backtrace
make test
make app
```

Run the debug executable during development with:

```bash
swift run Backtrace
```

## Design principles

Changes should preserve these constraints:

1. **Local and read-only.** Never modify an assistant's session store.
2. **Private by default.** Do not add telemetry, analytics, remote sync, or transcript uploads.
3. **Native and light.** Prefer SwiftUI, Foundation, and system frameworks over dependencies.
4. **Bounded work.** Avoid loading entire large histories when metadata or a preview is enough.
5. **Resilient adapters.** Session formats are external and may contain missing or new fields.
6. **Safe commands.** Shell-quote project paths and session identifiers used in copied commands.

## Adding or changing a provider

- Keep provider-specific parsing inside `Sources/Backtrace/Services/Providers`.
- Add deterministic, synthetic fixtures to `Tests/BacktraceTests`.
- Cover the session ID, title, project path, dates, and resume command.
- Redact all real data before turning it into a fixture.
- Keep preview parsing bounded and ignore events that are not conversation messages.

## Pull requests

Before submitting:

```bash
make test
make app
codesign --verify --deep --strict dist/Backtrace.app
```

Keep pull requests focused. Explain the user-visible result, implementation tradeoffs, and how the change was verified. Include screenshots for visual changes when practical.

Release artifacts in `dist/` are maintained with tagged releases. Contributors normally should not rebuild or commit them unless the pull request is explicitly preparing a release.

By contributing, you agree that your contribution is licensed under the project's MIT License.
