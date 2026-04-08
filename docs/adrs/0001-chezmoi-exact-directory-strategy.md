# ADR-0001: Chezmoi exact_ Directory Strategy for Claude Code Configuration

## Status

Accepted

## Date

2024-12 (retroactively documented 2025-12)

## Context

The `.claude` directory contains Claude Code's configuration including:
- **103+ skills** - Auto-discovered capabilities with YAML frontmatter
- **76 slash commands** - Organized across 14 namespaces
- **22 specialized agents** - Domain-specific task handlers
- **Settings and scripts** - Runtime configuration

This directory is managed by chezmoi (dotfiles manager) but also actively used by Claude Code processes during runtime. Two competing approaches existed:

### Option A: Symlink Strategy
Use chezmoi's `symlink_` prefix to create symbolic links from `~/.claude` to the source directory.

**Pros:**
- Changes immediately visible without `chezmoi apply`
- Single source of truth (source directory)
- Simpler mental model

**Cons:**
- **Race conditions**: Claude Code processes accessing files during modifications/renames caused corruption
- **Partial states**: Mid-edit files visible to running processes
- **No atomic updates**: Changes applied incrementally, not atomically

### Option B: exact_ Directory Strategy
Use chezmoi's `exact_` prefix (`exact_dot_claude/`) to copy files with automatic cleanup of orphaned entries.

**Pros:**
- **Atomic updates**: `chezmoi apply` provides explicit checkpoints
- **Process stability**: Running Claude processes unaffected until apply
- **Auto-cleanup**: Deleted/renamed skills automatically removed (like Neovim plugins with lazy.nvim)
- **Predictable state**: Target always matches source exactly after apply

**Cons:**
- Requires explicit `chezmoi apply` after changes
- Two locations (source vs target) can cause confusion

### The Race Condition Problem

With symlinks, we observed:
1. User edits skill file in source directory
2. Claude Code process reads partially-written file mid-save
3. YAML frontmatter parsing fails or returns incomplete data
4. Skill activation becomes unpredictable

This was particularly problematic because:
- Skills activate based on description matching user queries
- Corrupted descriptions = missed activations
- Multiple Claude sessions could run simultaneously

### Runtime Directory Challenge

Claude Code creates runtime directories that should NOT be managed:
- `projects/` - Project-specific state
- `session-env/` - Session environment data
- `shell-snapshots/` - Shell state snapshots
- `plans/` - Plan mode state

These must persist across `chezmoi apply` operations.

## Decision

**Use the `exact_` prefix strategy** with runtime directory preservation via `.chezmoiignore`.

### Implementation

1. **Source directory**: `~/.local/share/chezmoi/exact_dot_claude/`
2. **Target directory**: `~/.claude` (managed atomically)
3. **Runtime preservation**: `exact_dot_claude/.chezmoiignore` excludes runtime directories

```
# exact_dot_claude/.chezmoiignore
plans/
projects/
session-env/
shell-snapshots/
settings.local.json
```

### Workflow

```bash
# Edit skills/commands in source directory
vim ~/.local/share/chezmoi/exact_dot_claude/skills/my-skill/SKILL.md

# Apply atomically when ready
chezmoi apply -v ~/.claude

# Or use convenience alias
alias ca-claude='chezmoi apply -v ~/.claude'
```

### Why exact_ Instead of Regular Copy

The `exact_` prefix tells chezmoi to:
1. Remove files in target that don't exist in source
2. Ensure target matches source exactly
3. Delete orphaned skills/commands automatically

Without `exact_`, renamed or deleted skills would persist as orphans.

## Consequences

### Positive

1. **Eliminated race conditions** - Running Claude processes see consistent state
2. **Explicit checkpoints** - Changes only visible after deliberate `chezmoi apply`
3. **Automatic cleanup** - No manual removal of old skills needed
4. **Predictable behavior** - Skills either fully present or absent, never partial
5. **Safe experimentation** - Edit source without affecting running sessions

### Negative

1. **Two-step workflow** - Must remember to run `chezmoi apply`
2. **Potential for drift** - Source and target can diverge until apply
3. **Learning curve** - New contributors must understand the pattern

### Mitigations

- **Alias convenience**: `ca-claude` for quick application
- **Documentation**: Clear CLAUDE.md instructions at repository root
- **Git hooks**: Could add pre-commit hook to warn of unapplied changes (not implemented)

## Alternatives Considered

### Git Worktree
Use git worktree to have source directory be the actual `.claude` directory.

**Rejected because**: Still doesn't solve atomicity; introduces git complexity.

### inotify/fswatch Auto-Apply
Watch source directory and auto-apply on changes.

**Rejected because**: Defeats the purpose of explicit checkpoints; could apply mid-edit.

### Containerized Claude Code
Run Claude Code in container with mounted config.

**Rejected because**: Overkill for this problem; introduces deployment complexity.

## Related Decisions

- ADR-0002: Unified Tool Version Management with Mise (shared philosophy of explicit state management)
- Skills activation via trigger keywords (depends on reliable skill file integrity)

## References

- chezmoi documentation: https://www.chezmoi.io/reference/source-state-attributes/
- `exact_dot_claude/CLAUDE.md` - Directory management documentation
- `exact_dot_claude/.chezmoiignore` - Runtime directory exclusions
