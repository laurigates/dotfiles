# Claude Code Skills Directory

This directory contains **Agent Skills** - modular capabilities that extend Claude's functionality through automatically-invoked specialized knowledge domains.

## What Are Skills?

Skills are **model-invoked** capabilities. Claude autonomously decides when to use them based on your request and the skill's description. They consist of:

- `SKILL.md` (required): YAML frontmatter with metadata plus instruction content
- Supporting files (optional): Reference documentation, examples, templates

**Key distinction**: Unlike slash commands (explicit user invocation), skills activate automatically when Claude determines they're relevant.

## Skills in This Repository

This repository contains **21 specialized skills** organized by domain:

### Core Development Tools (4 skills)
- **chezmoi-expert** - Comprehensive chezmoi guidance (templates, cross-platform configs, file naming)
- **shell-expert** - Shell scripting, CLI tools, automation, cross-platform scripting
- **fd-file-finding** - Fast file search with smart defaults and gitignore awareness
- **rg-code-search** - Blazingly fast code search with ripgrep and regex patterns

### Version Control & Release (2 skills)
- **git-workflow** - Preferred git patterns (branching, commits, pre-commit validation, PRs)
- **release-please-protection** - Prevents manual edits to automated release files

### GitHub Actions Integration (3 skills)
- **claude-code-github-workflows** - Workflow design, PR reviews, issue triage, CI auto-fix
- **github-actions-mcp-config** - MCP server setup, tool permissions, multi-server coordination
- **github-actions-auth-security** - Authentication methods, secrets management, security best practices

### Programming Languages (4 skills)
- **python-development** - Modern Python with uv, ruff, pytest, type hints
- **rust-development** - Memory-safe systems programming with cargo and modern tooling
- **nodejs-development** - JavaScript/TypeScript with Bun, Vite, Vue 3, Pinia
- **cpp-development** - Modern C++20/23 with CMake, Conan, Clang tools

### Editor & Configuration (1 skill)
- **neovim-configuration** - Lua configuration, plugin management, LSP setup, AI integration

### Infrastructure & DevOps (4 skills)
- **container-development** - Docker, multi-stage builds, 12-factor apps, Skaffold
- **kubernetes-operations** - K8s cluster management, debugging, kubectl mastery
- **infrastructure-terraform** - Infrastructure as Code with HCL and state management
- **embedded-systems** - ESP32/ESP-IDF, STM32, FreeRTOS, real-time systems

### Meta Skills (3 skills)
- **agent-context-management** - Managing context and delegation in multi-agent workflows
- **multi-agent-workflows** - Coordinating complex tasks across specialized agents
- **knowledge-graph-patterns** - Structuring and querying knowledge graphs effectively

## Skill Structure

Each skill is a directory with this format:

```
skill-name/
├── SKILL.md          # Required: metadata and instructions
├── REFERENCE.md      # Optional: detailed reference documentation
└── examples/         # Optional: code samples and templates
```

### SKILL.md Format

```yaml
---
name: skill-identifier
description: What this does and when to use it
allowed-tools: Tool1, Tool2, Tool3
---

# Skill Name

## Core Expertise
[Key capabilities and domain knowledge]

## Essential Commands
[Commands and code snippets]

## Best Practices
[Guidelines and patterns]
```

**Field requirements:**
- `name`: Lowercase letters, numbers, hyphens only (max 64 characters)
- `description`: Functionality AND use cases (max 1024 characters)
  - ✅ Good: "Modern Python development with uv package manager, ruff linting, pytest testing. Automatically assists with Python projects, debugging, and best practices."
  - ❌ Bad: "Helps with Python"
- `allowed-tools`: Optional; restricts which tools Claude can use when skill is active

## How Skills Are Loaded

Skills are discovered from three sources (in precedence order):

1. **Project Skills**: `.claude/skills/` (this directory, team-shared via git)
2. **Personal Skills**: `~/.claude/skills/` (individual workflows)
3. **Plugin Skills**: Bundled with installed plugins

After `chezmoi apply`, project skills from `.claude/skills/` become available at `~/.claude/skills/`.

## Creating New Skills

### 1. Choose a Focused Domain

One skill should address a single capability. Create separate skills for distinct workflows.

❌ **Too broad**: "document-processing" (PDFs, Word, Excel, PowerPoint)
✅ **Focused**: "pdf-extraction", "excel-automation", "docx-generation"

### 2. Write a Specific Description

Include concrete trigger terms and use cases:

```yaml
description: |
  Extract text and tables from PDFs, fill forms, merge documents.
  Use when working with PDF files or when the user mentions PDFs,
  forms, or document extraction.
```

### 3. Structure Instructions Clearly

Organize content into logical sections:
- **Core Expertise**: Key capabilities
- **Essential Commands**: Copy-pasteable examples
- **Best Practices**: Patterns and anti-patterns
- **Troubleshooting**: Common issues and solutions

### 4. Add Supporting Documentation

Use `REFERENCE.md` for detailed information that would clutter the main skill:
- API reference tables
- Configuration options
- Advanced patterns
- Troubleshooting guides

### 5. Test Activation Patterns

Verify the skill activates appropriately:
```bash
# Test with queries that should trigger the skill
"Help me set up a Python project with uv"  # → python-development
"How do I template my fish config?"        # → chezmoi-expert
"Search for all TODO comments"             # → rg-code-search
```

## Best Practices

### Keep Skills Focused
Each skill should have a single clear purpose. If you're writing "and" or "or" frequently in the description, consider splitting into multiple skills.

### Use Specific Trigger Language
Include domain-specific terms that users naturally mention:
- Python skill: "uv", "pytest", "ruff", "pyproject.toml"
- Chezmoi skill: "dotfiles", "template", "cross-platform", "source directory"
- Git skill: "commit", "branch", "pull request", "pre-commit"

### Provide Executable Examples
Users and Claude both benefit from copy-pasteable commands:
```bash
# ✅ Good: Specific, runnable command
uv run pytest --cov --cov-report=html

# ❌ Bad: Abstract description
"Run tests with coverage reporting"
```

### Document Edge Cases
Include troubleshooting sections for common issues:
```markdown
## Troubleshooting

### Skill Not Activating
- Check description includes specific trigger terms
- Verify YAML syntax is valid
- Ensure file is named `SKILL.md`
```

### Version and Update
Track changes to skills over time:
```yaml
# Add version comments to track evolution
# v1.0.0 - Initial creation
# v1.1.0 - Added debugging expertise
# v1.2.0 - Updated for uv 0.5.0
```

## Common Issues

### Claude doesn't use the skill
- **Fix**: Add specific trigger terms to description
- **Fix**: Check YAML frontmatter is valid
- **Fix**: Ensure skill name matches directory name

### Multiple skills conflict
- **Fix**: Use distinct language in descriptions
- **Fix**: Be more specific about when each applies
- **Example**: Don't use "testing" in both pytest and playwright skills

### Skill instructions too long
- **Fix**: Move detailed reference to `REFERENCE.md`
- **Fix**: Keep main skill focused on essential patterns
- **Fix**: Link to supporting files for deep dives

### Tool restrictions causing issues
- **Fix**: Review `allowed-tools` field
- **Fix**: Ensure critical tools are included
- **Fix**: Remove field if no restrictions needed

## Examples from Anthropic

Official example skills are available at:
- **Repository**: https://github.com/anthropics/skills/
- **Categories**: Creative, Development, Enterprise, Meta
- **Notable examples**:
  - `skill-creator` - Guide for building effective skills
  - `mcp-builder` - Creating MCP servers
  - `webapp-testing` - Playwright-based testing
  - Document skills (DOCX, PDF, PPTX, XLSX)

## Reference Documentation

- **Official Skills Guide**: https://docs.claude.com/en/docs/claude-code/skills
- **Example Skills Repository**: https://github.com/anthropics/skills/
- **Creating Slash Commands**: https://docs.claude.com/en/docs/claude-code/slash-commands
- **MCP Servers**: https://docs.claude.com/en/docs/claude-code/mcp

## Contributing Skills

To add a new skill to this repository:

1. Create a directory in `.claude/skills/skill-name/`
2. Add `SKILL.md` with proper YAML frontmatter
3. Test activation with relevant queries
4. Update this `CLAUDE.md` with the new skill
5. Update repository `CLAUDE.md` skill count if needed
6. Commit and push to share with the team

Skills in `.claude/skills/` are automatically distributed to all team members who pull the repository.

---

**Last updated**: 2025-10-31
**Total skills**: 21
**Skill version format**: YAML frontmatter in SKILL.md
