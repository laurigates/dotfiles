# ADR 0001: Migration to Claude Code Rules System

## Status

Accepted

## Date

2025-12-13

## Context

Claude Code introduced the `.claude/rules/` directory feature in v2.0.64 (December 2025) as a modular approach for organizing project-specific instructions. Prior to this, all Claude Code instructions were maintained in:

1. **CLAUDE.md files** - Monolithic files containing project context, conventions, and operational rules
2. **Skills** - Context-dependent expertise that activates based on task relevance

The existing setup had several issues:

- `exact_dot_claude/CLAUDE.md` had grown to 300+ lines mixing high-level design with detailed operational rules
- Universal constraints (delegation, code quality, security) were mixed with project-specific context
- It was unclear which instructions applied universally vs. conditionally
- Maintenance required editing a single large file

## Decision

Migrate universal operational rules from CLAUDE.md files to the new `.claude/rules/` directory while:

1. **Keeping CLAUDE.md files** for high-level project context and navigation
2. **Keeping Skills** for domain-specific expertise that activates conditionally
3. **Creating focused rule files** for universal constraints that apply regardless of task type

### Rules Created

| Rule File | Content Migrated From | Purpose |
|-----------|----------------------|---------|
| `rules/delegation.md` | `exact_dot_claude/CLAUDE.md` | When to use subagents vs direct tools |
| `rules/communication.md` | `exact_dot_claude/CLAUDE.md` | Tone, style, response formatting |
| `rules/development-process.md` | `exact_dot_claude/CLAUDE.md` | TDD, documentation-first, git workflow |
| `rules/code-quality.md` | `exact_dot_claude/CLAUDE.md` | SOLID, functional principles, fail-fast |
| `rules/tool-selection.md` | `exact_dot_claude/CLAUDE.md` | Decision framework for tools |
| `rules/security.md` | Root `CLAUDE.md` | API tokens, secrets, scanning |
| `rules/release-please.md` | Root `CLAUDE.md` | Protected files, conventional commits |
| `rules/documentation-first.md` | Root `CLAUDE.md` | Check docs before implementing |

### Content Kept in CLAUDE.md

- **Root `CLAUDE.md`**: Repository overview, chezmoi configuration, key files, tools, MCP servers
- **`exact_dot_claude/CLAUDE.md`**: High-level design philosophy, directory structure, chezmoi management

### Content Kept as Skills

All 102 skills remain as skills because they:
- Activate conditionally based on task relevance
- Provide specialized domain expertise
- Have YAML frontmatter for activation triggers
- Follow progressive disclosure with REFERENCE.md files

## Consequences

### Positive

- **Improved organization**: Single-concern rule files are easier to maintain
- **Clearer semantics**: Rules = universal, Skills = conditional, CLAUDE.md = context
- **Better discoverability**: Rule files have descriptive names indicating their purpose
- **Reduced file size**: CLAUDE.md files are now focused and concise
- **Future-proof**: Aligned with Claude Code's official feature for project instructions

### Negative

- **More files to manage**: 8 rule files instead of 2 large CLAUDE.md sections
- **Learning curve**: Team members need to understand rules vs skills vs CLAUDE.md
- **Chezmoi complexity**: Additional directory (`rules/`) under `exact_dot_claude/`

### Neutral

- **Same priority level**: Rules load with the same priority as `.claude/CLAUDE.md`
- **No behavior change**: The same instructions apply, just organized differently
- **Backward compatible**: Existing skills and commands work unchanged

## Alternatives Considered

### 1. Keep Everything in CLAUDE.md

**Rejected because:**
- Files were becoming unwieldy (300+ lines)
- Mixed concerns (context vs rules)
- Claude Code now has a dedicated feature for this

### 2. Convert All Rules to Skills

**Rejected because:**
- Skills activate conditionally based on description matching
- Universal constraints should apply unconditionally
- Would require convoluted "Use when..." clauses to always activate

### 3. Use Path-Scoped Rules Only

**Rejected because:**
- Most rules apply project-wide, not to specific paths
- Path scoping is better suited for subdirectory-specific conventions
- Would add unnecessary complexity via YAML frontmatter

## Implementation Notes

### Directory Structure After Migration

```
exact_dot_claude/
├── CLAUDE.md              # Slimmed: ~70 lines (was ~300)
├── rules/                 # NEW
│   ├── delegation.md
│   ├── communication.md
│   ├── development-process.md
│   ├── code-quality.md
│   ├── tool-selection.md
│   ├── security.md
│   ├── release-please.md
│   └── documentation-first.md
├── skills/                # Unchanged: 102 skills
├── commands/              # Unchanged
└── ...
```

### Applying Changes

After pulling this change:
```bash
chezmoi apply -v ~/.claude
```

### Memory Hierarchy

Rules load in this order (lower number = loaded first, higher takes precedence):

1. `~/.claude/CLAUDE.md` - User preferences
2. `./CLAUDE.md` - Project root
3. `./.claude/CLAUDE.md` + `./.claude/rules/**/*.md` - **Same level**
4. `./.claude/CLAUDE.local.md` - Personal overrides
5. `./src/CLAUDE.md` - Subdirectory context

## References

- [Claude Code Rules Documentation](https://code.claude.com/docs/en/memory)
- [Claude Code v2.0.64 Changelog](https://claudelog.com/claude-code-changelog/)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
