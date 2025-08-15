# Claude Code + Kitty Integration

This integration provides dynamic tab titles and a central status hub for Claude Code sessions in kitty terminal.

## Features

### Dynamic Tab Titles
- Shows repository name + current Claude status
- Format: `[repo-name] | [status]`
- Status indicators:
  - `Processing...` - User submitted prompt
  - `🤖 Responding...` - Claude is generating response
  - `✓ Ready` - Response complete, ready for next prompt

### Central Status Hub
- Dedicated tab showing all Claude activity across sessions
- Real-time table of timestamps, repositories, and statuses
- Automatically updates when Claude responds
- Shows last 20 activities

## Setup

### Prerequisites
1. **Kitty terminal** with remote control enabled
2. **Claude Code** installed and configured
3. Add to `kitty.conf`:
   ```
   allow_remote_control yes
   ```

### Installation
1. Apply dotfiles with chezmoi:
   ```bash
   chezmoi apply -v
   ```

2. Run setup script:
   ```bash
   ~/.claude/setup_kitty_integration.sh
   ```

3. Start using Claude in different repositories to see it work!

## Files Created

### Hook Scripts
- `~/.claude/hooks/user-prompt-submit.sh`
- `~/.claude/hooks/assistant-response-start.sh`
- `~/.claude/hooks/assistant-response-complete.sh`

### Configuration
- `~/.claude/settings.json` - Enables Claude Code hooks

### Utilities
- `~/.claude/setup_kitty_integration.sh` - One-time setup
- `/tmp/claude_status_hub.log` - Status log file

## How It Works

1. **Hook Events**: Claude Code calls hook scripts on specific events
2. **Repository Detection**: Scripts detect current Git repository name
3. **Tab Title Updates**: Uses `kitty @ set-tab-title` to update current tab
4. **Hub Updates**: Appends to log file and sends display to hub tab
5. **Real-time Display**: Hub tab shows formatted table of all activity

## Kitty Remote Control Commands Used

```bash
# Set tab title
kitty @ set-tab-title "repo-name | status"

# Send text to specific tab
kitty @ send-text --match "title:Claude Hub" --stdin

# Create new tab
kitty @ new-tab --title "Claude Hub"
```

## Troubleshooting

### Tab titles not updating
- Check that `allow_remote_control yes` is in kitty.conf
- Verify you're running in kitty (`echo $TERM` should show `xterm-kitty`)
- Test with: `kitty @ set-tab-title "test"`

### Hub tab not updating
- Check that hub tab exists (title: "Claude Hub")
- Verify `/tmp/claude_status_hub.log` file exists and has content
- Test manually: `cat /tmp/claude_status_hub.log`

### Hooks not running
- Check that `~/.claude/settings.json` exists and has hooks configured
- Verify hook scripts are executable: `chmod +x ~/.claude/hooks/*.sh`
- Test hook manually: `~/.claude/hooks/user-prompt-submit.sh`

## Customization

### Modify Status Messages
Edit the hook scripts to change status text:
- `user-prompt-submit.sh`: Change "Processing..."
- `assistant-response-start.sh`: Change "🤖 Responding..."
- `assistant-response-complete.sh`: Change "✓ Ready"

### Change Hub Display Format
Modify the `generate_hub_display()` function in any hook script to customize the table format.

### Add More Hook Events
Claude Code supports additional hooks - add them to `settings.json` and create corresponding scripts.

## Repository Integration

This integration is part of a chezmoi-managed dotfiles repository:
- Templates enable cross-platform compatibility
- Hook scripts are marked executable via chezmoi
- Configuration integrates with existing Claude setup
- No manual file copying required

Perfect for developers working across multiple repositories who want better visibility into their Claude Code sessions!
