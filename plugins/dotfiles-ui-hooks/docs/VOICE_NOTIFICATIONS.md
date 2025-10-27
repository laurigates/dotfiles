# Claude Code Voice Notification System

A sophisticated voice notification system that provides contextual, spoken feedback when Claude Code completes tasks. Uses Google's Gemini API for natural text-to-speech with intelligent context extraction from conversation transcripts.

## Features

- **Accurate Reporting**: Reports exactly what was done (files modified, commands run, tests passed) instead of generic messages
- **Contextual Notifications**: Extracts actual work performed from Claude's transcript to generate relevant messages
- **Natural Speech**: Uses Gemini 2.5 Flash TTS for high-quality, natural-sounding voice output
- **Project Awareness**: Automatically includes project name in notifications
- **Event-Based Styling**: Different notification styles for success, errors, tests, creation, etc.
- **Smart Caching**: Caches generated audio for repeated messages
- **Fallback Support**: Falls back to macOS `say` command when Gemini is unavailable
- **Debug Mode**: Trace context extraction and message generation with `CLAUDE_VOICE_DEBUG=true`
- **AI Control**: Optional AI summaries (disabled by default for accuracy)

## Components

### Core Scripts

1. **`voice-notify.py`** - Main TTS engine
   - Handles Gemini API integration
   - Manages voice configuration per project
   - Implements audio caching
   - Provides macOS fallback

2. **`casual_summarizer.py`** - Message generation
   - Creates accurate, template-based summaries from actual context
   - Optional Gemini AI generation (disabled by default)
   - Reports specific files, commands, and test results
   - Falls back to generic templates only when no context available

3. **`transcript_context_extractor.py`** - Context extraction
   - Reads Claude Code JSONL transcripts
   - Extracts files modified, commands run, test results
   - Determines primary activity and success indicators

4. **`assistant-response-complete.sh`** - Hook integration
   - Triggered when Claude completes a response
   - Reads stdin JSON to get transcript path
   - Orchestrates the notification pipeline

## Setup

### Prerequisites

1. **Python Dependencies** (managed via uv):
   ```bash
   cd ~/.claude/hooks
   uv pip install google-genai
   ```

2. **Google API Key**:
   ```bash
   export GEMINI_API_KEY="your-api-key-here"  # pragma: allowlist secret
   ```

3. **Language Setting** (optional):
   ```bash
   # Set voice language (default: en-GB)
   export CLAUDE_VOICE_LANGUAGE="fi-FI"  # Finnish
   export CLAUDE_VOICE_LANGUAGE="en-GB"  # British English
   # Other examples: es-ES, fr-FR, de-DE, ja-JP, pt-BR
   ```

4. **Executable Permissions**:
   ```bash
   chmod +x ~/.claude/hooks/executable_assistant-response-complete.sh
   chmod +x ~/.claude/hooks/*.py
   ```

### Configuration

Voice settings are stored in `~/.claude/voice-config.json`:

```json
{
  "enabled": true,
  "model": "tts",              // "tts" or "native-audio"
  "default_voice": "Zephyr",
  "language": "en-GB",         // Default to British English
  "volume": 0.7,
  "use_cache": true,
  "projects": {
    "my-project": {
      "voice": "Puck",
      "style": "professional",
      "language": "fi-FI"      // Finnish for this project
    },
    "infrastructure": {
      "voice": "Kore",
      "language": "en-US"      // American English for this project
    }
  },
  "message_styles": {
    "success": "cheerfully",
    "error": "with concern",
    "test_success": "happily"
  }
}
```

### Environment Variables

```bash
# Control AI summary generation (disabled by default for accuracy)
export CLAUDE_VOICE_USE_AI_SUMMARIES=false

# Enable debug mode to see what's happening
export CLAUDE_VOICE_DEBUG=true

# Override language globally
export CLAUDE_VOICE_LANGUAGE=en-US
```

#### Language Configuration Priority

The system checks for language settings in this order:
1. **Environment Variable**: `CLAUDE_VOICE_LANGUAGE` (highest priority)
2. **Project-specific**: Language defined for the current project in config
3. **Default**: Language in main config (defaults to `en-GB`)

#### Supported Languages

Gemini TTS supports many languages including:
- **English**: `en-GB` (British), `en-US` (American), `en-AU` (Australian), `en-IN` (Indian)
- **Finnish**: `fi-FI`
- **Spanish**: `es-ES`, `es-MX`, `es-US`
- **French**: `fr-FR`, `fr-CA`
- **German**: `de-DE`
- **Italian**: `it-IT`
- **Portuguese**: `pt-BR`, `pt-PT`
- **Japanese**: `ja-JP`
- **Korean**: `ko-KR`
- **Chinese**: `zh-CN`, `zh-TW`
- **Russian**: `ru-RU`
- **Arabic**: `ar-XA`
- **Hindi**: `hi-IN`
- **Dutch**: `nl-NL`
- **Polish**: `pl-PL`
- **Turkish**: `tr-TR`
- **Swedish**: `sv-SE`
- **Norwegian**: `nb-NO`
- **Danish**: `da-DK`

### Available Voices

- **Zephyr** - Default, balanced voice
- **Puck** - More energetic
- **Kore** - Professional tone

## How It Works

1. **Claude completes a task** → Stop hook triggers
2. **Hook receives JSON** with `transcript_path` via stdin
3. **Context extracted** from last 100 lines of JSONL transcript
4. **Gemini generates** casual message based on context
5. **TTS converts** message to speech with appropriate voice
6. **Audio plays** through speakers

### Example Notifications

Accurate reporting based on actual context:

- ✅ "Updated 2 Python files including notify.py"
- 📦 "Modified 5 files including app.ts"
- ✅ "All tests passed! 15 tests passed"
- ⚠️ "Tests completed: 3 tests failed"
- 🎯 "Executed: docker-compose up -d --build"
- 📝 "Updated documentation in README.md, CONTRIBUTING.md"
- 🔧 "Ran linting: ruff check . --fix"
- 💾 "Made a git commit with changes to setup.py, requirements.txt"
- 🏗️ "Built the project"
- 📦 "Installed project dependencies"

## Context Extraction

The system analyzes:
- **Tools used**: Edit, Write, Bash, etc.
- **Files modified**: Tracks which files were created/updated
- **Commands run**: Captures executed shell commands
- **Test results**: Detects test passes/failures
- **Error patterns**: Identifies encountered errors
- **User requests**: Remembers the original ask

## Troubleshooting

### No Sound
```bash
# Check if hook is executable
ls -la ~/.claude/hooks/executable_assistant-response-complete.sh

# Test voice system directly
cd ~/.claude/hooks
echo '{"context": {"project_name": "test"}, "event_type": "success"}' | \
  uv run python casual_summarizer.py | \
  xargs -I {} uv run python voice-notify.py "{}" "test" "success"
```

### Generic Messages
- Ensure transcript file exists and is readable
- Check that `transcript_context_extractor.py` is present
- Verify JSON is being passed correctly via stdin

### Gemini Issues
```bash
# Verify API key
echo $GEMINI_API_KEY

# Test Gemini directly
cd ~/.claude/hooks
uv run python -c "
from google import genai
client = genai.Client(api_key='$GEMINI_API_KEY')
print('Gemini connected successfully')
"
```

### Debug Mode
Enable logging in the scripts:
```python
logging.basicConfig(level=logging.DEBUG)
```

## Customization

### Adding Project-Specific Voices

Edit `~/.claude/voice-config.json`:
```json
"projects": {
  "your-project": {
    "voice": "Kore",
    "style": "professional"
  }
}
```

### Custom Message Templates

Modify templates in `casual_summarizer.py`:
```python
self.templates = {
    'success': [
        "Nailed it! {action} {target}!",
        "Boom! Just {action} {target}!"
    ]
}
```

### Adjusting Context Window

In `transcript_context_extractor.py`:
```python
# Increase lines read from transcript
context = extractor.extract_from_transcript(transcript_path, max_lines=200)
```

## Architecture

```
┌─────────────────────────┐
│   Claude Code Hook      │
│  (Stop Event Triggered) │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  assistant-response-    │
│     complete.sh         │
│  - Reads stdin JSON     │
│  - Extracts transcript  │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ transcript_context_     │
│    extractor.py         │
│  - Reads JSONL          │
│  - Extracts context     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  casual_summarizer.py   │
│  - Generates message    │
│  - Uses Gemini API      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│    voice-notify.py      │
│  - Gemini TTS           │
│  - Plays audio          │
└─────────────────────────┘
```

## Privacy & Security

- All processing happens locally
- Transcripts are only read from disk, never transmitted
- API calls to Gemini only contain summarized context
- Audio cache stored locally in `~/.claude/voice-cache/`
- No sensitive data included in notifications

## Performance

- Notifications trigger in background (non-blocking)
- Audio generation cached for repeated messages
- Typical latency: 1-2 seconds from task completion
- Fallback to `say` command is near-instant

## Recent Improvements

- [x] **Accurate Context Reporting**: Now reports actual files and commands instead of generic messages
- [x] **Template-Based Summaries**: Specific messages based on extracted context
- [x] **Debug Mode**: Added `CLAUDE_VOICE_DEBUG` for troubleshooting
- [x] **AI Control**: Made AI summaries optional (disabled by default)
- [x] **Native Audio Support**: Ready for Gemini 2.5 Flash Native Audio Dialog
- [x] **Model Selection**: Switch between TTS and native audio models

## Future Enhancements

- [ ] Custom wake words for attention
- [ ] Integration with system notifications
- [ ] Voice selection based on error severity
- [ ] User preference learning
- [ ] Notification history and replay
- [ ] Support for more granular context (line numbers, function names)
