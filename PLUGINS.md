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

### Chezmoi Workflow

When using this repository with chezmoi:

1. **Initial Setup**: Apply your dotfiles to deploy the base configuration
   ```bash
   chezmoi apply
   ```
   This will deploy:
   - `~/.claude/` (from `dot_claude/`) - Base settings, hooks, workflows
   - `~/plugins/dotfiles-toolkit/` (from `plugins/dotfiles-toolkit/`) - Plugin files

2. **Install the Plugin**: After applying dotfiles, install the plugin via the marketplace
   ```bash
   /plugin marketplace add laurigates/dotfiles
   /plugin install dotfiles-toolkit
   ```

3. **Making Changes**:
   - **Base config changes**: Edit files in `dot_claude/`, then run `chezmoi apply`
   - **Plugin changes**: Edit files in `plugins/dotfiles-toolkit/`, then run `chezmoi apply`
   - **View changes before applying**: Use `chezmoi diff` to preview changes
   - **Dry run**: Use `chezmoi apply --dry-run` to see what would be applied

4. **Plugin Updates**: When you update the plugin files in this repository
   ```bash
   # Apply chezmoi changes to update plugin files on disk
   chezmoi apply

   # Claude Code will automatically detect plugin changes
   # Or manually reload with: /plugin update
   ```

**Note**: The plugin files are stored in your dotfiles repository and deployed via chezmoi. This means:
- Plugin is version-controlled with your dotfiles
- Changes are tracked via git and managed via chezmoi
- No need for separate plugin update mechanisms - just `chezmoi apply`

## For Contributors

If you're contributing to this dotfiles repository:

1. **Base configuration**: Edit files in `dot_claude/` for core settings, hooks, and workflows
2. **Plugin features**: Edit agents and commands in `plugins/dotfiles-toolkit/`
3. **Version bumps**: Update `plugins/dotfiles-toolkit/.claude-plugin/plugin.json` when making significant changes
4. **Marketplace**: Update `.claude-plugin/marketplace.json` when adding new plugins
5. **Document changes**: Update `plugins/dotfiles-toolkit/CHANGELOG.md` with your changes

### Plugin Validation

Before committing plugin changes, validate the plugin structure:

1. **JSON Validation**: Ensure JSON files are well-formed
   ```bash
   # Validate plugin.json
   jq empty plugins/dotfiles-toolkit/.claude-plugin/plugin.json

   # Validate marketplace.json
   jq empty .claude-plugin/marketplace.json
   ```

2. **File Existence**: Verify all documented agents and commands exist
   ```bash
   # Count agents
   ls plugins/dotfiles-toolkit/agents/*.md | wc -l

   # Count commands
   find plugins/dotfiles-toolkit/commands -name "*.md" | wc -l
   ```

3. **Documentation Sync**: Ensure README lists match actual files
   - Check that all commands exist and are properly documented
   - Verify agent descriptions are accurate
   - Update command/agent counts if changed

4. **Chezmoi Compatibility**: Test that files deploy correctly
   ```bash
   chezmoi diff
   chezmoi apply --dry-run
   ```

5. **Line Endings**: Verify consistent line endings (handled by `.gitattributes`)
   ```bash
   git ls-files --eol
   ```

**Automated Validation**: Run the validation script to check all aspects:
```bash
./plugins/dotfiles-toolkit/validate-plugin.sh
```

This script validates JSON files, directory structure, file counts, and version consistency.

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

- **Commands**: See [exact_dot_claude/commands/CLAUDE.md](./exact_dot_claude/commands/CLAUDE.md)
- **Skills**: See [exact_dot_claude/skills/CLAUDE.md](./exact_dot_claude/skills/CLAUDE.md)
- **Claude Code Plugins**: [Official Announcement](https://www.anthropic.com/news/claude-code-plugins)

## Migrating from Direct Configuration

If you were previously using the direct `~/.claude/` configuration:

1. The agents and commands in `dot_claude/` remain unchanged
2. Install the plugin as described above
3. Optionally disable individual agents/commands in `settings.json` if you want the plugin to take over
4. The plugin and direct config can coexist - Claude Code merges them

**Recommendation**: Use the plugin system for easier management and the ability to toggle features on/off.
