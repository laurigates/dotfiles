# Dotfiles UI Hooks Plugin

Voice notifications, Obsidian logging, SketchyBar integration, and comprehensive status overlay for Claude Code.

## Features

### Voice Notifications
- Context-aware voice notifications using macOS text-to-speech
- Project-specific voice configurations
- Casual summaries of Claude's actions
- Customizable voices, styles, and volume
- Quiet hours support

### Obsidian Logging
- Automatic logging of Claude conversations to Obsidian vault
- Session summaries with timestamps
- Tool usage tracking
- Context extraction and organization

### SketchyBar Integration
- Real-time status updates in macOS menu bar
- Session indicators
- Quick access to Claude status

### Status Overlay
- Comprehensive dashboard of all active Claude sessions
- Multi-project monitoring
- Session details: model, directory, git status
- Triggered via kitty overlay (Cmd+Shift+C)

## Installation

### Via Marketplace (Recommended)

```bash
/plugin install dotfiles-ui-hooks
```

### Requirements

This plugin depends on:
- `dotfiles-utils@dotfiles` - Shared utilities (automatically installed)
- Python 3.8+ (for voice notification system)
- macOS (for voice notifications)
- Obsidian (optional, for logging)
- SketchyBar (optional, for menu bar integration)

## Configuration

### Voice Configuration

The plugin includes a template `config/voice-config.json` with settings for:
- Voice selection per project
- Message styles and tones
- Event-specific configurations
- Notification templates
- Quiet hours

Copy to `~/.claude/voice-config.json` and customize.

### Hook Integration

Hooks are automatically configured when the plugin is enabled. The following hooks are available:

**UserPromptSubmit:**
- `sketchybar-trigger.sh` - Update menu bar
- `obsidian-logger.sh` - Log conversation start

**Stop:**
- `voice-notify.sh` - Voice notification on completion
- `obsidian-log-complete.sh` - Finalize conversation log
- `sketchybar-trigger.sh` - Update menu bar status

**PreToolUse:**
- `pre-commit-fix.sh` - Auto-format before git operations

## Scripts

### Status Overlay

```bash
# Show comprehensive Claude status dashboard
~/.local/share/claude/plugins/dotfiles-ui-hooks/scripts/show-status-overlay.sh
```

Displays all active Claude sessions with:
- Current model and workspace
- Git repository status
- Output style and configuration
- Session timestamps

### Statusline Command

Provides real-time statusline information for Claude Code interface:
- Model name
- Current directory
- Git repository (owner/repo)
- Time

## Disabling Features

Edit `~/.claude/settings.json` and configure:

```json
{
  "hooks": {
    "enable_voice_notifications": false,
    "enable_obsidian_logging": false,
    "enable_sketchybar": false
  }
}
```

Or disable the entire plugin:

```bash
/plugin disable dotfiles-ui-hooks
```

## Documentation

- `docs/hooks-guide.md` - Comprehensive hooks documentation
- `docs/VOICE_NOTIFICATIONS.md` - Voice notification system details

## Troubleshooting

### Voice notifications not working
- Verify Python 3.8+ is installed
- Check `~/.claude/voice-config.json` exists
- Ensure macOS text-to-speech is available

### Obsidian logging fails
- Verify Obsidian vault path in configuration
- Check file permissions
- Ensure Python dependencies are installed

### Status overlay not appearing
- Verify kitty terminal is being used
- Check hotkey configuration (Cmd+Shift+C)
- Ensure lib utilities are available from dotfiles-utils plugin

## License

Same license as the dotfiles repository.

## Author

**Lauri Gates**
- GitHub: [@laurigates](https://github.com/laurigates)
- Email: laurigates@users.noreply.github.com
