# Dotfiles Core Plugin

Comprehensive development toolkit with 17 skills, 14 specialized agents, and 20+ commands for code quality, infrastructure operations, and development workflows.

## Installation

### Option 1: Via Marketplace (Recommended)

Add this dotfiles repository as a plugin marketplace:

```bash
/plugin marketplace add laurigates/dotfiles
```

Then install the plugin:

```bash
/plugin install dotfiles-toolkit
```

### Option 2: Local Development

If you're working on this dotfiles repository locally, the plugin contains all components directly in:
- `plugins/dotfiles-core/skills/` - All 17 skills
- `plugins/dotfiles-core/agents/` - All 14 specialized agents
- `plugins/dotfiles-core/commands/` - All 20+ slash commands

No additional setup is required - the files are stored directly in the plugin structure.

## What's Included

### Skills (17)

Skills are automatically discovered by Claude based on context - no explicit invocation needed:

#### Core Development Tools (5)
- **chezmoi-expert** - Comprehensive chezmoi dotfiles management
- **shell-expert** - Shell scripting, CLI tools, and automation
- **fd-file-finding** - Fast file search with smart defaults
- **rg-code-search** - Blazingly fast code search with ripgrep
- **git-workflow** - Preferred git patterns and best practices

#### GitHub Actions Integration (3)
- **claude-code-github-workflows** - Workflow design and automation
- **github-actions-mcp-config** - MCP server configuration
- **github-actions-auth-security** - Authentication and security

#### Editor Configuration (1)
- **neovim-configuration** - Modern Neovim setup with Lua and LSP

#### Language-Specific Development (4)
- **python-development** - Modern Python with uv, ruff, pytest
- **rust-development** - Memory-safe systems programming
- **nodejs-development** - JavaScript/TypeScript with Bun, Vite, Vue 3
- **cpp-development** - Modern C++20/23 with CMake, Conan

#### Infrastructure and DevOps (3)
- **container-development** - Docker and containerization
- **kubernetes-operations** - K8s cluster management
- **infrastructure-terraform** - Infrastructure as Code

#### Specialized Domains (1)
- **embedded-systems** - ESP32/ESP-IDF, STM32, FreeRTOS

### Specialized Agents (14)

These agents handle complex multi-step workflows that require explicit delegation:

#### Code Quality & Analysis
- **code-review** - Comprehensive code review with quality, security, and performance analysis
- **code-analysis** - Deep code analysis and architectural insights
- **code-refactoring** - Safe refactoring strategies with testing
- **commit-review** - Commit message quality review
- **security-audit** - Security analysis and vulnerability assessment

#### Infrastructure & Operations
- **cicd-pipelines** - CI/CD pipeline design and configuration
- **git-operations** - Complex Git workflows and repository management
- **system-debugging** - System-level debugging and troubleshooting

#### Documentation & Architecture
- **documentation** - Technical documentation generation
- **requirements-documentation** - Requirements and specifications writing
- **research-documentation** - Research documentation and knowledge capture
- **service-design** - Service architecture design and patterns
- **test-architecture** - Test structure design and TDD guidance

#### Integration & Development
- **api-integration** - API design, integration, and best practices

### Commands (20+)

#### Documentation
- `/docs/docs` - Generate comprehensive documentation
- `/docs/update` - Update existing documentation
- `/docs/decommission` - Document service decommissioning

#### Git Operations
- `/git/smartcommit` - Intelligent commit creation
- `/git/repo-maintenance` - Repository maintenance tasks

#### GitHub Integration
- `/github/process-issues` - Batch process GitHub issues
- `/github/process-single-issue` - Process single issue
- `/github/fix-pr` - Fix pull request issues

#### Code Quality
- `/codereview` - Comprehensive code review
- `/refactor` - Code refactoring assistance
- `/tdd` - Test-driven development workflow
- `/lint/check` - Run linting checks

#### Project Management
- `/project/init` - Initialize new project
- `/setup/new-project` - New project scaffolding
- `/setup/release` - Release preparation
- `/test/run` - Run test suites

#### Development Workflows
- `/deps/install` - Install dependencies
- `/build-knowledge-graph` - Build knowledge graphs
- `/handoff` - Project handoff documentation
- `/chore/modernize` - Modernize codebase
- `/chore/refactor` - Refactoring tasks

#### Experimental
- `/experimental/devloop` - Development loop optimization
- `/experimental/devloop-zen` - Zen development mode
- `/experimental/modernize` - Experimental modernization

#### Knowledge Management
- `/assimilate` - Assimilate new information
- `/disseminate` - Share knowledge
- `/google-chat-format` - Format for Google Chat

## MCP Server Integration

This plugin bundles the **zen-mcp-server** which provides backend capabilities for several agents:

- **code-review** - Powered by zen's `codereview` tool
- **system-debugging** - Powered by zen's `debug` tool
- **commit-review** - Powered by zen's `precommit` tool
- **security-audit** - Powered by zen's `secaudit` tool

The MCP server is **automatically installed and configured** when you enable this plugin - no manual setup required!

**Configuration Location:** `.mcp.json` in the plugin root

## Features

- **Cross-Platform Support** - Works on macOS, Linux, and Windows
- **Chezmoi Integration** - Deep integration with chezmoi dotfiles management
- **Specialized Agents** - Task-specific agents for focused assistance
- **Comprehensive Commands** - Ready-to-use slash commands for common tasks
- **Best Practices** - Incorporates development best practices and patterns
- **Bundled MCP Server** - zen-mcp-server included for enhanced functionality

## Usage

Once installed, you can:

1. **Use specialized agents** for specific tasks:
   ```
   Can you help me review this code? Use the code-review agent.
   ```

2. **Run slash commands** directly:
   ```
   /codereview
   /git/smartcommit
   /docs/update
   ```

3. **Toggle the plugin** on/off as needed:
   ```
   /plugin disable dotfiles-toolkit
   /plugin enable dotfiles-toolkit
   ```

## Contributing

This plugin is part of the [laurigates/dotfiles](https://github.com/laurigates/dotfiles) repository. Contributions are welcome!

## License

Same license as the dotfiles repository.

## Author

**Lauri Gates**
- GitHub: [@laurigates](https://github.com/laurigates)
- Email: laurigates@users.noreply.github.com
