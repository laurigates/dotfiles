# Claude Code Skills Directory

This directory contains **Agent Skills** - modular capabilities that extend Claude's functionality through automatically-invoked specialized knowledge domains.

## What Are Skills?

Skills are **model-invoked** capabilities. Claude autonomously decides when to use them based on your request and the skill's description. They consist of:

- `SKILL.md` (required): YAML frontmatter with metadata plus instruction content
- Supporting files (optional): Reference documentation, examples, templates

**Key distinction**: Unlike slash commands (explicit user invocation), skills activate automatically when Claude determines they're relevant.

## Why Skills Don't Activate (And How to Fix It)

### The Activation Problem

Research shows that **basic skill descriptions achieve only ~20% activation rate**. This is because:

1. **Only metadata is pre-loaded**: At startup, Claude only sees the `name` and `description` fields (~100 tokens), not the full SKILL.md
2. **Description is the PRIMARY trigger**: Claude decides whether to load a skill almost entirely based on its description
3. **Vague descriptions get ignored**: Generic descriptions like "helps with documents" don't provide enough signal

### What Makes Skills Activate

Claude activates a skill when it recognizes a match between:
- **User's request language** → **Skill's description keywords**

The more specific and explicit your description, the higher the activation rate.

### Activation Rate by Approach

| Approach | Success Rate | Notes |
|----------|-------------|-------|
| Basic description | ~20% | Passive, relies on Claude inference |
| Specific trigger keywords | ~50% | Includes terms users actually say |
| Explicit use cases | ~70% | "Use when..." clauses |
| Forced evaluation hooks | ~84% | Hook forces explicit skill evaluation |

### Quick Checklist for High-Activation Skills

- [ ] **YAML frontmatter present** with `name` and `description` fields
- [ ] **Description answers TWO questions**: What does it do? When should Claude use it?
- [ ] **Trigger keywords match user language** (not technical jargon)
- [ ] **"Use when..." clause** explicitly states activation scenarios
- [ ] **Third person perspective** ("Extracts..." not "I extract...")
- [ ] **Under 1024 characters** but specific enough to disambiguate

## Skills in This Repository

This repository contains **74 specialized skills** organized by domain:

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

### Python Development (10 skills)
- **python-development** - Core Python concepts, idioms, and best practices
- **python-testing** - pytest, fixtures, parametrization, test organization
- **python-code-quality** - Linting, formatting, type checking, code analysis
- **python-packaging** - Package creation, distribution, publishing to PyPI
- **uv-run** - Running scripts, inline dependencies (PEP 723), temporary dependencies
- **uv-project-management** - Project setup, dependencies, and lockfiles with uv
- **uv-python-versions** - Python version management with uv
- **uv-tool-management** - CLI tool installation and management with uv
- **uv-workspaces** - Monorepo and workspace management with uv
- **uv-advanced-dependencies** - Advanced dependency resolution with uv

### TypeScript/JavaScript Development (2 skills)
- **nodejs-development** - JavaScript/TypeScript with Bun, Vite, Vue 3, Pinia
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

### Infrastructure & DevOps (17 skills)
- **container-development** - Docker, multi-stage builds, 12-factor apps, Skaffold
- **kubernetes-operations** - K8s cluster management, debugging, kubectl mastery
- **infrastructure-terraform** - Infrastructure as Code with HCL and state management
- **openfeature** - Vendor-agnostic feature flag SDK, evaluation context, hooks, testing patterns
- **go-feature-flag** - Self-hosted feature flags with file-based config, relay proxy, targeting rules
- **mcp-management** - Intelligent MCP server installation and project-based configuration
- **helm-chart-development** - Helm chart creation, templating, best practices
- **helm-debugging** - Debug Helm deployments and template rendering
- **helm-release-management** - Manage Helm releases and upgrades
- **helm-release-recovery** - Recover from failed Helm releases
- **helm-values-management** - Manage Helm values files and overrides
- **argocd-login** - ArgoCD authentication and CLI login workflows
- **tfc-list-runs** - List Terraform Cloud runs with filtering by status and date
- **tfc-plan-json** - Parse and analyze Terraform Cloud plan JSON output
- **tfc-run-logs** - Retrieve and analyze Terraform Cloud run logs
- **tfc-run-status** - Check Terraform Cloud run status and details
- **tfc-workspace-runs** - Manage Terraform Cloud workspace runs

### Testing & Quality (1 skill)
- **test-tier-selection** - Automatic test tier selection (unit/integration/e2e) based on change scope

### Code Quality & Formatting (4 skills)
- **code-antipatterns-analysis** - Detect anti-patterns, code smells, and quality issues using ast-grep across JavaScript, TypeScript, Vue, React, Python
- **ruff-linting** - Python code quality with ruff linter
- **ruff-formatting** - Python code formatting with ruff format
- **ruff-integration** - Integrate ruff with editors, pre-commit, and CI/CD

### Meta & Coordination (10 skills)
- **agent-coordination-patterns** - Patterns for multi-agent task coordination
- **agent-file-coordination** - File-based coordination between agents
- **multi-agent-workflows** - Coordinating complex tasks across specialized agents
- **ux-handoff-markers** - Standardized @HANDOFF markers for inter-agent communication
- **blueprint-development** - PRD-first development methodology and skill generation
- **project-discovery** - Systematic project orientation for unfamiliar codebases
- **command-context-patterns** - Best practices for context expressions in slash commands
- **graphiti-episode-storage** - Episode-based memory storage with Graphiti
- **graphiti-learning-workflows** - Learning workflows using Graphiti memory
- **graphiti-memory-retrieval** - Retrieve and query episodic memory with Graphiti

### Knowledge Management (2 skills)
- **obsidian-bases** - Obsidian Bases database feature for YAML-based interactive note views, filters, formulas, and table/card views
- **claude-blog-sources** - Access Claude Blog for latest Claude Code improvements, patterns, and best practices

### Communication & Formatting (3 skills)
- **google-chat-formatting** - Convert Markdown to Google Chat formatting syntax
- **imagemagick-conversion** - Image conversion and manipulation with ImageMagick
- **ticket-drafting-guidelines** - Structured guidelines for drafting GitHub issues and technical tickets

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

### 2. Write a High-Activation Description

The description field is **the most important part of your skill**. It determines whether Claude will ever load the skill.

#### Description Formula

```
[What it does in 1-2 sentences] + [Specific domain terms] + "Use when [explicit triggers]."
```

#### Examples: Good vs Bad Descriptions

**❌ Bad (won't activate):**
```yaml
description: Helps with documents
```
- Too vague, no trigger keywords, no use cases

**❌ Mediocre (~20% activation):**
```yaml
description: Extract text from PDF files and process documents
```
- Better, but missing explicit "Use when..." clause

**✅ Good (~50% activation):**
```yaml
description: |
  Extract text and tables from PDFs, fill forms, merge documents.
  Use when working with PDF files or when the user mentions PDFs,
  forms, or document extraction.
```
- Specific capabilities + explicit trigger scenarios

**✅ Excellent (~70% activation):**
```yaml
description: |
  Extract text, tables, and images from PDF files. Fill PDF forms
  programmatically. Merge, split, and manipulate PDF documents.
  Use when the user mentions: PDFs, PDF extraction, form filling,
  document merging, PyPDF2, pdfplumber, or pdf-lib.
```
- Multiple specific capabilities
- Explicit tool/library names users might mention
- Clear "Use when" with concrete trigger terms

#### Key Principles

1. **Match user vocabulary**: If users say "dotfiles", include "dotfiles" (not just "configuration files")
2. **Include tool names**: "pytest", "uv", "ripgrep" - users mention specific tools
3. **List file extensions**: ".pdf", ".yml", "pyproject.toml" - specific file patterns trigger skills
4. **Use third person**: "Extracts..." not "I extract..." or "Extract..."

### 3. Structure Instructions Clearly

Organize content into logical sections:
- **Core Expertise**: Key capabilities
- **Essential Commands**: Copy-pasteable examples
- **Best Practices**: Patterns and anti-patterns
- **Troubleshooting**: Common issues and solutions

### 4. Add Supporting Documentation (Progressive Disclosure)

**Rule of thumb**: Keep SKILL.md under 500 lines. Move detailed content to supporting files.

#### When to Split

| Content Type | Keep in SKILL.md | Move to REFERENCE.md |
|-------------|------------------|---------------------|
| Core capabilities | ✓ | |
| Common commands | ✓ | |
| Quick reference | ✓ | |
| Full API reference | | ✓ |
| Advanced patterns | | ✓ |
| Troubleshooting | | ✓ |
| Edge cases | | ✓ |

#### Recommended Structure

```
skill-name/
├── SKILL.md              # Core guidance (always loaded when skill activates)
├── REFERENCE.md          # Detailed reference (loaded on-demand)
├── examples/             # Working code samples
│   ├── basic.ext
│   └── advanced.ext
└── templates/            # Reusable templates
    └── config.ext
```

#### Why Progressive Disclosure Matters

- **Context efficiency**: Claude only loads what's needed (~5k tokens max per skill)
- **Faster activation**: Smaller SKILL.md loads faster
- **Better focus**: Core instructions aren't buried in reference material
- **On-demand depth**: Reference files load when Claude needs them

**Reference pattern in SKILL.md:**
```markdown
For advanced patterns, see [REFERENCE.md](REFERENCE.md).
```

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

### Official Anthropic Resources
- **Agent Skills Documentation**: https://code.claude.com/docs/en/skills
- **Skill Authoring Best Practices**: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- **Example Skills Repository**: https://github.com/anthropics/skills/
- **Claude Code Best Practices**: https://www.anthropic.com/engineering/claude-code-best-practices

### Community Resources
- **Making Skills Activate Reliably** (Scott Spence): https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably
- **Inside Claude Code Skills** (Mikhail Shilkov): https://mikhail.io/2025/10/claude-code-skills/
- **Awesome Claude Skills** (Community): https://github.com/travisvn/awesome-claude-skills

### Related Claude Code Docs
- **Creating Slash Commands**: https://docs.claude.com/en/docs/claude-code/slash-commands
- **MCP Servers**: https://docs.claude.com/en/docs/claude-code/mcp
- **Hooks Configuration**: https://docs.claude.com/en/docs/claude-code/hooks

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

**Last updated**: 2025-12-08
**Total skills**: 96
**Skill version format**: YAML frontmatter in SKILL.md
**Key metric**: Skills with YAML frontmatter: 72/96 (75%) - fix remaining 25% for full activation
