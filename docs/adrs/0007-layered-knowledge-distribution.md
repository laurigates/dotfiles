# ADR-0007: Layered Knowledge Distribution (CLAUDE.md Architecture)

## Status

Accepted

## Date

2024-12 (retroactively documented 2025-12)

## Context

The dotfiles repository contains extensive configuration and automation across multiple domains:
- Chezmoi dotfiles management
- Neovim editor configuration
- Shell and terminal setup
- Claude Code skills, commands, and agents
- CI/CD workflows
- Maintenance scripts

### The Monolithic Documentation Problem

Initially, all guidance lived in a single root `CLAUDE.md` file. As the repository grew:

**Problems with single-file documentation:**
1. **Information overload** - 1000+ lines in one file
2. **Irrelevant context** - Neovim details shown when working on shell configs
3. **Maintenance burden** - All changes to one file cause merge conflicts
4. **Discovery failure** - Hard to find domain-specific guidance
5. **Stale information** - Distant sections not updated with related code

### Claude Code's Context Loading

Claude Code automatically loads `CLAUDE.md` files from:
1. Repository root
2. Current working directory
3. Parent directories up to root

This means **multiple CLAUDE.md files are loaded simultaneously**, enabling layered documentation that's context-aware.

### Domain Expert Principle

Different repository areas have different experts:
- Neovim config → Neovim expertise
- Fish shell → Shell scripting expertise
- Skills system → Claude Code agent expertise
- CI/CD → GitHub Actions expertise

Centralizing all documentation forces one person/context to maintain all domains.

## Decision

**Distribute documentation across domain-specific CLAUDE.md files** following the principle: "Domain experts write domain documentation at the point of source code."

### Documentation Hierarchy

```
dotfiles/
├── CLAUDE.md                           # Root: Repository overview, tools, security
├── exact_dot_claude/
│   ├── CLAUDE.md                       # Claude Code: Design principles, delegation
│   ├── commands/
│   │   └── CLAUDE.md                   # Commands: 14 namespaces, 76 commands
│   ├── skills/
│   │   └── CLAUDE.md                   # Skills: 103+ skills, activation patterns
│   └── agents/
│       └── CLAUDE.md                   # Agents: 22 agents, delegation flows
├── private_dot_config/
│   ├── CLAUDE.md                       # Config: Chezmoi naming, templates
│   └── nvim/
│       └── CLAUDE.md                   # Neovim: Lua config, LSP, plugins
└── scripts/
    └── CLAUDE.md                       # Scripts: Maintenance automation
```

### 8 CLAUDE.md Files by Domain

| File | Domain | Key Content |
|------|--------|-------------|
| **Root** | Repository | Overview, MCP servers, linting, security, release-please |
| **exact_dot_claude/** | Claude Code design | Delegation strategy, core principles, TDD workflow |
| **commands/** | Slash commands | 14 namespaces, command anatomy, creation guide |
| **skills/** | Agent skills | 103+ skills, activation patterns, YAML format |
| **agents/** | Specialized agents | 22 agents, analysis vs implementation, delegation flows |
| **private_dot_config/** | Configuration | Chezmoi naming, templates, cross-platform |
| **nvim/** | Neovim | Lua architecture, LSP, plugins, lazy.nvim |
| **scripts/** | Maintenance | Completion generation, namespace migration |

### Content Distribution Rules

| Content Type | Location | Rationale |
|--------------|----------|-----------|
| Repository overview | Root | First thing anyone sees |
| Tool versions, linting | Root | Applies everywhere |
| Security, secrets | Root | Critical, universal |
| Claude Code philosophy | exact_dot_claude/ | Design decisions |
| Command reference | commands/ | Co-located with commands |
| Skill activation guide | skills/ | Near skill definitions |
| Agent architecture | agents/ | With agent configs |
| Chezmoi patterns | private_dot_config/ | Config-specific |
| Neovim details | nvim/ | Editor-specific |
| Script usage | scripts/ | Near scripts |

### Cross-Reference Pattern

Each domain CLAUDE.md includes a "See Also" section:

```markdown
## See Also

- **Root CLAUDE.md** - Overall repository guidance
- **`.claude/CLAUDE.md`** - High-level design and delegation strategy
- **Chezmoi Expert Skill** - Automatic guidance for chezmoi operations
```

### Root CLAUDE.md Quick Reference

The root file includes a navigation table:

```markdown
| Topic | Documentation | Key Information |
|-------|---------------|-----------------|
| **Overall guidance** | `CLAUDE.md` (this file) | Repository overview |
| **Claude Code design** | `.claude/CLAUDE.md` | Delegation strategy |
| **Slash commands** | `.claude/commands/CLAUDE.md` | 14 namespaces |
| **Skills catalog** | `.claude/skills/CLAUDE.md` | 103+ skills |
| **Configuration** | `private_dot_config/CLAUDE.md` | Chezmoi patterns |
| **Maintenance** | `scripts/CLAUDE.md` | CLI completions |
```

## Consequences

### Positive

1. **Context-aware loading** - Only relevant docs loaded per directory
2. **Reduced cognitive load** - Focused information per domain
3. **Parallel maintenance** - Different areas updated independently
4. **Domain expertise** - Specialists maintain their sections
5. **Discoverable** - Documentation lives near related code
6. **Merge-friendly** - Changes isolated to domain files

### Negative

1. **Navigation complexity** - Must know where to look
2. **Potential duplication** - Some info may appear in multiple places
3. **Consistency challenge** - Different writing styles per domain
4. **Discovery for newcomers** - Must learn the hierarchy

### File Size Guidelines

| File | Target Lines | Rationale |
|------|--------------|-----------|
| Root CLAUDE.md | 300-500 | Overview, not exhaustive |
| Domain CLAUDE.md | 200-400 | Focused reference |
| Subdomain CLAUDE.md | 100-200 | Specific details |

If a CLAUDE.md exceeds 500 lines, consider:
1. Moving detailed content to separate docs
2. Creating subdomain CLAUDE.md files
3. Using progressive disclosure (summary → details)

### Update Protocol

When making changes:

1. **Identify affected domain** - Which CLAUDE.md owns this content?
2. **Update domain file** - Make changes in the appropriate file
3. **Check cross-references** - Update "See Also" if needed
4. **Verify navigation** - Ensure root quick reference is current

## Alternatives Considered

### Single Monolithic CLAUDE.md
Keep all documentation in one file.

**Rejected because**: Information overload, maintenance burden, irrelevant context loading.

### External Documentation System
Use dedicated docs site (GitBook, Docusaurus, etc.).

**Rejected because**: Not loaded by Claude Code; documentation drifts from code.

### README.md Files Instead
Use README.md in each directory.

**Rejected because**: Claude Code specifically loads CLAUDE.md; README is for humans browsing GitHub.

### Wiki-Based Documentation
Maintain docs in GitHub wiki.

**Rejected because**: Not versioned with code; not loaded by Claude Code.

### Flat Documentation Directory
All docs in `docs/` without hierarchy.

**Rejected because**: Loses co-location benefit; all docs loaded regardless of context.

## Related Decisions

- ADR-0006: Documentation-First Development (what to document)
- ADR-0003: Skill Activation via Trigger Keywords (skills docs)
- ADR-0005: Namespace-Based Command Organization (commands docs)

## References

- Root: `CLAUDE.md`
- Claude Code design: `exact_dot_claude/CLAUDE.md`
- Commands: `exact_dot_claude/commands/CLAUDE.md`
- Skills: `exact_dot_claude/skills/CLAUDE.md`
- Agents: `exact_dot_claude/agents/CLAUDE.md`
- Configuration: `private_dot_config/CLAUDE.md`
- Neovim: `private_dot_config/nvim/CLAUDE.md`
- Scripts: `scripts/CLAUDE.md`
