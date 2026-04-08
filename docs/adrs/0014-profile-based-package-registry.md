# ADR-0014: Profile-Based Package Registry

**Date**: 2026-04-08
**Status**: Accepted
**Confidence**: High (direct evidence from codebase)

## Context

The Brewfile was growing large and monolithic, containing packages needed for different use cases (core tools, development, infrastructure, GUI applications) without differentiation. On a minimal machine or a CI runner, there was no easy way to install only the relevant subset.

Commit evidence: `feat(packages): restructure into profile-based package registry`

## Decision

Restructure Homebrew package management into a profile-based registry:

- `.chezmoidata/packages.toml` — Registry of all available packages grouped by profile
- `.chezmoidata/profiles.toml` — Activation flags per profile (`dev`, `infra`, `gui`, etc.)
- Chezmoi templates render only packages for active profiles into the final `Brewfile`

Profiles:
- `core` — Always installed (chezmoi, mise, git, shell tools)
- `dev` — Development tools (neovim, ripgrep, fd, etc.)
- `dev_build` — Build dependencies
- `infra` — Infrastructure tools (terraform, kubectl, helm)
- `security` — Security scanning tools
- `embedded` — Arduino, serial tools
- `services` — Local service dependencies
- `media` — Media processing tools
- `gui` — GUI applications (cask installs)

## Consequences

**Positive:**
- Brewfile is now generated from a single source of truth
- Easy to enable/disable feature sets by toggling profile flags
- CI can install only `core` profile for faster smoke tests
- New machine setup can be tailored to the machine's role

**Negative:**
- Adds complexity: changes now require editing `packages.toml` instead of `Brewfile` directly
- Template rendering adds a step between editing and seeing the final Brewfile

## Related

- ADR-0002: Unified Tool Version Management with Mise (complementary system for runtime tools)
- `docs/prds/project-overview.md` FR-005: Package management
