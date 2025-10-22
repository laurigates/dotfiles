# Claude Code Skills

This directory contains Skills for Claude Code - model-invoked capabilities that Claude automatically discovers and uses based on context.

## What are Skills?

Skills are different from:
- **Agents** (`.claude/agents/`) - Explicitly delegated for specialized tasks
- **Slash Commands** (`.claude/commands/`) - User-invoked with `/command` syntax

Skills are **automatically discovered** by Claude based on their description and used when relevant to the conversation context.

## Available Skills

### Chezmoi Expert
**Location:** `chezmoi-expert/`
**Purpose:** Comprehensive chezmoi dotfiles management expertise

Automatically provides guidance on:
- Source vs target file management
- Template system and cross-platform configuration
- File naming conventions (`dot_`, `private_`, etc.)
- Troubleshooting and best practices

**When Claude uses this:** Anytime you work with chezmoi commands, dotfiles, or ask about configuration management.

### Dotfiles Management
**Location:** `dotfiles-management/`
**Purpose:** Cross-platform development environment setup

Automatically assists with:
- Tool integration (mise, Fish, Neovim, Homebrew)
- Platform-specific configurations (macOS/Linux)
- Package management and security practices
- Reproducible environment setup

**When Claude uses this:** When working with development tools, shell configuration, editor setup, or cross-platform compatibility.

## Skill Structure

Each Skill is a directory containing:

```
skill-name/
├── SKILL.md       # Required: Main skill file with YAML frontmatter
└── REFERENCE.md   # Optional: Detailed reference documentation
```

### SKILL.md Format

```yaml
---
name: Skill Name
description: Brief description that helps Claude know when to use this skill
allowed-tools: [Optional list of tools the skill can use]
---

# Skill Name

Main skill content with instructions and examples...
```

## Creating New Skills

1. Create a directory in `.claude/skills/`
2. Add a `SKILL.md` with required frontmatter
3. Write a clear, specific description
4. Add core instructions and examples
5. (Optional) Add `REFERENCE.md` for detailed documentation

## Skills vs Agents vs Commands

| Feature | Skills | Agents | Slash Commands |
|---------|--------|--------|----------------|
| Invocation | Automatic | Delegation | User types `/cmd` |
| Discovery | By description | By description | Explicit |
| Best for | Domain knowledge | Specialized tasks | Quick workflows |
| Files | `SKILL.md` + extras | Single `.md` | Single `.md` |
| Location | `.claude/skills/` | `.claude/agents/` | `.claude/commands/` |

## Benefits of Skills

- **Progressive Disclosure**: Metadata loaded upfront, full content on-demand
- **Automatic Usage**: No need to remember to invoke them
- **Composable**: Multiple skills work together automatically
- **Efficient**: Only loads what's needed when needed
- **Portable**: Same format works across Claude products

## Documentation

For more information about Skills:
- [Claude Code Skills Documentation](https://docs.claude.com/en/docs/claude-code/skills)
- [Agent Skills Overview](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)
- [Skills Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
