#!/usr/bin/env python3
"""
Claude Code Voice Notification System

Uses Gemini API text-to-speech to provide voice notifications when Claude
completes tasks or encounters different states. Supports project-specific
voices and dynamic speech styles.
"""

import json
import logging
import os
import subprocess
import sys
import tempfile
import wave
from pathlib import Path
from typing import Any

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

try:
    from google import genai
    from google.genai import types

    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    logger.warning(
        "google-genai not installed. Will use fallback to macOS 'say' command."
    )


class VoiceNotifier:
    """Main voice notification class with Gemini API integration and macOS fallback."""

    def __init__(self, config_path: str | None = None):
        """Initialize the voice notifier with configuration."""
        self.config_path = config_path or str(
            Path("~/.claude/voice-config.json").expanduser()
        )
        self.config = self.load_config()
        self.cache_dir = Path.home() / ".claude" / "voice-cache"
        self.cache_dir.mkdir(parents=True, exist_ok=True)

        # Initialize Gemini client if available
        if GEMINI_AVAILABLE and self.config.get("enabled", True):
            self.init_gemini_client()
        else:
            self.gemini_client: None | object = None

    def load_config(self) -> dict[str, Any]:
        """Load voice configuration from JSON file."""
        default_config = {
            "enabled": True,
            "default_voice": "Zephyr",
            "default_style": "cheerful",
            "volume": 0.7,
            "use_cache": True,
            "projects": {},
            "message_styles": {
                "success": "cheerfully",
                "error": "with concern",
                "waiting": "patiently",
                "tool_use": "professionally",
                "neutral": "calmly",
            },
        }

        try:
            config_path = Path(self.config_path)
            if config_path.exists():
                with config_path.open() as f:
                    user_config = json.load(f)
                # Merge with defaults
                default_config.update(user_config)
                return default_config
            else:
                # Create default config file
                self.save_config(default_config)
                return default_config
        except Exception as e:
            logger.error(f"Error loading config: {e}. Using defaults.")
            return default_config

    def save_config(self, config: dict[str, Any]) -> None:
        """Save configuration to JSON file."""
        try:
            config_path = Path(self.config_path)
            config_path.parent.mkdir(parents=True, exist_ok=True)
            with config_path.open("w") as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            logger.error(f"Error saving config: {e}")

    def init_gemini_client(self) -> None:
        """Initialize Gemini API client."""
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            # Also check for GOOGLE_API_KEY for backward compatibility
            api_key = os.getenv("GOOGLE_API_KEY")

        if not api_key:
            logger.warning(
                "GEMINI_API_KEY not found. Voice notifications will use macOS 'say' fallback."
            )
            self.gemini_client = None
            return

        try:
            self.gemini_client = genai.Client(api_key=api_key)
            logger.info("Gemini API client initialized successfully.")
        except Exception as e:
            logger.error(f"Failed to initialize Gemini client: {e}")
            self.gemini_client = None

    def get_project_name(self) -> str:
        """Get current project name from git repository or directory."""
        try:
            # Try git repository name first
            result = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True,
                text=True,
                check=True,
            )
            return Path(result.stdout.strip()).name
        except subprocess.CalledProcessError:
            # Fall back to current directory name
            return Path.cwd().name

    def get_voice_config(self, project: str | None = None) -> dict[str, str]:
        """Get voice configuration for the specified project."""
        if not project:
            project = self.get_project_name()

        project_config = self.config.get("projects", {}).get(project, {})

        return {
            "voice": project_config.get("voice", self.config["default_voice"]),
            "style": project_config.get("style", self.config["default_style"]),
        }

    def analyze_message_style(self, message: str) -> str:
        """Analyze message content to determine appropriate speech style."""
        message_lower = message.lower()

        # Waiting indicators (check first as questions override other keywords)
        if "waiting" in message_lower or message.strip().endswith("?"):
            return "waiting"

        # Error indicators
        error_keywords = ["error", "failed", "exception", "issue", "problem", "trouble"]
        if any(keyword in message_lower for keyword in error_keywords):
            return "error"

        # Success indicators (moved "ready" to be less generic)
        success_keywords = [
            "completed",
            "done",
            "success",
            "finished",
            "applied",
        ]
        if any(keyword in message_lower for keyword in success_keywords):
            return "success"

        # Tool use indicators
        tool_keywords = ["running", "executing", "processing", "analyzing"]
        if any(keyword in message_lower for keyword in tool_keywords):
            return "tool_use"

        return "neutral"

    def generate_speech_gemini(
        self, text: str, voice_name: str, style: str
    ) -> bytes | None:
        """Generate speech using Gemini API."""
        if not self.gemini_client:
            return None

        try:
            # Format the text with style instruction
            style_instruction = self.config["message_styles"].get(style, "calmly")
            formatted_text = f"Say {style_instruction}: {text}"

            response = self.gemini_client.models.generate_content(
                model="gemini-2.5-flash-preview-tts",
                contents=formatted_text,
                config=types.GenerateContentConfig(
                    response_modalities=["AUDIO"],
                    speech_config=types.SpeechConfig(
                        voice_config=types.VoiceConfig(
                            prebuilt_voice_config=types.PrebuiltVoiceConfig(
                                voice_name=voice_name
                            )
                        )
                    ),
                ),
            )

            # Extract audio data from the response
            if response.candidates and len(response.candidates) > 0:
                candidate = response.candidates[0]
                if candidate.content and candidate.content.parts:
                    for part in candidate.content.parts:
                        if hasattr(part, "inline_data") and part.inline_data:
                            return part.inline_data.data

            logger.warning("No audio data found in Gemini response.")
            return None

        except Exception as e:
            logger.error(f"Gemini TTS generation failed: {e}")
            return None

    def get_cache_key(self, text: str, voice: str, style: str) -> str:
        """Generate cache key for audio data."""
        import hashlib

        content = f"{text}_{voice}_{style}"
        return hashlib.md5(content.encode()).hexdigest()

    def get_cached_audio(self, cache_key: str) -> bytes | None:
        """Retrieve cached audio data."""
        if not self.config.get("use_cache", True):
            return None

        cache_file = self.cache_dir / f"{cache_key}.wav"
        try:
            if cache_file.exists():
                return cache_file.read_bytes()
        except Exception as e:
            logger.error(f"Error reading cache: {e}")
        return None

    def save_cached_audio(self, cache_key: str, audio_data: bytes) -> None:
        """Save audio data to cache."""
        if not self.config.get("use_cache", True):
            return

        cache_file = self.cache_dir / f"{cache_key}.wav"
        try:
            # Save as WAV file with proper headers
            with wave.open(str(cache_file), "wb") as wf:
                wf.setnchannels(1)  # Mono
                wf.setsampwidth(2)  # 16-bit
                wf.setframerate(24000)  # 24kHz sample rate
                wf.writeframes(audio_data)
        except Exception as e:
            logger.error(f"Error saving to cache: {e}")

    def play_audio(self, audio_data: bytes) -> bool:
        """Play audio data using afplay."""
        try:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_file:
                # Write WAV file with proper headers
                with wave.open(temp_file.name, "wb") as wf:
                    wf.setnchannels(1)  # Mono
                    wf.setsampwidth(2)  # 16-bit
                    wf.setframerate(24000)  # 24kHz sample rate
                    wf.writeframes(audio_data)

                # Play audio with volume control
                volume = self.config.get("volume", 0.7)
                result = subprocess.run(
                    ["afplay", "-v", str(volume), temp_file.name],
                    capture_output=True,
                    text=True,
                )

                # Clean up temp file
                Path(temp_file.name).unlink()

                return result.returncode == 0

        except Exception as e:
            logger.error(f"Error playing audio: {e}")
            return False

    def fallback_say(self, text: str, voice: str | None = None) -> bool:
        """Fallback to macOS say command."""
        try:
            cmd = ["say"]

            # Add voice if specified and available
            if voice:
                # Map Gemini voices to macOS voices
                macos_voice_map = {
                    "Zephyr": "Samantha",
                    "Puck": "Alex",
                    "Kore": "Victoria",
                }
                macos_voice = macos_voice_map.get(voice, "Samantha")
                cmd.extend(["-v", macos_voice])

            # Add rate control
            cmd.extend(["-r", "200"])  # Rate control

            cmd.append(text)

            result = subprocess.run(cmd, capture_output=True, text=True)
            return result.returncode == 0

        except Exception as e:
            logger.error(f"Fallback say command failed: {e}")
            return False

    def notify(
        self, message: str, project: str | None = None, style: str | None = None
    ) -> bool:
        """Main notification method."""
        if not self.config.get("enabled", True):
            logger.info("Voice notifications are disabled.")
            return True

        # Get voice configuration for project
        voice_config = self.get_voice_config(project)

        # Get actual project name (use provided or detect)
        actual_project = project or self.get_project_name()

        # Prepend project context to message
        contextualized_message = f"In {actual_project}: {message}"

        # Determine style if not provided
        if not style:
            style = self.analyze_message_style(message)

        logger.info(
            f"Voice notification: {contextualized_message[:50]}... (voice: {voice_config['voice']}, style: {style})"
        )

        # Try Gemini API first
        if GEMINI_AVAILABLE and self.gemini_client:
            cache_key = self.get_cache_key(contextualized_message, voice_config["voice"], style)

            # Check cache first
            audio_data = self.get_cached_audio(cache_key)

            if not audio_data:
                # Generate new audio
                audio_data = self.generate_speech_gemini(
                    contextualized_message, voice_config["voice"], style
                )
                if audio_data:
                    self.save_cached_audio(cache_key, audio_data)

            if audio_data and self.play_audio(audio_data):
                return True

            logger.warning("Gemini TTS failed, falling back to macOS say.")

        # Fallback to macOS say command
        return self.fallback_say(contextualized_message, voice_config["voice"])


def main() -> None:
    """Main entry point for the voice notification script."""
    if len(sys.argv) < 2:
        print("Usage: voice-notify <message> [project] [style]")
        sys.exit(1)

    message = sys.argv[1]
    project = sys.argv[2] if len(sys.argv) > 2 else None
    style = sys.argv[3] if len(sys.argv) > 3 else None

    notifier = VoiceNotifier()
    success = notifier.notify(message, project, style)

    if not success:
        logger.error("Voice notification failed.")
        sys.exit(1)


if __name__ == "__main__":
    main()
