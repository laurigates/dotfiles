# Obsidian Daily Logger

Automatically logs Claude Code activities to your Obsidian vault for daily note processing and activity tracking.

## Features

- **Automatic Activity Logging**: Captures all Claude Code activities
- **Smart Summarization**: Uses Gemini API to generate concise, meaningful log entries
- **Emoji Prefixes**: Visual indicators for different activity types
- **Project Context**: Includes repository/project names when available
- **Fail-Safe**: Silent failures won't interrupt Claude Code operations
- **Configurable**: Environment variables for customization

## Configuration

### Environment Variables

- `OBSIDIAN_VAULT_PATH`: Path to your Obsidian vault (default: `/Users/lgates/Documents/FVH Vault`)
- `OBSIDIAN_LOGGER_ENABLED`: Enable/disable logging (default: `true`)
- `OBSIDIAN_LOGGER_USE_GEMINI`: Use Gemini API for summaries (default: `true`)
- `OBSIDIAN_LOGGER_MODEL`: Gemini model to use (default: `gemini-2.5-flash`)
- `GEMINI_API_KEY`: Your Gemini API key (required for AI summaries)

### Log Location

Logs are written to: `{VAULT_PATH}/Inbox/DailyLog.md`

## Log Format

Each entry follows this format:
```
[YYYY-MM-DD HH:MM] 📝 Activity description (project-name)
```

### Activity Emojis

- 📝 Created
- ✏️ Modified
- 🔧 Fixed
- 🔍 Analyzed
- ⚙️ Configured
- 📚 Documented
- ✅ Tests passed
- ❌ Tests failed
- 💾 Git commit
- 🚀 Git push
- 📦 Building
- 🧹 Linting
- 🐛 Debugging
- ♻️ Refactoring
- 📥 Installing
- ⚠️ Error
- 💡 General

## Examples

```markdown
[2025-01-09 14:32] 🔧 Fixed linting errors in voice-notify.py (claude-code)
[2025-01-09 14:45] 📝 Created obsidian logger hook module (chezmoi)
[2025-01-09 15:01] ✅ All 42 tests passing (backend-api)
[2025-01-09 15:15] 🚀 Deployed to production environment (web-app)
[2025-01-09 15:30] 🐛 Debugged authentication issue (auth-service)
```

## How It Works

1. **Hook Trigger**: Runs on `UserPromptSubmit` event
2. **Context Parsing**: Extracts activity context from Claude's response
3. **Summary Generation**: Uses Gemini API or templates to create concise summaries
4. **Log Append**: Adds timestamped entry to DailyLog.md
5. **Silent Operation**: Failures don't interrupt Claude Code

## Testing

```bash
# Test with sample context
echo '{"context": {"primary_activity": "created", "files_modified": ["test.py"]}}' | \
    python hooks/obsidian-logger/obsidian_logger.py

# Check the log
cat ~/Documents/FVH\ Vault/Inbox/DailyLog.md
```

## Troubleshooting

### Logs Not Appearing

1. Check if enabled: `echo $OBSIDIAN_LOGGER_ENABLED`
2. Verify vault path exists: `ls -la "$OBSIDIAN_VAULT_PATH/Inbox"`
3. Check permissions: `touch "$OBSIDIAN_VAULT_PATH/Inbox/DailyLog.md"`

### Gemini API Issues

1. Verify API key: `echo $GEMINI_API_KEY`
2. Test API directly: `python hooks/obsidian-logger/obsidian_logger.py`
3. Fall back to templates: `export OBSIDIAN_LOGGER_USE_GEMINI=false`

## Integration with Daily Notes

The DailyLog.md file is designed to be processed by your daily note workflow:

1. Parse entries by date
2. Group by project
3. Summarize activities
4. Generate insights

Example Obsidian template:
```markdown
## Today's Activities

```dataview
LIST item.text
FROM "Inbox/DailyLog.md"
WHERE contains(item.text, dateformat(date(today), "yyyy-MM-dd"))
```
```
