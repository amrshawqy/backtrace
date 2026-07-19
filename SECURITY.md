# Security policy

Backtrace reads local AI-assistant histories, which may contain source code, prompts, filesystem paths, credentials, and other sensitive information. Security and privacy reports are taken seriously.

## Reporting a vulnerability

Do not open a public issue for a vulnerability or attach a real session transcript.

Use GitHub's private vulnerability reporting flow:

<https://github.com/amrshawqy/backtrace/security/advisories/new>

Include:

- the affected Backtrace version and macOS version;
- clear reproduction steps;
- the security or privacy impact;
- a minimal synthetic proof of concept; and
- any suggested mitigation.

Remove credentials, private source code, real session IDs, usernames, and customer data. The maintainer will review reports on a best-effort basis and coordinate disclosure when a fix is available.

## Supported versions

Security fixes are applied to the latest release and the `main` branch. Older development builds are not supported.

## Distribution note

The current downloadable community build is ad-hoc signed and not Apple-notarized. Verify its published SHA-256 checksum before overriding Gatekeeper. A successful checksum confirms the downloaded bytes match the published artifact; it is not a substitute for reviewing or trusting the source.
