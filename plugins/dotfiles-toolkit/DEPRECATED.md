# DEPRECATED

This plugin has been split into three focused plugins for better maintainability and flexibility.

## Migration

### Old Plugin (deprecated)
```json
"enabledPlugins": {
  "dotfiles-toolkit@dotfiles": true
}
```

### New Plugins (recommended)
```json
"enabledPlugins": {
  "dotfiles-core@dotfiles": true,           // Essential tools (always enabled)
  "dotfiles-experimental@dotfiles": true,    // Experimental features (optional)
  "dotfiles-fvh@dotfiles": true              // Work-specific tools (optional)
}
```

## New Plugin Structure

### dotfiles-core
**Essential development workflows (always recommended)**

Includes all stable features:
- Git workflows (`/git:smartcommit`, `/git:repo-maintenance`)
- GitHub automation (`/github:*`)
- Code quality (`/tdd`, `/codereview`, `/refactor`)
- Testing (`/test:run`)
- Linting (`/lint:check`)
- Dependencies (`/deps:install`)
- Documentation (`/docs:*`)
- Setup utilities (`/setup:*`)
- All 14 agents

### dotfiles-experimental
**Testing and experimental features (can disable if unstable)**

Includes:
- `/experimental:devloop` - Automated development loop
- `/experimental:devloop-zen` - AI-powered dev loop with Zen MCP
- `/experimental:modernize` - Code modernization automation

### dotfiles-fvh
**Work-specific integrations (disable for personal projects)**

Includes:
- `/disseminate` - Podio/GitHub synchronization
- `/handoff` - Work handoff documents (Podio format)
- `/build-knowledge-graph` - FVH technical knowledge graphs

## Benefits of New Structure

1. **Easy experimental disable** - Toggle experimental features without affecting core functionality
2. **Work/personal separation** - Disable FVH tools for personal projects
3. **Better maintainability** - Focused, single-purpose plugins
4. **Faster development** - Local marketplace provides instant feedback

## Migration Steps

1. **Update settings** (`~/.claude/settings.json` or `dot_claude/settings.json.tmpl`):
   ```json
   "extraKnownMarketplaces": {
     "dotfiles": {
       "source": {
         "source": "local",
         "path": "/Users/USERNAME/.local/share/chezmoi/plugins"
       }
     }
   },
   "enabledPlugins": {
     "dotfiles-core@dotfiles": true,
     "dotfiles-experimental@dotfiles": true,
     "dotfiles-fvh@dotfiles": true
   }
   ```

2. **Apply changes**:
   ```bash
   chezmoi apply -v
   ```

3. **Verify plugins load**:
   ```bash
   /plugin list
   ```

4. **Confirm commands available**:
   ```bash
   /help
   ```

## Rollback

If you need to rollback to the old plugin:

```json
"enabledPlugins": {
  "dotfiles-toolkit@dotfiles": true,
  "dotfiles-core@dotfiles": false,
  "dotfiles-experimental@dotfiles": false,
  "dotfiles-fvh@dotfiles": false
}
```

However, this plugin will no longer receive updates. Please migrate to the new structure.

## Documentation

See the new documentation in `dot_claude/docs/`:
- [plugins-setup.md](../../dot_claude/docs/plugins-setup.md) - Plugin installation and management
- [claude-config.md](../../dot_claude/docs/claude-config.md) - Settings configuration guide
- [hooks-guide.md](../../dot_claude/docs/hooks-guide.md) - Hook system reference

## Timeline

- **v2.0.0**: New plugin structure introduced (current)
- **v2.1.0**: Old plugin will be archived (planned)
- **v3.0.0**: Old plugin will be removed (future)

Please migrate to the new structure at your earliest convenience.
