#!/usr/bin/env python3
"""
Claude Voice Configuration Tool

Simple CLI tool to manage voice notification settings for Claude Code.
"""

import json
import subprocess
import sys
from pathlib import Path
from typing import Any


class VoiceConfig:
    """Voice configuration management class."""

    def __init__(self) -> None:
        self.config_path = Path.home() / ".claude" / "voice-config.json"
        # Use the uv-managed entry point with proper working directory
        self.voice_project_dir = Path.home() / ".claude" / "hooks" / "voice-notify"
        self.voice_script_cmd = ["uv", "run", "python", "notify.py"]

    def load_config(self) -> dict[str, Any]:
        """Load the current configuration."""
        if self.config_path.exists():
            with self.config_path.open() as f:
                return json.load(f)  # type: ignore
        return {}

    def save_config(self, config: dict[str, Any]) -> None:
        """Save configuration to file."""
        self.config_path.parent.mkdir(parents=True, exist_ok=True)
        with self.config_path.open("w") as f:
            json.dump(config, f, indent=2)

    def list_voices(self) -> None:
        """List available Gemini voices."""
        config = self.load_config()
        voice_descriptions = config.get("voice_descriptions", {})

        print("Available Voices:")
        print("=" * 50)
        for voice, description in voice_descriptions.items():
            print(f"• {voice}: {description}")

        print("\nAdditional Gemini API voices:")
        print("• Aoede, Charon, Clementine, Fenrir, Juno")
        print("• Most voices support various styles and characteristics")

    def test_voice(self, voice_name: str | None = None, style: str | None = None) -> None:
        """Test a voice with a sample message."""
        config = self.load_config()
        voice = voice_name or config.get("default_voice", "Zephyr")
        test_style = style or "cheerful"

        message = f"Testing voice {voice} with {test_style} style. How does this sound?"

        print(f"Testing voice: {voice} (style: {test_style})")
        result = subprocess.run(
            self.voice_script_cmd + [message, "test-project", test_style],
            cwd=self.voice_project_dir
        )

        if result.returncode == 0:
            print("✓ Voice test completed!")
        else:
            print("✗ Voice test failed!")

    def set_project_voice(self, project: str, voice: str, style: str | None = None) -> None:
        """Set voice for a specific project."""
        config = self.load_config()

        if "projects" not in config:
            config["projects"] = {}

        config["projects"][project] = {
            "voice": voice,
            "style": style or config.get("default_style", "cheerful"),
        }

        self.save_config(config)
        print(
            f"✓ Set {project} to use voice '{voice}' with style '{style or 'default'}'"
        )

    def toggle_notifications(self) -> None:
        """Toggle voice notifications on/off."""
        config = self.load_config()
        current_state = config.get("enabled", True)
        config["enabled"] = not current_state

        self.save_config(config)
        state = "enabled" if config["enabled"] else "disabled"
        print(f"✓ Voice notifications {state}")

    def show_status(self) -> None:
        """Show current configuration status."""
        config = self.load_config()

        print("Voice Notification Status")
        print("=" * 30)
        print(f"Enabled: {'Yes' if config.get('enabled', True) else 'No'}")
        print(f"Default Voice: {config.get('default_voice', 'Zephyr')}")
        print(f"Default Style: {config.get('default_style', 'cheerful')}")
        print(f"Volume: {config.get('volume', 0.7)}")
        print(f"Cache: {'Enabled' if config.get('use_cache', True) else 'Disabled'}")

        projects = config.get("projects", {})
        if projects:
            print(f"\nProject Configurations ({len(projects)}):")
            for project, proj_config in projects.items():
                print(
                    f"  • {project}: {proj_config['voice']} ({proj_config.get('style', 'default')})"
                )
        else:
            print("\nNo project-specific configurations.")

    def interactive_setup(self) -> None:
        """Interactive setup wizard."""
        print("Claude Voice Notification Setup")
        print("=" * 35)

        config = self.load_config()

        # Test current setup
        print("\n1. Testing current voice...")
        self.test_voice()

        # Voice selection
        print("\n2. Voice Selection")
        self.list_voices()
        voice = input(
            f"\nChoose default voice (current: {config.get('default_voice', 'Zephyr')}): "
        ).strip()
        if voice:
            config["default_voice"] = voice

        # Style selection
        styles = list(config.get("message_styles", {}).keys())
        print(f"\nAvailable styles: {', '.join(styles)}")
        style = input(
            f"Choose default style (current: {config.get('default_style', 'cheerful')}): "
        ).strip()
        if style:
            config["default_style"] = style

        # Volume
        volume = input(
            f"Set volume 0.0-1.0 (current: {config.get('volume', 0.7)}): "
        ).strip()
        if volume:
            try:
                config["volume"] = float(volume)
            except ValueError:
                print("Invalid volume, keeping current setting.")

        # Save and test
        self.save_config(config)
        print("\n✓ Configuration saved!")

        test_again = input("\nTest new configuration? (y/N): ").strip().lower()
        if test_again == "y":
            self.test_voice()


def main() -> None:
    """Main CLI entry point."""
    config_tool = VoiceConfig()

    if len(sys.argv) < 2:
        print("Claude Voice Configuration Tool")
        print("\nUsage:")
        print("  voice-config status              # Show current configuration")
        print("  voice-config toggle              # Enable/disable notifications")
        print("  voice-config test [voice] [style] # Test a voice")
        print("  voice-config voices              # List available voices")
        print("  voice-config setup               # Interactive setup wizard")
        print("  voice-config set-project <name> <voice> [style] # Set project voice")
        sys.exit(1)

    command = sys.argv[1]

    if command == "status":
        config_tool.show_status()
    elif command == "toggle":
        config_tool.toggle_notifications()
    elif command == "test":
        voice = sys.argv[2] if len(sys.argv) > 2 else None
        style = sys.argv[3] if len(sys.argv) > 3 else None
        config_tool.test_voice(voice, style)
    elif command == "voices":
        config_tool.list_voices()
    elif command == "setup":
        config_tool.interactive_setup()
    elif command == "set-project":
        if len(sys.argv) < 4:
            print("Usage: voice-config set-project <project> <voice> [style]")
            sys.exit(1)
        project = sys.argv[2]
        voice = sys.argv[3]
        style = sys.argv[4] if len(sys.argv) > 4 else None
        config_tool.set_project_voice(project, voice, style)
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
