---
id: PRP-003
created: 2026-04-08
modified: 2026-04-08
status: Draft
confidence: 6
source: git history (sketchybar scope: 5 commits in last 200)
relates-to: [PRD-001]
---

# Sketchybar macOS Integration

## Context

Sketchybar is a highly customizable macOS menu bar replacement. The dotfiles include Sketchybar configuration (committed changes in `sketchybar` scope), including a GitHub repos plugin showing PR/issue counts. However, the integration is not fully documented and some components have been removed (k8s plugin, yabai click handler).

## Problem

Sketchybar configuration is present but:
- Not documented in README or docs/
- Depends on yabai (tiling WM) for some features that were removed
- GitHub plugin requires a token — integration with `~/.api_tokens` not verified
- No smoke test validates Sketchybar config

## Proposed Approach

1. **Document current state**: Audit what plugins/widgets are active and their dependencies
2. **Verify GitHub token integration**: Ensure the GitHub repos plugin reads from `~/.api_tokens` (never hardcoded)
3. **Create Sketchybar ADR**: Document the decision to use Sketchybar vs. alternatives (Raycast bar, default menu bar)
4. **Add to README**: Document Sketchybar as optional macOS-only component
5. **Consider yabai reintegration**: Decide whether to add yabai back or keep Sketchybar standalone
6. **Brewfile integration**: Ensure Sketchybar is in the `gui` profile with correct dependencies

## Success Criteria

- Sketchybar config applies cleanly via `chezmoi apply`
- GitHub plugin displays PR/issue counts using `~/.api_tokens` token
- Configuration documented in README as macOS-only optional component
- Separate ADR for Sketchybar architectural decision

## Related

- `docs/prds/project-overview.md` FR-005: Package management (gui profile)
- `docs/adrs/0013-nixos-declarative-system-configuration.md` (macOS vs. Linux scope)
