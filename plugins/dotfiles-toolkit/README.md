# Dotfiles Toolkit Plugin

Comprehensive development toolkit with 14 specialized agents and 20+ commands for code quality, infrastructure operations, and development workflows.

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

If you're working on this dotfiles repository locally, the plugin contains all agents and commands directly in:
- `plugins/dotfiles-toolkit/agents/` - All specialized agents
- `plugins/dotfiles-toolkit/commands/` - All slash commands

No additional setup is required - the files are stored directly in the plugin structure.

## What's Included

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

**Note:** Domain expertise (language-specific development, tooling) has been moved to Skills (`.claude/skills/`) for automatic discovery. Skills include: Shell Expert, Neovim Configuration, Python, Rust, Node.js, C++, Container Development, Kubernetes, Terraform, and Embedded Systems.

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

This plugin bundles the **vectorcode** MCP server for advanced code search and analysis capabilities.

**Configuration:** See `.mcp.json` in the plugin root

The MCP server is automatically configured when you enable this plugin. It provides:
- Semantic code search across your codebase
- Code structure analysis
- Symbol and reference tracking
- Intelligent code navigation

**Configuration Location:** `.mcp.json` in the plugin root
**Index Location:** `~/.vectorcode` (configurable via `VECTORCODE_INDEX_PATH`)

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
