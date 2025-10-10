# Dotfiles Toolkit Plugin

Comprehensive development toolkit with 30+ specialized agents and 20+ commands for dotfiles management, development workflows, and cross-platform configuration.

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

If you're working on this dotfiles repository locally:

1. Run the setup script to create symlinks:
   ```bash
   ./plugins/dotfiles-toolkit/setup-symlinks.sh
   ```

2. The plugin structure uses symlinks to the main `dot_claude/` directories:
   - `agents/` → `../../dot_claude/agents/`
   - `commands/` → `../../dot_claude/commands/`

## What's Included

### Specialized Agents (30+)

#### Dotfiles & Configuration
- **chezmoi-expert** - Comprehensive chezmoi guidance and best practices
- **neovim-configuration** - Neovim setup and plugin configuration

#### Development Workflows
- **code-review** - Thorough code review with best practices
- **code-analysis** - Deep code analysis and insights
- **code-refactoring** - Safe refactoring strategies
- **test-architecture** - Test design and TDD guidance

#### Language-Specific
- **python-development** - Python development best practices
- **nodejs-development** - Node.js and JavaScript development
- **rust-development** - Rust development and patterns
- **cpp-development** - C++ development and modern practices
- **shell-expert** - Shell scripting expertise

#### Infrastructure & Operations
- **container-development** - Docker and containerization
- **kubernetes-operations** - K8s operations and management
- **infrastructure-terraform** - Terraform and IaC
- **cicd-pipelines** - CI/CD pipeline design

#### Git & Documentation
- **git-operations** - Git workflows and operations
- **commit-review** - Commit message quality review
- **documentation** - Technical documentation writing
- **requirements-documentation** - Requirements and specifications

#### System & Architecture
- **system-debugging** - System-level debugging
- **service-design** - Service architecture design
- **api-integration** - API design and integration
- **memory-management** - Memory optimization
- **security-audit** - Security analysis and hardening

#### Utilities
- **json-processing** - JSON data manipulation
- **task-logging** - Task tracking and logging
- **plan-critique** - Plan review and improvement
- **template-generation** - Template creation

#### Claude Code Tools
- **claude-code-command-editor** - Edit slash commands
- **claude-code-subagent-editor** - Edit subagent definitions

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
- `/github/quickpr` - Quick PR creation

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

## Features

- **Cross-Platform Support** - Works on macOS, Linux, and Windows
- **Chezmoi Integration** - Deep integration with chezmoi dotfiles management
- **Specialized Agents** - Task-specific agents for focused assistance
- **Comprehensive Commands** - Ready-to-use slash commands for common tasks
- **Best Practices** - Incorporates development best practices and patterns

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
