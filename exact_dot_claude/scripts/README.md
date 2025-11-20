# Claude Config Pruner

A Python tool to clean up your `~/.claude.json` configuration file by removing orphaned projects and cached data.

## Features

- **Safe pruning**: Creates timestamped backups before making changes
- **Dry-run mode**: Preview changes without modifying anything
- **Interactive mode**: Confirm before applying changes
- **Detailed statistics**: Shows what will be removed and space savings
- **Preserves important data**: Keeps settings, MCP servers, tips history, OAuth account

## What Gets Removed

- **Orphaned projects**: Project entries for directories that no longer exist on disk
- **Cached data**: Temporary caches that will be automatically re-fetched:
  - `cachedChangelog` - Release notes cache
  - `cachedStatsigGates` - Feature flags cache
  - `cachedDynamicConfigs` - Configuration cache

## Installation

### Option 1: Use directly from ~/.claude/scripts

Add to your shell profile (~/.zshrc or ~/.bashrc):

```bash
alias claude-prune='~/.claude/scripts/prune-claude-config.py'
```

### Option 2: Install as a user tool with uv

```bash
uv tool install --from ~/.claude/scripts prune-claude-config.py
```

### Option 3: Symlink to ~/.local/bin

```bash
mkdir -p ~/.local/bin
ln -s ~/.claude/scripts/prune-claude-config.py ~/.local/bin/claude-prune
```

Make sure `~/.local/bin` is in your PATH.

## Usage

### Preview changes (recommended first step)

```bash
prune-claude-config.py --dry-run
```

### Interactive mode (with confirmation prompt)

```bash
prune-claude-config.py --interactive
```

### Run immediately (creates backup automatically)

```bash
prune-claude-config.py
```

### Use custom config path

```bash
prune-claude-config.py --config /path/to/claude.json
```

### Show help

```bash
prune-claude-config.py --help
```

## Examples

**Safe exploration:**
```bash
# See what would be cleaned
prune-claude-config.py --dry-run

# Review and confirm before applying
prune-claude-config.py --interactive
```

**Regular maintenance:**
```bash
# Quick cleanup (automatic backup is created)
prune-claude-config.py
```

## Scheduling (Optional)

You can schedule regular cleanups using cron or launchd.

### Weekly cleanup with launchd (macOS)

Create `~/Library/LaunchAgents/com.user.claude-prune.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.claude-prune</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/lgates/.claude/scripts/prune-claude-config.py</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/claude-prune.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/claude-prune.error.log</string>
</dict>
</plist>
```

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.user.claude-prune.plist
```

## Backups

Backups are stored with timestamp suffixes:
```
~/.claude.json.backup.20251117_184941
~/.claude.json.backup.20251118_093022
```

You can safely delete old backups once you've verified the pruned config works correctly.

## Requirements

- Python 3.7+
- Standard library only (no external dependencies)

## Troubleshooting

**"Configuration file not found"**
- Check that `~/.claude.json` exists
- Use `--config` to specify a different path

**"Invalid JSON in configuration file"**
- Your config file may be corrupted
- Restore from a backup if available
- Contact Claude Code support if needed

**Script doesn't run**
- Ensure it's executable: `chmod +x ~/.claude/scripts/prune-claude-config.py`
- Check Python 3 is available: `python3 --version`
- Try running with: `python3 ~/.claude/scripts/prune-claude-config.py`

## Contributing

This script is part of your personal Claude Code setup managed via chezmoi. To update:

1. Edit the script in `~/.local/share/chezmoi/exact_dot_claude/scripts/`
2. Apply changes: `chezmoi apply -v ~/.claude`

## License

Personal use tool - modify as needed.
