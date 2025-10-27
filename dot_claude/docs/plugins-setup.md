# Claude Code Plugins Setup Guide

## Installation

The dotfiles repository provides three Claude Code plugins via a local marketplace:

```bash
# Marketplace is auto-configured in settings.json
# Plugins load from: ~/.local/share/chezmoi/plugins/

# To verify plugins are available:
/plugin list
```

## Available Plugins

### dotfiles-core (Required)
Essential development workflows and tools. Always keep this enabled.

**Includes:**
- Git workflows (`/git:smartcommit`, `/git:repo-maintenance`)
- GitHub automation (`/github:process-issues`, `/github:fix-pr`)
- Code quality (`/tdd`, `/codereview`, `/refactor`)
- Testing (`/test:run`)
- Linting (`/lint:check`)
- Dependencies (`/deps:install`)
- Documentation (`/docs:*`)
- Setup utilities (`/setup:*`)
- 14 specialized agents (git-operations, code-review, documentation, etc.)

### dotfiles-experimental (Optional)
Experimental and testing features. Disable if causing issues.

**Includes:**
- `/experimental:devloop` - Automated development loop
- `/experimental:devloop-zen` - AI-powered dev loop with Zen MCP
- `/experimental:modernize` - Code modernization automation

**To disable:**
```json
// In ~/.claude/settings.json or dot_claude/settings.json.tmpl
"enabledPlugins": {
  "dotfiles-core@dotfiles": true,
  "dotfiles-experimental@dotfiles": false,  // Disabled
  "dotfiles-fvh@dotfiles": true
}
```

### dotfiles-fvh (Work-Specific)
FVH-specific workflows and integrations. Disable for personal projects.

**Includes:**
- `/disseminate` - Sync between Podio and GitHub
- `/handoff` - Create handoff documents (Podio format support)
- `/build-knowledge-graph` - Build FVH technical knowledge graphs

**To disable for personal projects:**
```json
"enabledPlugins": {
  "dotfiles-core@dotfiles": true,
  "dotfiles-experimental@dotfiles": true,
  "dotfiles-fvh@dotfiles": false  // Disabled
}
```

## Local Development Workflow

Plugins are loaded directly from the chezmoi source directory, providing instant feedback:

```bash
# 1. Edit a plugin file
vim ~/.local/share/chezmoi/plugins/dotfiles-core/commands/git/smartcommit.md

# 2. Changes are immediate (no reinstall needed!)
/git:smartcommit  # Uses updated version

# 3. Only need to apply settings changes
chezmoi apply -v  # Only for settings.json.tmpl changes
```

## Troubleshooting

### Plugins Not Loading
```bash
# Check marketplace configuration
cat ~/.claude/settings.json | grep -A 5 extraKnownMarketplaces

# Should show:
# "dotfiles": {
#   "source": {
#     "source": "directory",
#     "path": "/Users/USERNAME/.local/share/chezmoi/plugins"
#   }
# }

# Verify plugins directory exists
ls ~/.local/share/chezmoi/plugins/
```

### Commands Not Available
```bash
# List available commands
/help

# Check specific plugin is enabled
cat ~/.claude/settings.json | grep -A 5 enabledPlugins

# Re-apply chezmoi if settings were changed
chezmoi apply -v
```

### Permission Errors
Check `permissions.allow` in settings.json includes required MCP servers and bash commands.

## Plugin Architecture

```
plugins/
├── dotfiles-core/
│   ├── .claude-plugin/plugin.json
│   ├── agents/           # 14 specialized agents
│   └── commands/         # Organized by category
├── dotfiles-experimental/
│   └── commands/experimental/
└── dotfiles-fvh/
    └── commands/
```

Each plugin follows the standard Claude Code plugin structure with:
- `.claude-plugin/plugin.json` - Metadata
- `commands/` - Slash commands
- `agents/` - Specialized sub-agents
