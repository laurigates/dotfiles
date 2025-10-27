# Claude Code Skills

This directory contains Skills for Claude Code - model-invoked capabilities that Claude automatically discovers and uses based on context.

## What are Skills?

Skills are different from:
- **Agents** (`.claude/agents/`) - Explicitly delegated for specialized tasks
- **Slash Commands** (`.claude/commands/`) - User-invoked with `/command` syntax

Skills are **automatically discovered** by Claude based on their description and used when relevant to the conversation context.

## Available Skills

### Core Development Tools

#### Chezmoi Expert
**Location:** `chezmoi-expert/`
**Purpose:** Comprehensive chezmoi dotfiles management expertise

Automatically provides guidance on:
- Source vs target file management
- Template system and cross-platform configuration
- File naming conventions (`dot_`, `private_`, etc.)
- Troubleshooting and best practices

**When Claude uses this:** Anytime you work with chezmoi commands, dotfiles, or ask about configuration management.

#### Shell Expert
**Location:** `shell-expert/`
**Purpose:** Shell scripting, command-line tools, and automation

Automatically provides:
- Modern CLI tool mastery (jq, yq, lsd)
- POSIX-compliant and Bash scripting best practices
- Cross-platform scripting patterns
- Automation and performance optimization

**When Claude uses this:** When working with shell scripts, command-line tools, automation tasks, or system administration.

#### fd File Finding
**Location:** `fd-file-finding/`
**Purpose:** Fast file finding with smart defaults

Automatically assists with:
- Fast parallel file search (Rust-based)
- Gitignore awareness and smart filtering
- Type, size, and time-based filtering
- Integration with other tools

**When Claude uses this:** When searching for files by name, extension, or pattern across directories.

#### rg Code Search
**Location:** `rg-code-search/`
**Purpose:** Blazingly fast code search with ripgrep

Automatically provides:
- Fast recursive code search
- Regex pattern matching and multi-line search
- File type and path filtering
- Code analysis and security scanning

**When Claude uses this:** When searching for text patterns, code snippets, or performing multi-file code analysis.

#### Git Workflow
**Location:** `git-workflow/`
**Purpose:** Preferred git workflow patterns and best practices

Automatically assists with:
- Branching strategy and commit practices
- Pre-commit validation and security scanning
- Explicit staging and frequent commits
- Pull request preparation

**When Claude uses this:** When performing git operations or managing version control workflows.

### GitHub Actions Integration

#### Claude Code GitHub Workflows
**Location:** `claude-code-github-workflows/`
**Purpose:** Claude Code workflow design and automation patterns

Automatically assists with:
- PR review and issue triage workflows
- CI failure auto-fix automation
- Custom trigger configurations
- Path-filtered reviews

**When Claude uses this:** When creating or modifying GitHub Actions workflows that integrate Claude Code.

#### GitHub Actions MCP Configuration
**Location:** `github-actions-mcp-config/`
**Purpose:** MCP server configuration for GitHub Actions

Automatically provides:
- MCP server setup and multi-server coordination
- Tool permission patterns and environment variables
- Performance optimization
- Multi-repository configuration

**When Claude uses this:** When configuring MCP servers in GitHub Actions context.

#### GitHub Actions Authentication & Security
**Location:** `github-actions-auth-security/`
**Purpose:** Authentication and security for GitHub Actions

Automatically assists with:
- Anthropic API, AWS Bedrock, Vertex AI authentication
- Secrets management and rotation
- Permission scoping and access control
- Security best practices and validation

**When Claude uses this:** When setting up authentication or discussing security for GitHub Actions workflows.

### Editor Configuration

#### Neovim Configuration
**Location:** `neovim-configuration/`
**Purpose:** Modern Neovim setup with Lua and LSP

Automatically assists with:
- Lua-based configuration with lazy.nvim
- LSP setup with Mason
- AI integration with CodeCompanion
- Plugin management and performance optimization

**When Claude uses this:** When configuring Neovim, setting up LSP, managing plugins, or optimizing editor workflows.

### Language-Specific Development

#### Python Development
**Location:** `python-development/`
**Purpose:** Modern Python development with uv and ruff

Automatically provides:
- uv package management (10-100x faster than pip)
- ruff linting and formatting
- pytest testing and coverage
- Type hints and modern pyproject.toml configuration

**When Claude uses this:** When working with Python projects, debugging, testing, or package management.

#### Rust Development
**Location:** `rust-development/`
**Purpose:** Memory-safe systems programming with Rust

Automatically assists with:
- Cargo build system and package management
- Ownership patterns and memory safety
- Async programming with Tokio
- Performance optimization and testing

**When Claude uses this:** When developing Rust applications, working with cargo, or implementing concurrent systems.

#### Node.js Development
**Location:** `nodejs-development/`
**Purpose:** Modern JavaScript/TypeScript with Bun and Vite

Automatically provides:
- Bun runtime and package management
- Vue 3 with Composition API
- TypeScript configuration and type safety
- Vite build tool and optimization

**When Claude uses this:** When working with Node.js, TypeScript, Vue 3, or modern JavaScript tooling.

#### C++ Development
**Location:** `cpp-development/`
**Purpose:** Modern C++20/23 development

Automatically assists with:
- CMake build system and Conan package management
- Modern C++ standards (concepts, ranges, coroutines)
- Memory safety with RAII and smart pointers
- Performance optimization and testing

**When Claude uses this:** When developing C++ applications, configuring CMake, or working with modern C++ features.

### Infrastructure and DevOps

#### Container Development
**Location:** `container-development/`
**Purpose:** Docker and containerization expertise

Automatically provides:
- Dockerfile and multi-stage builds
- 12-factor app methodology
- Image optimization and security hardening
- Skaffold workflows for development

**When Claude uses this:** When working with Docker, containerization, microservices, or orchestration.

#### Kubernetes Operations
**Location:** `kubernetes-operations/`
**Purpose:** K8s cluster management and operations

Automatically assists with:
- Kubectl commands and cluster operations
- Deployment management and troubleshooting
- Networking, storage, and configuration
- Pod debugging and log analysis

**When Claude uses this:** When managing Kubernetes clusters, deploying applications, or troubleshooting K8s issues.

#### Infrastructure Terraform
**Location:** `infrastructure-terraform/`
**Purpose:** Infrastructure as Code with Terraform

Automatically provides:
- HCL configuration and module design
- State management and remote backends
- Plan-apply workflow best practices
- Debugging and troubleshooting

**When Claude uses this:** When provisioning infrastructure, managing Terraform state, or working with cloud resources.

### Specialized Domains

#### Embedded Systems
**Location:** `embedded-systems/`
**Purpose:** Low-level embedded development

Automatically assists with:
- ESP32/ESP-IDF and STM32 development
- FreeRTOS task management
- Hardware interfaces (SPI, I2C, UART)
- Real-time systems and power optimization

**When Claude uses this:** When developing embedded applications, working with microcontrollers, or implementing real-time systems.

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
