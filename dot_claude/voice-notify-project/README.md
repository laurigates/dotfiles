# Claude Voice Notification System

Voice notifications for Claude Code using Gemini API text-to-speech with project-specific voices and macOS fallback.

## Features

- **Gemini API TTS**: High-quality text-to-speech with 30+ voice options
- **Project-Specific Voices**: Different voice personalities per repository
- **Dynamic Speech Styles**: Context-aware tone (cheerful, concerned, patient)
- **macOS Fallback**: Uses native `say` command when API unavailable
- **Audio Caching**: Reduces API calls for frequently used phrases

## Installation

This project is managed by uv and integrated with Claude Code hooks.

```bash
cd ~/.claude/voice-notify-project
uv sync
```

## Configuration

Edit `~/.claude/voice-config.json` to customize voices and styles.

## Usage

### Via Claude Hooks
Automatically triggered when Claude completes tasks.

### Manual Testing
```bash
cd ~/.claude/voice-notify-project
uv run voice-notify "Test message" "project-name" "success"
```

### Configuration Tool
```bash
cd ~/.claude/voice-notify-project
uv run voice-config status
uv run voice-config test
uv run voice-config setup
```

## Voices

- **Zephyr**: Bright, clear voice
- **Puck**: Upbeat, energetic voice
- **Kore**: Firm, professional voice
- Plus 27+ additional voices available through Gemini API

## Requirements

- Python 3.13+
- macOS (for audio playback)
- GOOGLE_API_KEY environment variable (optional, falls back to macOS say)
