# Claude Voice Notification System

Voice notifications for Claude Code using Gemini API text-to-speech with project-specific voices and macOS fallback.

## Features

- **Gemini API TTS**: High-quality text-to-speech with 30+ voice options
- **Project-Specific Voices**: Different voice personalities per repository
- **Dynamic Speech Styles**: Context-aware tone (cheerful, concerned, patient)
- **macOS Fallback**: Uses native `say` command when API unavailable
- **Audio Caching**: Reduces API calls for frequently used phrases
- **Efficient PCM-to-WAV**: Direct memory-based audio conversion

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
uv run python config.py status
uv run python config.py test
uv run python config.py setup
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
  "default_voice": "Zephyr",
  "default_style": "cheerful",
  "language": "en-GB",
  "volume": 0.7,
  "use_cache": true,
  "projects": {
    "my-project": {
      "voice": "Puck",
      "style": "energetic"
    }
  },
  "message_styles": {
    "success": "cheerfully",
    "error": "with concern",
    "waiting": "patiently"
  }
}
```

## Requirements

- Python 3.10+
- macOS (for audio playback via `afplay`)
- GOOGLE_API_KEY environment variable (optional, falls back to macOS say)
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

## Technical Details

### Audio Processing
The system receives raw PCM audio data from Gemini API and converts it to WAV format using an efficient in-memory approach with `struct.pack`, avoiding the overhead of file I/O operations.

### Caching
Audio files are cached as WAV files in `~/.claude/voice-cache/` to reduce API calls for repeated messages.

### Integration
The voice notification system is integrated with Claude Code's hook system, specifically the `assistant-response-complete` hook, which triggers notifications when Claude finishes responding.

## Troubleshooting

1. **No sound**: Check that your GOOGLE_API_KEY is set and valid
2. **Fallback to say command**: The system automatically falls back to macOS `say` if Gemini API is unavailable
3. **Cache issues**: Clear `~/.claude/voice-cache/` if you experience stale audio

## License

Part of the Claude Code configuration system managed by chezmoi.
