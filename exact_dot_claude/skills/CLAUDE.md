# Claude Code Skills Directory

This directory contains **Agent Skills** - modular capabilities that extend Claude's functionality through automatically-invoked specialized knowledge domains.

## What Are Skills?

Skills are **model-invoked** capabilities. Claude autonomously decides when to use them based on your request and the skill's description. They consist of:

- `SKILL.md` (required): YAML frontmatter with metadata plus instruction content
- Supporting files (optional): Reference documentation, examples, templates

**Key distinction**: Unlike slash commands (explicit user invocation), skills activate automatically when Claude determines they're relevant.

## Skills in This Repository

This repository contains **71 specialized skills** organized by domain:

### Core Development Tools (9 skills)
- **chezmoi-expert** - Comprehensive chezmoi guidance (templates, cross-platform configs, file naming)
- **shell-expert** - Shell scripting, CLI tools, automation, cross-platform scripting
- **fd-file-finding** - Fast file search with smart defaults and gitignore awareness
- **rg-code-search** - Blazingly fast code search with ripgrep and regex patterns
- **jq-json-processing** - JSON querying, filtering, and transformation with jq command-line tool
- **yq-yaml-processing** - YAML querying, filtering, and transformation with yq (v4+) command-line tool
- **ast-grep-search** - AST-based code search for structural pattern matching
- **vectorcode-search** - Semantic code search using embeddings for concept-based discovery
- **vectorcode-init** - Initialize VectorCode with automatic configuration generation

### Version Control & Release (6 skills)
- **git-branch-pr-workflow** - Branch management, pull request workflows, and GitHub integration
- **git-commit-workflow** - Commit message conventions, staging, and commit best practices
- **git-security-checks** - Pre-commit security validation and secret detection
- **git-repo-detection** - Extract GitHub repository owner/name from git remotes
- **github-issue-search** - Search and filter GitHub issues efficiently
- **release-please-protection** - Prevents manual edits to automated release files

### GitHub Actions Integration (4 skills)
- **claude-code-github-workflows** - Workflow design, PR reviews, issue triage, CI auto-fix
- **github-actions-mcp-config** - MCP server setup, tool permissions, multi-server coordination
- **github-actions-auth-security** - Authentication methods, secrets management, security best practices
- **github-actions-inspection** - Inspect workflow runs, analyze logs, debug CI/CD failures

### Python Development (9 skills)
- **python-development** - Core Python concepts, idioms, and best practices
- **python-testing** - pytest, fixtures, parametrization, test organization
- **python-code-quality** - Linting, formatting, type checking, code analysis
- **python-packaging** - Package creation, distribution, publishing to PyPI
- **uv-project-management** - Modern Python project management with uv
- **uv-python-versions** - Python version management with uv
- **uv-tool-management** - CLI tool installation and management with uv
- **uv-workspaces** - Monorepo and workspace management with uv
- **uv-advanced-dependencies** - Advanced dependency resolution with uv

### TypeScript/JavaScript Development (3 skills)
- **nodejs-development** - JavaScript/TypeScript with Bun, Vite, Vue 3, Pinia
- **vitest-testing** - Modern TypeScript/JavaScript testing with Vitest
- **bun-lockfile-update** - Manage Bun lockfile updates and version pinning

### Other Languages (3 skills)
- **rust-development** - Memory-safe systems programming with cargo and modern tooling
- **cpp-development** - Modern C++20/23 with CMake, Conan, Clang tools
- **embedded-systems** - ESP32/ESP-IDF, STM32, FreeRTOS, real-time systems

### Editor & Configuration (1 skill)
- **neovim-configuration** - Lua configuration, plugin management, LSP setup, AI integration

### UX & Accessibility (2 skills)
- **accessibility-implementation** - WCAG 2.1/2.2 compliance, ARIA patterns, keyboard navigation, focus management, testing
- **design-tokens** - CSS custom property architecture, theme systems, design token organization, component integration

### Infrastructure & DevOps (10 skills)
- **container-development** - Docker, multi-stage builds, 12-factor apps, Skaffold
- **kubernetes-operations** - K8s cluster management, debugging, kubectl mastery
- **infrastructure-terraform** - Infrastructure as Code with HCL and state management
- **helm-chart-development** - Helm chart creation, templating, best practices
- **helm-debugging** - Debug Helm deployments and template rendering
- **helm-release-management** - Manage Helm releases and upgrades
- **helm-release-recovery** - Recover from failed Helm releases
- **helm-values-management** - Manage Helm values files and overrides
- **argocd-login** - ArgoCD authentication and CLI login workflows

### Testing & Quality (6 skills)
- **test-tier-selection** - Automatic test tier selection (unit/integration/e2e) based on change scope
- **api-testing** - HTTP API testing for TypeScript and Python (Supertest, httpx)
- **playwright-testing** - End-to-end testing with Playwright (cross-browser, visual regression)
- **mutation-testing** - Validate test effectiveness with Stryker and mutmut
- **property-based-testing** - Property-based testing with fast-check and Hypothesis
- **test-quality-analysis** - Detect test smells, overmocking, flaky tests

### Code Quality & Formatting (4 skills)
- **code-antipatterns-analysis** - Detect anti-patterns, code smells, and quality issues using ast-grep across JavaScript, TypeScript, Vue, React, Python
- **ruff-linting** - Python code quality with ruff linter
- **ruff-formatting** - Python code formatting with ruff format
- **ruff-integration** - Integrate ruff with editors, pre-commit, and CI/CD

### Meta & Coordination (9 skills)
- **agent-coordination-patterns** - Patterns for multi-agent task coordination
- **agent-file-coordination** - File-based coordination between agents
- **multi-agent-workflows** - Coordinating complex tasks across specialized agents
- **ux-handoff-markers** - Standardized @HANDOFF markers for inter-agent communication
- **blueprint-development** - PRD-first development methodology and skill generation
- **project-discovery** - Systematic project orientation for unfamiliar codebases
- **graphiti-episode-storage** - Episode-based memory storage with Graphiti
- **graphiti-learning-workflows** - Learning workflows using Graphiti memory
- **graphiti-memory-retrieval** - Retrieve and query episodic memory with Graphiti

### Knowledge Management (2 skills)
- **obsidian-bases** - Obsidian Bases database feature for YAML-based interactive note views, filters, formulas, and table/card views
- **claude-blog-sources** - Access Claude Blog for latest Claude Code improvements, patterns, and best practices

### Communication & Formatting (2 skills)
- **google-chat-formatting** - Convert Markdown to Google Chat formatting syntax
- **imagemagick-conversion** - Image conversion and manipulation with ImageMagick

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

**Chezmoi Management**: The `.claude` directory is managed via chezmoi's `exact_dot_claude/` source directory. Run `chezmoi apply -v ~/.claude` (alias: `ca-claude`) after editing skills to apply changes.

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

1. Create a directory in `exact_dot_claude/skills/skill-name/`
2. Add `SKILL.md` with proper YAML frontmatter
3. Run `chezmoi apply -v ~/.claude` to apply changes
4. Test activation with relevant queries
5. Update this `CLAUDE.md` with the new skill
6. Update repository `CLAUDE.md` skill count if needed
7. Commit and push to share with the team

Skills in `.claude/skills/` are automatically distributed to all team members who pull the repository. After pulling, run `chezmoi apply -v ~/.claude` to update local skills.

---

**Last updated**: 2025-11-27
**Total skills**: 71
**Skill version format**: YAML frontmatter in SKILL.md
