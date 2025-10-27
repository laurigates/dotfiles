# Claude Code Hooks Guide

## Overview

Hooks are shell commands that execute at specific points in Claude's workflow, enabling custom automation and integrations.

## Available Hooks

### UserPromptSubmit

Executes when you submit a prompt to Claude.

**Current implementations:**
- **Sketchybar trigger** - Updates macOS menu bar status
- **Obsidian logger** - Logs conversation to Obsidian vault

```json
"UserPromptSubmit": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "~/.claude/hooks/obsidian-logger.sh",
        "timeout": 3000
      }
    ]
  }
]
```

### PreToolUse

Executes before Claude uses a specific tool, based on matcher patterns.

**Current implementations:**

**1. Skip tracking tools (no hooks)**
```json
{
  "matcher": "Task|Read|Grep|Search|TodoWrite|mcp__graphiti-memory__search.*|WebFetch|WebSearch|Glob|LS",
  "hooks": []
}
```

**2. GitHub PR context**
```json
{
  "matcher": "mcp__github__create_pull_request",
  "hooks": [{
    "type": "command",
    "command": "gh repo view --json nameWithOwner --template 'github repository name with owner: {{.nameWithOwner}}'"
  }]
}
```
Injects repo context before creating PRs.

**3. Pre-commit formatting**
```json
{
  "matcher": "Bash(git add*)",
  "hooks": [{
    "type": "command",
    "command": "~/.claude/hooks/pre-commit-fix.sh",
    "timeout": 10000
  }]
}
```
Runs formatting/linting before staging files.

### Stop

Executes when Claude finishes responding.

**Current implementations:**
- **Sketchybar trigger** - Updates status to "idle"
- **Voice notifications** - Text-to-speech completion announcement
- **Obsidian log complete** - Finalizes conversation log entry

```json
"Stop": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "~/.claude/hooks/voice-notify.sh",
        "timeout": 5000
      }
    ]
  }
]
```

## Hook Scripts

Located in `dot_claude/hooks/` (managed by chezmoi):

### obsidian-logger.sh
Logs Claude conversations to Obsidian vault for knowledge management.

**Features:**
- Structured markdown output
- Automatic timestamping
- Context extraction
- Conversation threading

**Configuration:** Set vault path in script or environment

### voice-notify.sh
Text-to-speech notifications when Claude completes.

**Features:**
- macOS `say` command integration
- Configurable voice and rate
- Completion status announcements

### pre-commit-fix.sh
Runs code formatting and linting before git operations.

**Features:**
- Auto-format staged files
- Run pre-commit hooks
- Prevent commits with errors

**Tools:**
- Python: ruff, black
- Shell: shellcheck, shfmt
- General: pre-commit framework

### sketchybar-trigger.sh
Updates macOS Sketchybar with Claude status.

**States:**
- Active (user typing)
- Thinking (Claude processing)
- Idle (waiting)

## Configuration

Hooks are configured via `.chezmoidata.toml`:

```toml
[claude_hooks]
enable_sketchybar = true
enable_obsidian_logging = true
enable_voice_notifications = true
enable_pre_commit_formatting = true
enable_gh_context = true
```

Changes take effect after `chezmoi apply -v`.

## Creating Custom Hooks

### 1. Write Hook Script

Create executable script in `dot_claude/hooks/`:

```bash
#!/usr/bin/env bash
# dot_claude/hooks/executable_my-hook.sh

# Script receives stdin with context
# Exit 0 for success, non-zero for failure

echo "Hook executed at $(date)"
```

Note: `executable_` prefix makes chezmoi set execute permissions.

### 2. Add to Settings Template

Edit `dot_claude/settings.json.tmpl`:

```json
{{- if .my_custom_hook_enabled }}
  {
    "type": "command",
    "command": "~/.claude/hooks/my-hook.sh",
    "timeout": 3000
  }
{{- end }}
```

### 3. Configure in chezmoidata

Edit `.chezmoidata.toml`:

```toml
my_custom_hook_enabled = true
```

### 4. Apply Changes

```bash
chezmoi apply -v
```

## Hook Context

Hooks receive information via:

### Environment Variables
- `CLAUDE_MODE` - Current operation mode
- `CLAUDE_TOOL` - Tool being executed (PreToolUse only)

### Standard Input
JSON payload with conversation context (varies by hook type)

### Exit Codes
- `0` - Success, continue normal operation
- `non-zero` - Failure, may block operation (depends on hook type)

## Timeouts

Set appropriate timeouts based on hook complexity:

- **Fast hooks** (status updates): 1000-3000ms
- **Medium hooks** (logging): 3000-5000ms
- **Slow hooks** (formatting, linting): 5000-10000ms

Hooks timing out are killed and logged as errors.

## Debugging Hooks

### Enable verbose logging

```bash
# Add to hook script
set -x  # Print commands as executed

# Or run hook manually
bash -x ~/.claude/hooks/my-hook.sh
```

### Check hook execution

Claude logs hook execution in console output. Look for:
- Hook start/complete messages
- Error output
- Timeout warnings

### Test hooks independently

```bash
# Run hook directly
~/.claude/hooks/pre-commit-fix.sh

# Check exit code
echo $?
```

## Security Considerations

1. **Validate input** - Don't trust hook context blindly
2. **Limit permissions** - Hooks run with your user permissions
3. **Timeout appropriately** - Prevent hanging operations
4. **Review output** - Hooks can inject content into Claude's context
5. **Version control** - Track hook changes in git

## Examples

### Slack Notification Hook

```bash
#!/usr/bin/env bash
# Notify team when important operations complete

WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

curl -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "{\"text\": \"Claude completed task at $(date)\"}"
```

### Project Context Injection Hook

```bash
#!/usr/bin/env bash
# Inject project-specific context before tool use

if [[ "$CLAUDE_TOOL" == "mcp__github__create_issue" ]]; then
  # Add project labels, assignees, etc.
  echo "Default labels: bug,needs-triage"
fi
```

### Time Tracking Hook

```bash
#!/usr/bin/env bash
# Log time spent in Claude sessions

LOG_FILE=~/.claude/time-log.txt
echo "$(date): Session activity" >> "$LOG_FILE"
```

## Troubleshooting

### Hook not executing
- Check hook is executable: `ls -la ~/.claude/hooks/`
- Verify matcher pattern matches the tool
- Check chezmoi template syntax

### Hook timing out
- Increase timeout value
- Optimize hook for speed
- Move slow operations to background

### Hook failing silently
- Add error logging to hook script
- Check Claude console output
- Test hook manually with sample input

## Best Practices

1. **Keep hooks fast** - Avoid blocking Claude unnecessarily
2. **Handle errors gracefully** - Don't crash on unexpected input
3. **Log appropriately** - Balance verbosity with usefulness
4. **Test thoroughly** - Verify hooks work in all scenarios
5. **Document behavior** - Explain what hooks do and why
6. **Version control** - Track hook changes alongside code
