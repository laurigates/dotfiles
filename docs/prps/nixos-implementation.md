---
id: PRP-002
created: 2026-04-08
modified: 2026-04-08
status: Draft
confidence: 5
source: ADR-0013 (NixOS Declarative System Configuration)
relates-to: [PRD-001, ADR-0013]
---

# NixOS Implementation

## Context

ADR-0013 documents the intent to support NixOS as a secondary platform. NixOS offers declarative system configuration that complements chezmoi's dotfile management. The `nixos/` directory exists in the repository but implementation is incomplete.

## Problem

On NixOS, Homebrew is not available and mise has limitations (no system package management). Package installation requires Nix expressions. The current chezmoi templates don't handle NixOS-specific paths or package availability.

## Proposed Approach

1. **Audit NixOS compatibility**: Run chezmoi templates in NixOS environment and identify failures
2. **Add NixOS detection**: Add `{{ if eq .chezmoi.os "linux" }}` guards for Homebrew-specific sections
3. **Create home-manager config**: Use home-manager for user-level package management equivalent to Brewfile
4. **Port Brewfile to home.packages**: Map Homebrew formulas to Nix package names for active profiles
5. **Handle mise on NixOS**: Configure mise to work with Nix-managed system tools
6. **CI validation**: Add NixOS container-based smoke test

## Success Criteria

- `chezmoi apply` runs without errors on NixOS
- All core development tools available via Nix packages
- Neovim, Zsh, and mise working correctly
- CI smoke test on NixOS passes

## Considerations

- Nix package names differ from Homebrew formula names — mapping required
- home-manager is a separate dependency to bootstrap
- NixOS system-level config (`/etc/nixos/`) is outside chezmoi scope for now

## Related

- `docs/adrs/0013-nixos-declarative-system-configuration.md`
- `docs/prds/project-overview.md` FR-008: Cross-platform templates
- `nixos/` directory in repository root
