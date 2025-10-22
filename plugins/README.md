# Claude Code Plugins

This directory contains Claude Code plugins that can be installed via the plugin marketplace system.

## What are Plugins?

Plugins are different from:
- **Skills** (`.claude/skills/`) - Automatically discovered domain knowledge
- **Agents** (`.claude/agents/`) - Explicitly delegated for specialized tasks
- **Slash Commands** (`.claude/commands/`) - User-invoked with `/command` syntax

Plugins are **installable packages** that can contain multiple agents, commands, and other components, distributed via the Claude Code marketplace system.

## Available Plugins

### Dotfiles Toolkit
**Location:** `dotfiles-toolkit/`
**Purpose:** Comprehensive development toolkit with 30+ specialized agents and 20+ commands

**Categories:** Development, Dotfiles Management, Infrastructure

**Key Features:**
- **Dotfiles Management:** Chezmoi expert guidance and configuration management
- **Multi-Language Development:** Python, Rust, C++, Node.js, Shell scripting
- **Infrastructure & Operations:** Docker, Kubernetes, Terraform, CI/CD pipelines
- **Code Quality:** Review, refactoring, testing, and documentation tools
- **Git Workflows:** Smart commits, repository maintenance, PR management

**When to use this plugin:** Development workflows, dotfiles management, infrastructure operations, code quality improvements, or cross-platform configuration.

## Installation

### Via GitHub Marketplace

```bash
# Add this repository as a marketplace
/plugin marketplace add laurigates/dotfiles

# Browse and install plugins
/plugin

# Or install directly
/plugin install dotfiles-toolkit
```

### Local Development

For local development or if you've cloned this repository:

```bash
# Add your local repo as a marketplace
/plugin marketplace add file:///path/to/your/dotfiles

# Install the plugin
/plugin install dotfiles-toolkit
```

## Plugin Structure

Each plugin follows the Claude Code plugin structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Required: Plugin metadata
├── agents/                   # Optional: Specialized agents
├── commands/                 # Optional: Slash commands
├── skills/                   # Optional: Skills
└── README.md                 # Required: Plugin documentation
```

### Plugin Metadata Format

`.claude-plugin/plugin.json`:

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Brief description of the plugin",
  "author": "Author Name",
  "categories": ["category1", "category2"],
  "components": {
    "agents": ["agent1", "agent2"],
    "commands": ["command1", "command2"]
  }
}
```

## Creating New Plugins

1. Create a directory in `plugins/`
2. Add `.claude-plugin/plugin.json` with required metadata
3. Add components (agents, commands, skills)
4. Write comprehensive README.md
5. Update `.claude-plugin/marketplace.json` in repo root
6. Test the plugin locally before publishing

## Plugins vs Skills vs Agents vs Commands

| Feature | Plugins | Skills | Agents | Slash Commands |
|---------|---------|--------|--------|----------------|
| Invocation | Install once | Automatic | Delegation | User types `/cmd` |
| Distribution | Marketplace | Built-in | Built-in | Built-in |
| Contains | Multiple components | Knowledge | Single task | Single workflow |
| Best for | Reusable toolkits | Domain expertise | Specialized work | Quick actions |
| Location | `plugins/` | `.claude/skills/` | `.claude/agents/` | `.claude/commands/` |

## Benefits of Plugins

- **Composable**: Package related agents, commands, and skills together
- **Distributable**: Share via marketplace or local installation
- **Versioned**: Track changes and updates over time
- **Modular**: Enable/disable entire toolkits as needed
- **Discoverable**: Browse available plugins via marketplace
- **Portable**: Works across Claude Code installations

## Managing Plugins

```bash
# List installed plugins
/plugin list

# Enable/disable plugins
/plugin enable dotfiles-toolkit
/plugin disable dotfiles-toolkit

# Update plugins
/plugin update dotfiles-toolkit

# Uninstall plugins
/plugin uninstall dotfiles-toolkit
```

## Documentation

For more information about Plugins:
- [Claude Code Plugins Announcement](https://www.anthropic.com/news/claude-code-plugins)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [Plugin Development Guide](https://docs.claude.com/en/docs/claude-code/plugins)
