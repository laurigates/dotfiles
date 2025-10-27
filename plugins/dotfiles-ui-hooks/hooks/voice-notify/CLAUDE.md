# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Voice notification system for Claude Code that provides audio feedback using Gemini API text-to-speech with project-specific voices and macOS fallback.

## Development Commands

```bash
# Install/sync dependencies
uv sync

# Run tests
uv run pytest
uv run pytest --cov  # with coverage

# Code quality
uv run ruff check .
uv run ruff format .

# Manual testing
uv run python notify.py "Test message" "project-name" "success"
uv run python config.py status
uv run python config.py test
```

## Architecture

### Core Components

1. **VoiceNotifier** (`notify.py`): Main notification engine
   - Manages Gemini API client initialization
   - Handles voice synthesis with caching
   - Falls back to macOS `say` command when API unavailable
   - Converts raw PCM audio to WAV format in-memory

2. **VoiceConfig** (`config.py`): Configuration management tool
   - CLI interface for managing voice settings
   - Supports status, test, setup, and voice listing commands

3. **Hook Integration**: Designed to integrate with Claude Code's `assistant-response-complete` hook

### Key Technical Details

- **Audio Processing**: Receives raw PCM from Gemini API, converts to WAV using struct.pack for efficient in-memory conversion
- **Caching**: WAV files cached in `~/.claude/voice-cache/` with hash-based naming
- **Configuration**: JSON-based config at `~/.claude/voice-config.json` supporting per-project voices and styles
- **Environment**: Requires GEMINI_API_KEY for Gemini API, falls back gracefully to macOS `say`

### Voice Configuration Structure

```json
{
  "enabled": true,
  "default_voice": "Zephyr",
  "default_style": "cheerful",
  "language": "en-GB",
  "volume": 0.7,
  "use_cache": true,
  "projects": {
    "project-name": {
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

## Development Notes

- This is a uv-managed Python project (3.10+)
- Uses google-genai library for Gemini API integration
- Audio playback via macOS `afplay` command
- Test coverage expected for new features
- PRD.md contains full product requirements and implementation details
