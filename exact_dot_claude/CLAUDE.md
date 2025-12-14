# CLAUDE.md - High-Level Design & Directory Management

This file provides high-level design principles for Claude Code. Detailed operational rules are in the `rules/` directory.

## Directory Management (exact_ approach)

This `.claude` directory is managed via chezmoi's `exact_dot_claude/` source directory with the `exact_` prefix. This approach was chosen over symlinking for several critical reasons:

**Why exact_ instead of symlink:**
- **Process stability**: Symlinks caused race conditions when Claude Code processes accessed files during modifications/renames
- **Atomic updates**: `chezmoi apply` provides explicit checkpoints, preventing mid-operation file changes
- **Auto-cleanup**: Orphaned skills/commands are automatically removed (just like Neovim plugins)
- **Predictable state**: Target directory always matches source exactly after apply

**Runtime directories preserved:**
The following directories are created by Claude Code at runtime and are NOT managed by chezmoi:
- `plans/` - Plan mode state
- `projects/` - Project-specific state
- `session-env/` - Session environment data
- `shell-snapshots/` - Shell state snapshots
- `settings.local.json` - Local settings override

These are preserved via `exact_dot_claude/.chezmoiignore` patterns.

**Workflow:**
After editing skills, commands, rules, or configuration:
```bash
chezmoi apply -v ~/.claude  # Or use alias: ca-claude
```

## Directory Structure

```
.claude/
├── CLAUDE.md           # This file - high-level design
├── rules/              # Always-loaded project conventions (NEW)
│   ├── delegation.md       # When to use subagents vs direct tools
│   ├── communication.md    # Tone, style, response formatting
│   ├── development-process.md  # TDD, documentation-first, git workflow
│   ├── code-quality.md     # SOLID, functional principles, fail-fast
│   ├── tool-selection.md   # Decision framework for tools
│   ├── security.md         # API tokens, secrets, scanning
│   └── release-please.md   # Protected files, conventional commits
├── skills/             # Context-dependent expertise (102 skills)
├── commands/           # Explicit user-invoked slash commands
├── agents/             # Subagent definitions
├── docs/               # Supporting documentation
└── settings.json       # Claude Code settings
```

## Rules vs Skills vs CLAUDE.md

| Type | Loading | Purpose |
|------|---------|---------|
| **Rules** | Always (unconditional) | Universal constraints, guardrails |
| **Skills** | Conditional (on relevance) | Specialized domain expertise |
| **CLAUDE.md** | Always | Project context, navigation |

**Rules** apply regardless of task type. **Skills** activate when Claude determines they're relevant to the current task.

## Design Philosophy

- **Delegate by default** - Use subagents for complex tasks (see `rules/delegation.md`)
- **Documentation-first** - Research before implementing (see `rules/development-process.md`)
- **Test-driven** - RED → GREEN → REFACTOR (see `rules/development-process.md`)
- **Fail fast** - Let errors surface clearly (see `rules/code-quality.md`)
- **Humble communication** - Factual, concise, modest (see `rules/communication.md`)
