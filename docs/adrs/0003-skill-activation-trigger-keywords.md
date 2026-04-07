# ADR-0003: Skill Activation via Trigger Keywords

## Status

Accepted

## Date

2024-12 (retroactively documented 2025-12)

## Context

The dotfiles repository contains **103+ skills** - modular capabilities that extend Claude's functionality through specialized knowledge domains. Skills activate automatically when Claude determines they're relevant to the user's request.

### The Discovery Problem

Skills are discovered from the `~/.claude/skills/` directory, but **only metadata is pre-loaded** at startup:

```yaml
---
name: skill-identifier
description: What this does and when to use it
---
```

Claude sees only the `name` and `description` fields (~100 tokens) when deciding whether to load a skill. The full `SKILL.md` content (often 200-500 lines) is only loaded if the skill is activated.

This creates a **discovery bottleneck**: If the description doesn't match user language, the skill never activates.

### Measured Activation Rates

Through experimentation, we measured activation rates across different description approaches:

| Approach | Activation Rate | Example |
|----------|-----------------|---------|
| Basic description | ~20% | "Helps with documents" |
| Specific capabilities | ~35% | "Extract text from PDFs and process documents" |
| Trigger keywords | ~50% | Includes tool names like "PyPDF2", "pdfplumber" |
| Explicit "Use when..." | ~70% | "Use when user mentions PDFs, forms, extraction" |
| Forced evaluation hooks | ~84% | System-level skill evaluation triggers |

### The Vocabulary Mismatch

Users don't speak in technical abstractions. They say:
- "Help me with my dotfiles" (not "configuration file management")
- "Search for TODOs in the code" (not "perform regex pattern matching")
- "Fix my pytest tests" (not "resolve Python testing framework issues")

Skills with generic descriptions like "helps with configuration" fail to match user vocabulary.

### Scale Challenge

With 100+ skills, disambiguation becomes critical:
- Multiple skills could reasonably match a query
- Generic descriptions cause activation conflicts
- Users can't discover skills they don't know exist

## Decision

**Adopt explicit trigger keyword patterns** with "Use when..." clauses in all skill descriptions.

### Description Formula

```
[What it does in 1-2 sentences] + [Specific domain terms] + "Use when [explicit triggers]."
```

### Implementation Pattern

**Before (20% activation):**
```yaml
description: Helps with Python testing
```

**After (70% activation):**
```yaml
description: |
  Core Python development concepts, idioms, best practices, and language features.
  Covers Python 3.10+ features, type hints, async/await, and Pythonic patterns.
  For running scripts, see uv-run. For project setup, see uv-project-management.
  Use when user mentions Python, type hints, async Python, decorators, context managers,
  or writing Pythonic code.
```

### Trigger Keyword Categories

1. **Tool names**: `pytest`, `uv`, `ripgrep`, `chezmoi`
2. **File extensions**: `.py`, `.toml`, `.yml`
3. **Config files**: `pyproject.toml`, `.chezmoiignore`
4. **Action verbs**: "search", "find", "deploy", "test"
5. **Domain terms**: "dotfiles", "cross-platform", "container"

### Real Examples from Repository

**chezmoi-expert skill:**
```yaml
description: |
  Comprehensive chezmoi dotfiles management expertise including templates, cross-platform
  configuration, file naming conventions, and troubleshooting. Covers source directory
  management, reproducible environment setup, and chezmoi templating with Go templates.
  Use when user mentions chezmoi, dotfiles, cross-platform config, chezmoi apply,
  chezmoi diff, .chezmoidata, or managing configuration files across machines.
```

**rg-code-search skill:**
```yaml
description: Fast code search using ripgrep (rg) with smart defaults, regex patterns,
  and file filtering. Use when searching for text patterns, code snippets, or performing
  multi-file code analysis.
```

### Documentation Requirements

All skills must include:
1. **YAML frontmatter** with `name` and `description` fields
2. **Description under 1024 characters** but specific enough to disambiguate
3. **"Use when..." clause** with concrete trigger scenarios
4. **Third person perspective** ("Extracts..." not "I extract...")

## Consequences

### Positive

1. **3.5x activation improvement** - From ~20% to ~70% with proper descriptions
2. **Predictable behavior** - Clear mapping between user language and skill activation
3. **Self-documenting** - "Use when" clauses serve as usage documentation
4. **Conflict reduction** - Specific triggers reduce multi-skill ambiguity
5. **Discoverability** - Users can infer skill existence from natural language

### Negative

1. **Maintenance burden** - Must update triggers as user vocabulary evolves
2. **Description bloat** - Comprehensive descriptions approach 1024 char limit
3. **False positives** - Overly broad triggers may activate inappropriate skills
4. **Manual process** - No automated validation of activation patterns

### Skill Writing Checklist

For each new skill:
- [ ] YAML frontmatter present with `name` and `description`
- [ ] Description answers: What does it do? When should Claude use it?
- [ ] Trigger keywords match user language (not technical jargon)
- [ ] "Use when..." clause explicitly states activation scenarios
- [ ] Third person perspective throughout
- [ ] Under 1024 characters but specific enough

### Metrics Tracking

Skills documentation tracks:
- Total skills: 100+
- YAML frontmatter compliance: 100%
- "Use when" clause adoption: Target 100%

## Alternatives Considered

### Semantic Matching
Use embedding-based similarity between user query and skill descriptions.

**Rejected because**: Would require infrastructure changes to Claude Code; current keyword approach achieves acceptable activation rates.

### Skill Categories/Tags
Organize skills into categories that users explicitly select.

**Rejected because**: Adds friction; users shouldn't need to know skill taxonomy.

### System Hooks for Forced Evaluation
Use Claude Code hooks to force skill evaluation on every request.

**Partially adopted**: Hooks achieve 84% activation but add latency; reserved for critical skills.

### Skill Aliases
Multiple names/descriptions pointing to same skill.

**Not implemented**: Would increase maintenance burden; single well-written description preferred.

## Related Decisions

- ADR-0001: Chezmoi exact_ Directory Strategy (skills depend on file integrity)
- ADR-0004: Subagent-First Delegation Strategy (skills inform agent selection)
- ADR-0005: Namespace-Based Command Organization (commands vs skills distinction)

## References

- Skills directory: `exact_dot_claude/skills/`
- Skills documentation: `exact_dot_claude/skills/CLAUDE.md`
- External analysis: [Making Skills Activate Reliably](https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably)
- Anthropic skills guide: https://code.claude.com/docs/en/skills
