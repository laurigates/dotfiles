---
id: PRP-001
created: 2026-04-08
modified: 2026-04-08
status: Draft
confidence: 6
source: git history (private_dot_config/private_fish/ directory existence)
relates-to: [PRD-001]
---

# Fish Shell Migration

## Context

An experimental Fish shell configuration exists in `private_dot_config/private_fish/` but Zsh remains the primary shell. Fish offers a better interactive experience out-of-the-box (better completions, syntax highlighting, autosuggestions without plugins), but migration requires porting Zsh-specific configuration.

## Problem

Zsh requires numerous plugins (syntax-highlighting, autosuggestions, vi-mode, fzf-tab) to match Fish's default interactive experience. Each plugin is an external dependency managed via `.chezmoiexternal.toml`. Fish provides these capabilities natively.

## Proposed Approach

1. **Audit Zsh → Fish feature parity**: Map all current Zsh functions, aliases, completions, and integrations to Fish equivalents
2. **Port key functions**: `ghpc`, `serial-devices`, `serial-monitor`, FZF integration, mise activation, Starship integration
3. **Handle compatibility**: Some tools (mise, Homebrew) have Fish-specific activation — verify all work
4. **Dual-shell period**: Run Fish as interactive shell while keeping Zsh for scripting compatibility
5. **Remove Zsh plugins**: Once feature-parity confirmed, remove external Zsh plugin dependencies from `.chezmoiexternal.toml`

## Success Criteria

- All current Zsh aliases and functions available in Fish
- Shell startup time ≤ current Zsh baseline (< 500ms)
- All tool completions (36+ from completions.toml) working
- mise, Homebrew, FZF, Starship all integrated
- CI smoke test validates Fish shell setup

## Considerations

- Fish is not POSIX-compatible — scripts must remain Zsh/bash
- Some tools may have weaker Fish support than Zsh
- Neovim terminal integration should be tested with Fish

## Related

- `docs/prds/project-overview.md` FR-002: Zsh shell configuration
- `private_dot_config/private_fish/` — existing experimental config
