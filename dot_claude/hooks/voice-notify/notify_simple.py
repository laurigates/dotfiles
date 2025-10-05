#!/usr/bin/env python3
"""
Simplified Voice Notifier for Claude Code

Generates context-aware voice notifications based on actual Claude activities.
No AI required - uses template-based messages with actual file/command details.
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Dict, Optional
import logging

# Configure logging
DEBUG = os.getenv("CLAUDE_HOOKS_DEBUG", "false").lower() == "true"
log_level = logging.DEBUG if DEBUG else logging.WARNING
logging.basicConfig(
    level=log_level,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stderr),
        logging.FileHandler('/tmp/claude_hooks_debug.log', mode='a')
    ]
)
logger = logging.getLogger(__name__)


class SimpleVoiceNotifier:
    """Simple, reliable voice notifications using context-aware templates."""

    def __init__(self):
        """Initialize the notifier."""
        self.enabled = os.getenv("CLAUDE_VOICE_ENABLED", "true").lower() == "true"
        self.volume = float(os.getenv("CLAUDE_VOICE_VOLUME", "0.7"))

        # Try to use Gemini TTS if available
        self.gemini_client = None
        try:
            api_key = os.getenv("GEMINI_API_KEY")
            if api_key:
                from google import genai
                from google.genai import types
                self.gemini_client = genai.Client(api_key=api_key)
                logger.info("Gemini TTS available")
        except Exception as e:
            logger.debug(f"Gemini TTS not available: {e}")

    def generate_message(self, context: Dict) -> str:
        """
        Generate a specific, context-aware message from the context.

        This is the key improvement - we use the actual data to create
        specific messages like "Fixed hooks.py and config.json" instead
        of generic "Task completed" messages.
        """
        activity = context.get('primary_activity', 'general')
        files = context.get('files_modified', [])
        commands = context.get('commands_run', [])
        git_ops = context.get('git_operations', [])
        test_results = context.get('test_results')
        success = context.get('success', True)
        errors = context.get('errors', [])

        # Handle specific activities with real data
        if activity == 'tests_passed' and test_results:
            return f"Great! {test_results}"

        elif activity == 'tests_failed' and test_results:
            return f"Heads up - {test_results}"

        elif activity == 'git_commit' and files:
            if len(files) == 1:
                return f"Committed changes to {files[0]}"
            elif len(files) <= 3:
                return f"Committed {', '.join(files)}"
            else:
                return f"Committed {len(files)} files"

        elif activity == 'git_push':
            return "Pushed changes to remote"

        elif activity == 'modified_python' and files:
            py_files = [f for f in files if f.endswith('.py')]
            if len(py_files) == 1:
                return f"Updated {py_files[0]}"
            else:
                return f"Updated {len(py_files)} Python files"

        elif activity == 'modified_javascript' and files:
            js_files = [f for f in files if f.endswith(('.js', '.ts', '.jsx', '.tsx'))]
            if len(js_files) == 1:
                return f"Updated {js_files[0]}"
            else:
                return f"Updated {len(js_files)} JavaScript files"

        elif activity == 'updated_docs' and files:
            doc_files = [f for f in files if f.endswith(('.md', '.txt', '.rst'))]
            if doc_files:
                return f"Updated documentation in {doc_files[0]}"

        elif activity == 'linting' and commands:
            lint_cmd = next((c for c in commands if 'lint' in c.lower() or 'ruff' in c.lower()), None)
            if lint_cmd:
                # Extract the tool name
                if 'ruff' in lint_cmd:
                    return "Ran ruff linting"
                elif 'eslint' in lint_cmd:
                    return "Ran ESLint"
                else:
                    return "Ran linter"

        elif activity == 'building':
            return "Built the project"

        elif activity == 'installing':
            return "Installed dependencies"

        elif activity == 'error_encountered' and errors:
            return f"Encountered {len(errors)} errors"

        # Fallback to specific details if available
        elif files:
            if len(files) == 1:
                action = "Created" if activity == 'created' else "Modified"
                return f"{action} {files[0]}"
            elif len(files) <= 3:
                return f"Modified {', '.join(files)}"
            else:
                return f"Modified {len(files)} files"

        elif commands:
            cmd = commands[0]
            # Extract meaningful part of command
            cmd_parts = cmd.split()
            if cmd_parts:
                tool = cmd_parts[0]
                if tool in ['npm', 'yarn', 'pip', 'cargo', 'go']:
                    if len(cmd_parts) > 1:
                        return f"Ran {tool} {cmd_parts[1]}"
                    else:
                        return f"Ran {tool}"
                else:
                    return f"Executed {tool}"

        # Generic fallbacks based on success
        elif not success:
            return "Task completed with some issues"
        else:
            return "Task completed successfully"

    def speak_with_gemini(self, text: str) -> bool:
        """Try to speak using Gemini TTS."""
        if not self.gemini_client:
            return False

        try:
            from google.genai import types

            # Generate speech
            response = self.gemini_client.models.generate_content(
                model="gemini-2.5-flash-preview-tts",
                contents=text,
                config=types.GenerateContentConfig(
                    response_modalities=["AUDIO"],
                    speech_config=types.SpeechConfig(
                        language_code="en-US",
                        voice_config=types.VoiceConfig(
                            prebuilt_voice_config=types.PrebuiltVoiceConfig(
                                voice_name="Zephyr"
                            )
                        )
                    ),
                )
            )

            # Extract and play audio
            if response and response.candidates:
                candidate = response.candidates[0]
                if candidate.content and candidate.content.parts:
                    for part in candidate.content.parts:
                        if part.inline_data and part.inline_data.mime_type:
                            if part.inline_data.mime_type.startswith('audio/'):
                                return self.play_audio(part.inline_data.data)

            return False

        except Exception as e:
            logger.debug(f"Gemini TTS failed: {e}")
            return False

    def play_audio(self, audio_data: bytes) -> bool:
        """Play audio data using afplay."""
        try:
            # Add WAV header to PCM data
            wav_data = self.pcm_to_wav(audio_data)

            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_file:
                temp_file.write(wav_data)
                temp_file.flush()

                # Play with afplay
                result = subprocess.run(
                    ["afplay", "-v", str(self.volume), temp_file.name],
                    capture_output=True,
                    text=True
                )

                os.unlink(temp_file.name)
                return result.returncode == 0

        except Exception as e:
            logger.error(f"Failed to play audio: {e}")
            return False

    def pcm_to_wav(self, pcm_data: bytes, sample_rate: int = 24000) -> bytes:
        """Convert PCM to WAV format."""
        import struct

        channels = 1
        bits_per_sample = 16
        byte_rate = sample_rate * channels * bits_per_sample // 8
        block_align = channels * bits_per_sample // 8
        data_size = len(pcm_data)

        wav_header = struct.pack(
            '<4sI4s4sIHHIIHH4sI',
            b'RIFF',
            36 + data_size,
            b'WAVE',
            b'fmt ',
            16,
            1,
            channels,
            sample_rate,
            byte_rate,
            block_align,
            bits_per_sample,
            b'data',
            data_size
        )

        return wav_header + pcm_data

    def speak_with_say(self, text: str) -> bool:
        """Fallback to macOS say command."""
        try:
            # Use a pleasant voice
            voice = "Samantha"
            rate = 200

            result = subprocess.run(
                ["say", "-v", voice, "-r", str(rate), text],
                capture_output=True,
                text=True
            )

            return result.returncode == 0

        except Exception as e:
            logger.error(f"Say command failed: {e}")
            return False

    def notify(self, context: Dict) -> bool:
        """
        Generate and speak a notification based on the context.
        """
        if not self.enabled:
            logger.info("Voice notifications disabled")
            return True

        # Generate context-aware message
        message = self.generate_message(context)

        # Add project name if available
        project = context.get('project_name')
        if project and project not in message:
            # Only add project name if it adds value
            if not any(word in message.lower() for word in ['task', 'completed', 'done']):
                message = f"{message} in {project}"

        logger.info(f"Speaking: {message}")

        # Try Gemini TTS first, then fall back to say
        if self.speak_with_gemini(message):
            return True
        else:
            return self.speak_with_say(message)


def main():
    """Main entry point - reads context from stdin and speaks notification."""
    try:
        # Read context from stdin
        input_data = sys.stdin.read()
        if not input_data:
            logger.error("No input received")
            sys.exit(1)

        context = json.loads(input_data)
        logger.debug(f"Received context: {context}")

        # Create notifier and speak
        notifier = SimpleVoiceNotifier()
        success = notifier.notify(context)

        if not success:
            logger.error("Notification failed")
            sys.exit(1)

    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON input: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
