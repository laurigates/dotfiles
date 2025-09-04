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
from pathlib import Path
from typing import Dict, Optional

# Configure logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

try:
    from google import genai
    from google.genai import types
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    logger.warning("google-genai not installed. Will use fallback to macOS 'say' command.")


class VoiceNotifier:
    """Main voice notification class with Gemini API integration and macOS fallback."""

    def __init__(self, config_path: Optional[str] = None):
        """Initialize the voice notifier with configuration."""
        self.config_path = config_path or os.path.expanduser("~/.claude/voice-config.json")
        self.config = self.load_config()
        self.cache_dir = Path.home() / ".claude" / "voice-cache"
        self.cache_dir.mkdir(parents=True, exist_ok=True)

        # Initialize Gemini client if available
        if GEMINI_AVAILABLE and self.config.get("enabled", True):
            self.init_gemini_client()
        else:
            self.gemini_client = None

    def load_config(self) -> Dict:
        """Load voice configuration from JSON file."""
        default_config = {
            "enabled": True,
            "model": "tts",  # "native-audio" or "tts" (native-audio not available yet)
            "default_voice": "Zephyr",
            "default_style": "cheerful",
            "language": "en-GB",  # Default language, can be overridden
            "volume": 0.7,
            "use_cache": True,
            "projects": {},
            "message_styles": {
                "success": "cheerfully",
                "error": "with concern",
                "waiting": "patiently",
                "tool_use": "professionally",
                "neutral": "calmly"
            },
            "language_names": {
                "en-GB": "British English",
                "en-US": "American English",
                "fi-FI": "Finnish",
                "fr-FR": "French",
                "de-DE": "German",
                "es-ES": "Spanish",
                "it-IT": "Italian",
                "ja-JP": "Japanese",
                "ko-KR": "Korean",
                "zh-CN": "Mandarin Chinese"
            }
        }

        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
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

    def save_config(self, config: Dict) -> None:
        """Save configuration to JSON file."""
        try:
            os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
            with open(self.config_path, 'w') as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            logger.error(f"Error saving config: {e}")

    def init_gemini_client(self) -> None:
        """Initialize Gemini API client."""
        api_key = os.getenv("GOOGLE_API_KEY")
        if not api_key:
            logger.warning("GOOGLE_API_KEY not found. Voice notifications will use macOS 'say' fallback.")
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
                capture_output=True, text=True, check=True
            )
            return os.path.basename(result.stdout.strip())
        except subprocess.CalledProcessError:
            # Fall back to current directory name
            return os.path.basename(os.getcwd())

    def get_voice_config(self, project: Optional[str] = None) -> Dict:
        """Get voice configuration for the specified project."""
        if not project:
            project = self.get_project_name()

        project_config = self.config.get("projects", {}).get(project, {})

        # Check for environment variable first, then project config, then default
        language = os.getenv('CLAUDE_VOICE_LANGUAGE') or \
                  project_config.get("language") or \
                  self.config.get("language", "en-GB")

        return {
            "voice": project_config.get("voice", self.config["default_voice"]),
            "style": project_config.get("style", self.config["default_style"]),
            "language": language
        }

    def analyze_message_style(self, message: str, event_type: Optional[str] = None) -> str:
        """Analyze message content to determine appropriate speech style."""
        # Use provided event type if available
        if event_type:
            style_map = {
                'success': 'success',
                'error': 'error',
                'test_success': 'success',
                'test_failure': 'error',
                'git_operation': 'tool_use',
                'bug_fix': 'success',
                'creation': 'success',
                'general': 'neutral'
            }
            if event_type in style_map:
                return style_map[event_type]

        # Fall back to content analysis
        message_lower = message.lower()

        # Error indicators
        error_keywords = ["error", "failed", "exception", "issue", "problem", "trouble"]
        if any(keyword in message_lower for keyword in error_keywords):
            return "error"

        # Success indicators
        success_keywords = ["completed", "done", "success", "finished", "ready", "applied", "fixed", "created"]
        if any(keyword in message_lower for keyword in success_keywords):
            return "success"

        # Waiting indicators
        if "waiting" in message_lower or message.strip().endswith("?"):
            return "waiting"

        # Tool use indicators
        tool_keywords = ["running", "executing", "processing", "analyzing", "updated", "modified"]
        if any(keyword in message_lower for keyword in tool_keywords):
            return "tool_use"

        return "neutral"

    def generate_speech_gemini(self, text: str, voice_name: str, style: str, language: str = "en-GB") -> Optional[bytes]:
        """Generate speech using Gemini API with native audio dialog model."""
        if not self.gemini_client:
            return None

        # Check which model to use
        model_type = self.config.get("model", "native-audio")

        if model_type == "tts":
            # Use the original TTS model directly
            return self._generate_speech_gemini_tts(text, voice_name, style, language)

        # Use the native audio dialog model
        try:
            logger.debug(f"Generating speech with native audio model, language={language}, style={style}")

            # Map our style to appropriate system instruction
            style_instructions = {
                "success": "Respond in a cheerful, celebratory tone.",
                "error": "Respond with concern and helpfulness.",
                "waiting": "Respond patiently and reassuringly.",
                "tool_use": "Respond professionally and efficiently.",
                "neutral": "Respond in a calm, friendly manner."
            }

            style_instruction = style_instructions.get(style, "Respond in a friendly, natural tone.")

            # Get full language name for better instruction
            language_name = self.config.get("language_names", {}).get(language, language)

            # Use the new native audio dialog model
            # The native audio model requires just the text and system instruction
            response = self.gemini_client.models.generate_content(
                model="gemini-2.5-flash-preview-native-audio-dialog",
                contents=text,  # Pass text directly
                config=types.GenerateContentConfig(
                    response_modalities=["AUDIO"],
                    system_instruction=f"You are a helpful assistant. {style_instruction} Please speak naturally in {language_name}.",
                    # Native audio dialog doesn't use speech_config
                )
            )

            # Extract audio data
            if response and response.candidates:
                candidate = response.candidates[0]
                if candidate.content and candidate.content.parts:
                    for part in candidate.content.parts:
                        # Check for inline_data with audio
                        if part.inline_data and part.inline_data.mime_type:
                            if part.inline_data.mime_type.startswith('audio/'):
                                # The data is already bytes, return it directly
                                audio_data = part.inline_data.data
                                logger.debug(f"Found audio data: {len(audio_data)} bytes, type: {part.inline_data.mime_type}")
                                return audio_data

            logger.warning("No audio data found in Gemini response")
            return None

        except Exception as e:
            logger.error(f"Gemini TTS generation failed: {e}")
            # If the native audio model fails, try falling back to the TTS model
            try:
                logger.info("Attempting fallback to TTS model...")
                return self._generate_speech_gemini_tts(text, voice_name, style, language)
            except Exception as fallback_e:
                logger.error(f"TTS fallback also failed: {fallback_e}")
                return None

    def _generate_speech_gemini_tts(self, text: str, voice_name: str, style: str, language: str = "en-GB") -> Optional[bytes]:
        """Fallback method using the original TTS model."""
        if not self.gemini_client:
            return None

        try:
            logger.debug(f"Using TTS fallback with voice={voice_name}, language={language}")

            response = self.gemini_client.models.generate_content(
                model="gemini-2.5-flash-preview-tts",
                contents=text,
                config=types.GenerateContentConfig(
                    response_modalities=["AUDIO"],
                    speech_config=types.SpeechConfig(
                        language_code=language,
                        voice_config=types.VoiceConfig(
                            prebuilt_voice_config=types.PrebuiltVoiceConfig(
                                voice_name=voice_name
                            )
                        )
                    ),
                )
            )

            # Extract audio data
            if response and response.candidates:
                candidate = response.candidates[0]
                if candidate.content and candidate.content.parts:
                    for part in candidate.content.parts:
                        if part.inline_data and part.inline_data.mime_type:
                            if part.inline_data.mime_type.startswith('audio/'):
                                audio_data = part.inline_data.data
                                logger.debug(f"Found TTS audio data: {len(audio_data)} bytes")
                                return audio_data

            return None

        except Exception as e:
            logger.error(f"TTS model failed: {e}")
            return None

    def get_cache_key(self, text: str, voice: str, style: str, language: str = "en-GB") -> str:
        """Generate cache key for audio data."""
        import hashlib
        content = f"{text}_{voice}_{style}_{language}"
        return hashlib.md5(content.encode()).hexdigest()

    def get_cached_audio(self, cache_key: str) -> Optional[bytes]:
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
        """Save audio data to cache as WAV."""
        if not self.config.get("use_cache", True):
            return

        cache_file = self.cache_dir / f"{cache_key}.wav"
        try:
            # Convert PCM to WAV before caching
            wav_data = self._pcm_to_wav(audio_data, sample_rate=24000, channels=1, bits_per_sample=16)
            cache_file.write_bytes(wav_data)
        except Exception as e:
            logger.error(f"Error saving to cache: {e}")

    def play_audio(self, audio_data: bytes) -> bool:
        """Play audio data using afplay."""
        try:
            # Convert PCM to WAV by adding WAV header
            wav_data = self._pcm_to_wav(audio_data, sample_rate=24000, channels=1, bits_per_sample=16)

            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_file:
                temp_file.write(wav_data)
                temp_file.flush()

                # Play audio with volume control
                volume = self.config.get("volume", 0.7)
                result = subprocess.run(
                    ["afplay", "-v", str(volume), temp_file.name],
                    capture_output=True, text=True
                )

                if result.returncode != 0:
                    logger.debug(f"afplay error: {result.stderr}")

                # Clean up temp file
                os.unlink(temp_file.name)

                return result.returncode == 0

        except Exception as e:
            logger.error(f"Error playing audio: {e}")
            return False

    def _pcm_to_wav(self, pcm_data: bytes, sample_rate: int = 24000, channels: int = 1, bits_per_sample: int = 16) -> bytes:
        """Convert raw PCM data to WAV format by adding header."""
        import struct

        # Calculate sizes
        byte_rate = sample_rate * channels * bits_per_sample // 8
        block_align = channels * bits_per_sample // 8
        data_size = len(pcm_data)

        # Create WAV header
        wav_header = struct.pack(
            '<4sI4s4sIHHIIHH4sI',
            b'RIFF',                    # ChunkID
            36 + data_size,              # ChunkSize
            b'WAVE',                     # Format
            b'fmt ',                     # Subchunk1ID
            16,                          # Subchunk1Size (16 for PCM)
            1,                           # AudioFormat (1 for PCM)
            channels,                    # NumChannels
            sample_rate,                 # SampleRate
            byte_rate,                   # ByteRate
            block_align,                 # BlockAlign
            bits_per_sample,             # BitsPerSample
            b'data',                     # Subchunk2ID
            data_size                    # Subchunk2Size
        )

        return wav_header + pcm_data

    def fallback_say(self, text: str, voice: Optional[str] = None) -> bool:
        """Fallback to macOS say command."""
        try:
            cmd = ["say"]

            # Add voice if specified and available
            if voice:
                # Map Gemini voices to macOS voices
                macos_voice_map = {
                    "Zephyr": "Samantha",
                    "Puck": "Alex",
                    "Kore": "Victoria"
                }
                macos_voice = macos_voice_map.get(voice, "Samantha")
                cmd.extend(["-v", macos_voice])

            # Add volume control
            volume = self.config.get("volume", 0.7)
            cmd.extend(["-r", "200"])  # Rate control

            cmd.append(text)

            result = subprocess.run(cmd, capture_output=True, text=True)
            return result.returncode == 0

        except Exception as e:
            logger.error(f"Fallback say command failed: {e}")
            return False

    def notify(self, message: str, project: Optional[str] = None, style: Optional[str] = None) -> bool:
        """Main notification method with enhanced event-type awareness."""
        if not self.config.get("enabled", True):
            logger.info("Voice notifications are disabled.")
            return True

        # Get voice configuration for project (includes language)
        voice_config = self.get_voice_config(project)

        # Determine style if not provided - now accepts event_type format
        if not style:
            style = self.analyze_message_style(message)
        else:
            # If style is an event type, convert it to speech style
            style = self.analyze_message_style(message, event_type=style)

        logger.info(f"Voice notification: {message[:50]}... (voice: {voice_config['voice']}, lang: {voice_config['language']}, style: {style})")

        # Try Gemini API first
        if GEMINI_AVAILABLE and self.gemini_client:
            cache_key = self.get_cache_key(message, voice_config['voice'], style, voice_config['language'])

            # Check cache first
            audio_data = self.get_cached_audio(cache_key)

            if not audio_data:
                # Generate new audio with language
                audio_data = self.generate_speech_gemini(message, voice_config['voice'], style, voice_config['language'])
                if audio_data:
                    self.save_cached_audio(cache_key, audio_data)

            if audio_data and self.play_audio(audio_data):
                return True

            logger.warning("Gemini TTS failed, falling back to macOS say.")

        # Fallback to macOS say command
        return self.fallback_say(message, voice_config['voice'])


def main():
    """Main entry point for the voice notification script."""
    if len(sys.argv) < 2:
        print("Usage: voice-notify.py <message> [project] [style]")
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
