# ADR-0015: Gitleaks for Secret Detection

**Date**: 2026-04-08
**Status**: Accepted
**Confidence**: High (direct evidence from commit history)

## Context

Secret detection was previously handled by `detect-secrets`, which maintains a `.secrets.baseline` file of known false positives. While effective, `detect-secrets` has significant drawbacks in this repository:

- Slow on large repos — scans all content on each run
- The baseline file requires ongoing maintenance as new "secrets" (false positives) are introduced
- Poor integration with chezmoi template syntax (`.tmpl` files contain template variables that trigger false positives constantly)
- Python dependency that adds complexity to the pre-commit setup

Commit evidence: `chore: replace detect-secrets with gitleaks (#169)`

## Decision

Replace `detect-secrets` with `gitleaks` for secret detection:

- `gitleaks` configured via `.gitleaks.toml` with custom rules and allowlists
- Runs as a pre-commit hook via `gitleaks protect --staged`
- Handles chezmoi template variables and known false positives via allowlist in `.gitleaks.toml`
- Removes `.secrets.baseline` maintenance burden

## Consequences

**Positive:**
- Faster scanning (Rust-based, designed for git repos)
- Configuration via `.gitleaks.toml` is more readable than JSON baseline
- Better support for chezmoi template allowlisting
- No Python runtime dependency for secret scanning

**Negative:**
- Migration required allowlisting historical false positives in `.gitleaks.toml`
- Team members must have gitleaks installed (managed via mise/Brewfile)

## Related

- ADR-0010: Tiered Test Execution (pre-commit is the first tier)
- `docs/prds/project-overview.md` FR-007: Secret management
