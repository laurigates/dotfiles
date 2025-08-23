"""
Claude Voice Notification System

A voice notification system for Claude Code that uses Gemini API TTS
with project-specific voices and fallback to macOS 'say' command.
"""

from .config import VoiceConfig
from .config import main as config_main
from .notify import VoiceNotifier
from .notify import main as notify_main

__version__ = "0.1.0"
__all__ = ["VoiceNotifier", "VoiceConfig", "notify_main", "config_main"]


def main() -> None:
    """Legacy main function for backwards compatibility."""
    print("Claude Voice Notification System v0.1.0")
    print("Use 'voice-notify' or 'voice-config' commands instead.")
