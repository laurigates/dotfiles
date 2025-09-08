# Claude Voice Notification System

Voice notifications for Claude Code using Gemini API text-to-speech with accurate context reporting, project-specific voices, and macOS fallback.

## Features

- **Accurate Context Reporting**: Reports exactly what was done (files modified, commands run, tests passed)
- **Gemini API TTS**: High-quality text-to-speech with 30+ voice options
- **Native Audio Support**: Ready for Gemini 2.5 Flash Native Audio Dialog (when available)
- **Project-Specific Voices**: Different voice personalities per repository
- **Dynamic Speech Styles**: Context-aware tone (cheerful, concerned, patient)
- **macOS Fallback**: Uses native `say` command when API unavailable
- **Audio Caching**: Reduces API calls for frequently used phrases
- **Debug Mode**: Trace context extraction and message generation
- **Configurable AI Summaries**: Optional AI-generated summaries (disabled by default for accuracy)

## Installation

This project is managed by uv and integrated with Claude Code hooks.

```bash
cd ~/.claude/hooks/voice-notify
uv sync
```

## Configuration

Edit `~/.claude/voice-config.json` to customize voices and styles.

## Usage

### Via Claude Hooks
Automatically triggered when Claude completes tasks through the `assistant-response-complete.sh` hook.

### Manual Testing
```bash
# Test voice notification
cd ~/.claude/hooks/voice-notify
uv run python notify.py "Test message" "project-name" "success"

# Or use the voice-test alias
voice-test "Test message" "project-name" "success"
```

### Configuration Tool
```bash
cd ~/.claude/hooks/voice-notify

# Check current status
uv run python config.py status

# Test voice notification
uv run python config.py test

# Interactive setup wizard
uv run python config.py setup

# Switch between TTS models
uv run python config.py model tts      # Traditional TTS (default)
uv run python config.py model native-audio  # Native Audio Dialog (when available)

# Toggle notifications
uv run python config.py toggle
```

## Available Voices

### Featured Voices
- **Zephyr**: Bright, clear voice
- **Puck**: Upbeat, energetic voice
- **Kore**: Firm, professional voice

### Additional Gemini Voices
Aoede, Charon, Clementine, Fenrir, Juno, and 20+ more voices available through the Gemini API.

## Configuration File Structure

The `~/.claude/voice-config.json` file supports:

```json
{
  "enabled": true,
  "model": "tts",              // "tts" or "native-audio"
  "default_voice": "Zephyr",
  "default_style": "cheerful",
  "language": "en-GB",         // Supports multiple languages
  "volume": 0.7,
  "use_cache": true,
  "projects": {
    "my-project": {
      "voice": "Puck",
      "style": "energetic",
      "language": "en-US"      // Per-project language override
    }
  },
  "message_styles": {
    "success": "cheerfully",
    "error": "with concern",
    "waiting": "patiently",
    "tool_use": "professionally",
    "neutral": "calmly"
  }
}
```

## Environment Variables

Control behavior through environment variables:

```bash
# Enable AI-generated summaries (default: false for accuracy)
export CLAUDE_VOICE_USE_AI_SUMMARIES=false

# Enable debug mode to trace message generation
export CLAUDE_VOICE_DEBUG=true

# Override voice language
export CLAUDE_VOICE_LANGUAGE=en-US
```

## Requirements

- Python 3.10+
- macOS (for audio playback via `afplay`)
- GEMINI_API_KEY environment variable (optional, falls back to macOS say)
- uv package manager

## Development

### Running Tests
```bash
cd ~/.claude/hooks/voice-notify
uv run pytest
```

### Code Quality
```bash
uv run ruff check .
uv run ruff format .
```

## How It Works

### Accurate Context Reporting
The system extracts actual context from Claude's transcript files to report exactly what was done:

1. **Transcript Analysis**: Parses Claude Code transcript JSONL files to identify:
   - Files modified (Edit, Write, MultiEdit tools)
   - Commands executed (Bash tool)
   - Test results (pytest, npm test output)
   - Git operations (commits, pushes)
   - Build/lint operations

2. **Template-Based Messages**: Generates specific messages based on actual data:
   - "Updated 2 Python files including notify.py"
   - "All tests passed! 15 tests passed"
   - "Ran linting: ruff check . --fix"
   - "Executed: docker-compose up -d --build"
   - "Made a git commit with changes to README.md"

3. **Fallback Strategy**: Only uses generic messages when no context is available

### Message Generation Pipeline
```
Claude Transcript → Context Extractor → Template Summarizer → Voice Synthesis
```

## Technical Details

### Audio Processing
The system receives raw PCM audio data from Gemini API and converts it to WAV format using an efficient in-memory approach with `struct.pack`, avoiding the overhead of file I/O operations.

### Caching
Audio files are cached as WAV files in `~/.claude/voice-cache/` to reduce API calls for repeated messages.

### Model Support
- **TTS Model** (`gemini-2.5-flash-preview-tts`): Traditional text-to-speech with voice selection
- **Native Audio Dialog** (`gemini-2.5-flash-preview-native-audio-dialog`): Conversational synthesis (ready when available)

### Integration
The voice notification system is integrated with Claude Code's hook system, specifically the `assistant-response-complete` hook, which triggers notifications when Claude finishes responding.

## Troubleshooting

1. **No sound**: Check that your GEMINI_API_KEY is set and valid
2. **Generic messages**: Ensure `CLAUDE_VOICE_USE_AI_SUMMARIES=false` (default) for accurate reporting
3. **Debug messages**: Set `CLAUDE_VOICE_DEBUG=true` to see context extraction and message generation
4. **Fallback to say command**: The system automatically falls back to macOS `say` if Gemini API is unavailable
5. **Cache issues**: Clear `~/.claude/voice-cache/` if you experience stale audio
6. **Wrong language**: Check language setting in config or set `CLAUDE_VOICE_LANGUAGE`

## License

Part of the Claude Code configuration system managed by chezmoi.
