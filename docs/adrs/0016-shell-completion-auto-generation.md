# ADR-0016: Shell Completion Auto-Generation Pattern

**Date**: 2026-04-08
**Status**: Accepted
**Confidence**: Medium (inferred from scripts and commit patterns)

## Context

Shell completions for CLI tools (Claude Code, uv, pip, docker, kubectl, etc.) need to stay in sync with the installed tool versions. Manually maintaining completion scripts is error-prone — completions become stale after tool upgrades, leading to missing or broken tab completion.

The completion list is large (36+ tools in `.chezmoidata/completions.toml`) and grows with each new tool added to the environment.

Commit evidence: `fix(completions): auto-regenerate claude completions on CLI update`, `feat(completions): update Claude CLI completions for v4.6`

## Decision

Auto-generate shell completions rather than version-controlling static completion files:

- `.chezmoidata/completions.toml` — Registry of all tools with their completion commands (e.g., `uv generate-shell-completion zsh`)
- Chezmoi template (`dot_zshrc.tmpl`) iterates the registry and sources completions dynamically
- For tools without built-in completion commands (e.g., Claude Code), `scripts/generate-claude-completion.sh` generates from `--help` output and the result is committed as a managed chezmoi file
- mise hook triggers Claude completion regeneration on Claude CLI version changes

**Trade-offs considered:**
- Fully dynamic (generate at shell startup): Too slow — 36 completions would noticeably delay shell start
- Fully static (commit all completion files): Becomes stale; large diffs on tool updates
- Chosen hybrid: Dynamic for tools with fast `generate-shell-completion` support; committed files for tools that lack it

## Consequences

**Positive:**
- Completions stay current with tool versions automatically
- Single registry to add new tools
- Shell startup stays fast (completions are pre-generated, not runtime-computed)

**Negative:**
- Claude CLI completions require manual regeneration when Claude Code adds new subcommands
- `generate-claude-completion.sh` is fragile (parses `--help` output)

## Related

- ADR-0002: Unified Tool Version Management with Mise
- `docs/prds/project-overview.md` FR-002: Zsh shell configuration
