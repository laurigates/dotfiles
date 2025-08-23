"""Tests for voice notification functionality."""

import json
import subprocess
from pathlib import Path
from unittest.mock import Mock, mock_open, patch

from claude_voice_notify.notify import VoiceNotifier


class TestVoiceNotifier:
    """Test the VoiceNotifier class."""

    def test_init_with_default_config(self):
        """Test initialization with default configuration."""
        with patch.object(VoiceNotifier, "load_config", return_value={}):
            notifier = VoiceNotifier()
            assert notifier.config_path == str(
                Path("~/.claude/voice-config.json").expanduser()
            )

    def test_init_with_custom_config_path(self):
        """Test initialization with custom config path."""
        custom_path = "/tmp/test-config.json"
        with patch.object(VoiceNotifier, "load_config", return_value={}):
            notifier = VoiceNotifier(config_path=custom_path)
            assert notifier.config_path == custom_path

    def test_load_config_with_existing_file(self):
        """Test loading configuration from existing file."""
        config_data = {
            "enabled": True,
            "default_voice": "TestVoice",
            "projects": {"test": {"voice": "ProjectVoice"}},
        }

        with (
            patch("pathlib.Path.exists", return_value=True),
            patch("pathlib.Path.open", mock_open(read_data=json.dumps(config_data))),
        ):
            notifier = VoiceNotifier()
            config = notifier.load_config()

            assert config["enabled"] is True
            assert config["default_voice"] == "TestVoice"
            assert "test" in config["projects"]

    def test_load_config_with_missing_file(self):
        """Test loading configuration when file doesn't exist."""
        with (
            patch("pathlib.Path.exists", return_value=False),
            patch.object(VoiceNotifier, "save_config") as mock_save,
        ):
            notifier = VoiceNotifier()
            config = notifier.load_config()

            # Should return default config
            assert config["enabled"] is True
            assert config["default_voice"] == "Zephyr"
            assert config["default_style"] == "cheerful"
            # save_config gets called during __init__ and load_config, so expect at least one call
            assert mock_save.call_count >= 1

    def test_get_project_name_from_git(self):
        """Test getting project name from git repository."""
        mock_result = Mock()
        mock_result.stdout = "/path/to/my-project\n"
        mock_result.returncode = 0

        with patch("subprocess.run", return_value=mock_result):
            notifier = VoiceNotifier()
            project_name = notifier.get_project_name()
            assert project_name == "my-project"

    def test_get_project_name_fallback_to_cwd(self):
        """Test falling back to current directory name when git fails."""
        with (
            patch(
                "subprocess.run", side_effect=subprocess.CalledProcessError(1, "git")
            ),
            patch("os.getcwd", return_value="/path/to/fallback-project"),
        ):
            notifier = VoiceNotifier()
            project_name = notifier.get_project_name()
            assert project_name == "fallback-project"

    def test_analyze_message_style_error(self):
        """Test message style analysis for error messages."""
        notifier = VoiceNotifier()

        error_messages = [
            "An error occurred",
            "Failed to process",
            "Exception in function",
            "There's a problem",
        ]

        for message in error_messages:
            assert notifier.analyze_message_style(message) == "error"

    def test_analyze_message_style_success(self):
        """Test message style analysis for success messages."""
        notifier = VoiceNotifier()

        success_messages = [
            "Task completed successfully",
            "Operation finished",
            "All done",
            "Successfully applied changes",
        ]

        for message in success_messages:
            assert notifier.analyze_message_style(message) == "success"

    def test_analyze_message_style_waiting(self):
        """Test message style analysis for waiting messages."""
        notifier = VoiceNotifier()

        waiting_messages = ["Waiting for input", "Are you ready?", "Should I continue?"]

        for message in waiting_messages:
            assert notifier.analyze_message_style(message) == "waiting"

    def test_get_voice_config_with_project_override(self):
        """Test getting voice configuration with project-specific settings."""
        config = {
            "default_voice": "DefaultVoice",
            "default_style": "default",
            "projects": {
                "test-project": {"voice": "ProjectVoice", "style": "professional"}
            },
        }

        with patch.object(VoiceNotifier, "load_config", return_value=config):
            notifier = VoiceNotifier()
            voice_config = notifier.get_voice_config("test-project")

            assert voice_config["voice"] == "ProjectVoice"
            assert voice_config["style"] == "professional"

    def test_get_voice_config_with_defaults(self):
        """Test getting voice configuration with default settings."""
        config = {
            "default_voice": "DefaultVoice",
            "default_style": "cheerful",
            "projects": {},
        }

        with patch.object(VoiceNotifier, "load_config", return_value=config):
            notifier = VoiceNotifier()
            voice_config = notifier.get_voice_config("unknown-project")

            assert voice_config["voice"] == "DefaultVoice"
            assert voice_config["style"] == "cheerful"

    def test_fallback_say_command(self):
        """Test fallback to macOS say command."""
        config = {"volume": 0.8}
        mock_result = Mock()
        mock_result.returncode = 0

        with (
            patch.object(VoiceNotifier, "load_config", return_value=config),
            patch("subprocess.run", return_value=mock_result) as mock_run,
        ):
            notifier = VoiceNotifier()
            success = notifier.fallback_say("Test message", "Zephyr")

            assert success is True
            mock_run.assert_called_once()
            args = mock_run.call_args[0][0]
            assert "say" in args
            assert "Test message" in args

    def test_notify_when_disabled(self):
        """Test notification when voice notifications are disabled."""
        config = {"enabled": False}

        with patch.object(VoiceNotifier, "load_config", return_value=config):
            notifier = VoiceNotifier()
            result = notifier.notify("Test message")

            # Should return True but not actually notify
            assert result is True

    @patch("claude_voice_notify.notify.GEMINI_AVAILABLE", False)
    def test_notify_without_gemini(self):
        """Test notification fallback when Gemini is not available."""
        config = {
            "enabled": True,
            "default_voice": "Zephyr",
            "default_style": "cheerful"
        }

        with (
            patch.object(VoiceNotifier, "load_config", return_value=config),
            patch.object(
                VoiceNotifier, "fallback_say", return_value=True
            ) as mock_fallback,
            patch.object(VoiceNotifier, "get_project_name", return_value="test-project"),
        ):
            notifier = VoiceNotifier()
            result = notifier.notify("Test message")

            assert result is True
            mock_fallback.assert_called_once()

    def test_cache_key_generation(self):
        """Test cache key generation for audio caching."""
        notifier = VoiceNotifier()

        key1 = notifier.get_cache_key("test", "voice1", "style1")
        key2 = notifier.get_cache_key("test", "voice1", "style1")
        key3 = notifier.get_cache_key("test", "voice2", "style1")

        assert key1 == key2  # Same inputs should generate same key
        assert key1 != key3  # Different inputs should generate different keys
        assert len(key1) == 32  # MD5 hash should be 32 characters
