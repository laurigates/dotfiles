# Claude Code Plugins

This directory contains Claude Code plugins that can be installed via the plugin marketplace system.

## Available Plugins

### [dotfiles-toolkit](./dotfiles-toolkit/)

Comprehensive development toolkit with 30+ specialized agents and 20+ commands.

**Categories**: Development, Dotfiles Management, Infrastructure

**Highlights**:
- Chezmoi expert guidance
- Multi-language development agents (Python, Rust, C++, Node.js, Shell)
- Infrastructure & operations (Docker, Kubernetes, Terraform)
- Git workflows and documentation
- Code review and refactoring tools

## Installation

### Via GitHub Marketplace

```bash
# Add this repository as a marketplace
/plugin marketplace add laurigates/dotfiles

# Browse and install plugins
/plugin
```

### Local Development

For local development or if you've cloned this repository:

```bash
# Navigate to the plugin directory
cd plugins/dotfiles-toolkit

# Run the setup script to create symlinks
./setup-symlinks.sh
```

## Plugin Structure

Each plugin follows the Claude Code plugin structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── agents/                   # Specialized agents (optional)
├── commands/                 # Slash commands (optional)
├── setup-symlinks.sh         # Setup script for local dev
└── README.md                 # Plugin documentation
```

## Creating New Plugins

To add a new plugin to this repository:

1. Create a new directory under `plugins/`
2. Add `.claude-plugin/plugin.json` with metadata
3. Add agents, commands, or other components
4. Update `.claude-plugin/marketplace.json` in the repo root
5. Document the plugin in its README.md

## More Information

- [Claude Code Plugins Announcement](https://www.anthropic.com/news/claude-code-plugins)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
