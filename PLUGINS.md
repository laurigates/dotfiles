# Claude Code Plugins Setup

This dotfiles repository now includes Claude Code plugins that can be easily installed and managed.

## Quick Start

### Install the Dotfiles Toolkit Plugin

```bash
# Add this repository as a plugin marketplace
/plugin marketplace add laurigates/dotfiles

# Browse available plugins and install
/plugin install dotfiles-toolkit
```

### What You Get

The `dotfiles-toolkit` plugin provides:

- **30+ Specialized Agents** - Task-specific AI agents for development, infrastructure, documentation, and more
- **20+ Slash Commands** - Ready-to-use commands for common workflows
- **Cross-Platform Support** - Works seamlessly across macOS, Linux, and Windows
- **Chezmoi Integration** - Deep integration with chezmoi dotfiles management

## Plugin Management

### Enable/Disable Plugins

```bash
# Disable the plugin temporarily
/plugin disable dotfiles-toolkit

# Re-enable it
/plugin enable dotfiles-toolkit
```

### List Installed Plugins

```bash
/plugin list
```

### Update Plugins

```bash
# Update all plugins from marketplaces
/plugin update
```

## Benefits of Using Plugins

### Before (Traditional Approach)
- All agents and commands always loaded
- Clutters system prompt context
- Difficult to share configurations
- Manual file management with chezmoi

### After (Plugin Approach)
- ✅ Toggle agents/commands on/off as needed
- ✅ Reduces context when not in use
- ✅ Easy to share: just add marketplace
- ✅ Simple installation for others
- ✅ Centralized plugin management
- ✅ Version control for configurations

## Integration with Chezmoi

The plugin structure is designed to work seamlessly with this chezmoi-managed dotfiles repository:

- **Plugin source**: `plugins/dotfiles-toolkit/` (in this repo)
- **Base config**: `dot_claude/` contains core settings, hooks, and workflows
- **Advanced features**: Plugin contains agents and commands
- **Clear separation**: Base configuration vs. advanced toolkit features

## For Contributors

If you're contributing to this dotfiles repository:

1. **Base configuration**: Edit files in `dot_claude/` for core settings, hooks, and workflows
2. **Plugin features**: Edit agents and commands in `plugins/dotfiles-toolkit/`
3. **Version bumps**: Update `plugins/dotfiles-toolkit/.claude-plugin/plugin.json` when making significant changes
4. **Marketplace**: Update `.claude-plugin/marketplace.json` when adding new plugins

### File Organization

- `dot_claude/` - Base Claude Code configuration (settings, hooks, workflows)
- `plugins/dotfiles-toolkit/agents/` - Specialized agents
- `plugins/dotfiles-toolkit/commands/` - Slash commands

## Local Development

If you've cloned this repository and want to use the plugin locally:

```bash
# Add your local repo as a marketplace
/plugin marketplace add file:///path/to/your/dotfiles

# Install the plugin
/plugin install dotfiles-toolkit
```

## More Information

- **Plugin Details**: See [plugins/dotfiles-toolkit/README.md](./plugins/dotfiles-toolkit/README.md)
- **All Plugins**: See [plugins/README.md](./plugins/README.md)
- **Claude Code Plugins**: [Official Announcement](https://www.anthropic.com/news/claude-code-plugins)

## Migrating from Direct Configuration

If you were previously using the direct `~/.claude/` configuration:

1. The agents and commands in `dot_claude/` remain unchanged
2. Install the plugin as described above
3. Optionally disable individual agents/commands in `settings.json` if you want the plugin to take over
4. The plugin and direct config can coexist - Claude Code merges them

**Recommendation**: Use the plugin system for easier management and the ability to toggle features on/off.
