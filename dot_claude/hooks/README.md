# Claude Code Hooks - Refactored Documentation

## Overview

The Claude Code hook system provides automated notifications and logging when Claude completes tasks. This refactored version simplifies the architecture and improves reliability.

## Architecture

### Simplified Pipeline

```
Claude Code → assistant-response-complete.sh → context_extractor.py → ┬→ voice-notify/notify_simple.py
                                                                       └→ obsidian-logger/obsidian_logger.py
```

### Key Components

1. **context_extractor.py** - Unified context extraction from transcripts
2. **assistant-response-complete.sh** - Main hook that orchestrates everything
3. **voice-notify/notify_simple.py** - Context-aware voice notifications
4. **obsidian-logger/obsidian_logger.py** - Activity logging to Obsidian vault

## Features

### Context-Aware Notifications

Instead of generic "Task completed" messages, you now get specific notifications:
- "Updated hooks.py and config.json"
- "All 42 tests passed"
- "Committed 3 files"
- "Ran ruff linting"
- "Built the project"

### Reliable Logging

The Obsidian logger now reliably writes to your vault with specific activity details:
- `🐍 Modified hooks.py`
- `✅ 15 tests passed`
- `💾 Committed config.json`
- `📦 Built project`

### Debug Mode

Enable comprehensive debugging to troubleshoot issues:
```bash
export CLAUDE_HOOKS_DEBUG=true
tail -f /tmp/claude_hooks_debug.log
```

## Installation

1. Ensure Python 3 is installed
2. Install jq for JSON processing (optional but recommended):
   ```bash
   brew install jq
   ```
3. For voice notifications with Gemini TTS (optional):
   ```bash
   export GEMINI_API_KEY=your_api_key
   ```
4. Configure Obsidian vault path if different from default:
   ```bash
   export OBSIDIAN_VAULT_PATH="/path/to/your/vault"
   ```

## Testing

Run the diagnostic script to verify everything works:
```bash
./hooks/test_hooks.sh
```

This will test:
- Environment setup
- Context extraction
- Voice notification generation
- Obsidian logging
- Complete pipeline execution

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CLAUDE_HOOKS_DEBUG` | Enable debug logging | `false` |
| `CLAUDE_VOICE_ENABLED` | Enable voice notifications | `true` |
| `CLAUDE_VOICE_VOLUME` | Voice volume (0.0-1.0) | `0.7` |
| `GEMINI_API_KEY` | API key for Gemini TTS | (none) |
| `OBSIDIAN_VAULT_PATH` | Path to Obsidian vault | `/Users/lgates/Documents/FVH Vault` |
| `OBSIDIAN_LOGGER_ENABLED` | Enable Obsidian logging | `true` |

### Voice Configuration

Edit `~/.claude/voice-config.json` to customize voices per project:
```json
{
  "enabled": true,
  "default_voice": "Samantha",
  "volume": 0.7,
  "projects": {
    "my-project": {
      "voice": "Alex"
    }
  }
}
```

## Troubleshooting

### Voice notifications saying generic messages

**Problem**: Voice says "Task completed" instead of specific details
**Solution**:
1. Enable debug mode: `export CLAUDE_HOOKS_DEBUG=true`
2. Check if transcript is being found: Look for "Extracted transcript path" in debug log
3. Verify context extraction: Look for "Extracted context" in debug log

### Obsidian logger not writing

**Problem**: DailyLog.md not being updated
**Solution**:
1. Check vault path exists: `ls -la "$OBSIDIAN_VAULT_PATH/Inbox"`
2. Verify write permissions: `touch "$OBSIDIAN_VAULT_PATH/Inbox/test.md"`
3. Enable debug mode and check for errors in `/tmp/claude_hooks_debug.log`

### No notifications at all

**Problem**: Complete silence after Claude completes
**Solution**:
1. Run diagnostic test: `./hooks/test_hooks.sh`
2. Check hook is executable: `ls -la hooks/executable_assistant-response-complete.sh`
3. Verify Claude Code settings include the hook

## How It Works

### Context Extraction

The `context_extractor.py` analyzes Claude's transcript to identify:
- Files that were modified
- Commands that were run
- Test results
- Git operations
- Errors encountered

### Message Generation

Based on the extracted context, specific messages are generated:

```python
# Example context
{
  "primary_activity": "modified_python",
  "files_modified": ["hooks.py", "config.py"],
  "success": true
}

# Generated message
"Updated hooks.py and config.py"
```

### Fallback Behavior

If any component fails, the system gracefully degrades:
- No transcript → Generic "Task completed" message
- No Gemini API → macOS `say` command
- No context → Simple activity-based message

## Extending

### Adding New Activity Types

Edit `context_extractor.py` to detect new activities:
```python
def _determine_primary_activity(self, context):
    # Add your detection logic
    if 'docker' in ' '.join(context.get('commands_run', [])):
        return 'docker_operation'
```

Then update message generation in `notify_simple.py`:
```python
elif activity == 'docker_operation':
    return "Updated Docker configuration"
```

### Custom Logging Formats

Modify `obsidian_logger.py` to customize log entries:
```python
elif activity == 'your_custom_activity':
    return f"🎯 {your_custom_message}"
```

## Benefits of Refactored System

1. **Simplicity**: Reduced from ~10 scripts to 4 core files
2. **Reliability**: Removed silent failures and complex pipelines
3. **Debuggability**: Comprehensive logging and test script
4. **Specificity**: Context-aware messages instead of generic ones
5. **Maintainability**: Clear separation of concerns
6. **Performance**: Direct data flow without multiple JSON conversions

## Migration Notes

If you had the old hook system:
1. The new system preserves all existing functionality
2. Old configuration files are still respected
3. The simplified pipeline is more reliable
4. Debug mode helps identify any issues

## Support

Check the debug log for detailed information:
```bash
tail -f /tmp/claude_hooks_debug.log
```

Run the diagnostic test for a health check:
```bash
./hooks/test_hooks.sh
```
