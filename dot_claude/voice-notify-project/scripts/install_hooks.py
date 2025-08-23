#!/usr/bin/env python3
"""
Installation script to update existing Claude hook scripts to use the new package.
"""

import shutil
import sys
from pathlib import Path


def update_voice_notify_script() -> None:
    """Update the voice-notify.py script to use the new package."""
    hooks_dir = Path.home() / ".claude" / "hooks"
    voice_notify_script = hooks_dir / "voice-notify.py"

    if voice_notify_script.exists():
        # Backup the original script
        backup_path = hooks_dir / "voice-notify.py.backup"
        shutil.copy2(voice_notify_script, backup_path)
        print(f"Backed up original script to {backup_path}")

    # Create new wrapper script that uses uv
    project_dir = Path(__file__).parent.parent
    wrapper_content = f'''#!/bin/bash
# Claude Code Voice Notification System - Wrapper Script
# This script wraps the new packaged voice notification system for backwards compatibility.

exec uv --directory {project_dir} run voice-notify "$@"
'''

    hooks_dir.mkdir(parents=True, exist_ok=True)
    with voice_notify_script.open('w') as f:
        f.write(wrapper_content)

    # Make executable
    Path(voice_notify_script).chmod(0o755)
    print(f"Updated voice notification script at {voice_notify_script}")


def update_voice_config_script() -> None:
    """Update the voice-config script to use the new package."""
    hooks_dir = Path.home() / ".claude" / "hooks"
    voice_config_script = hooks_dir / "voice-config"

    if voice_config_script.exists():
        # Backup the original script
        backup_path = hooks_dir / "voice-config.backup"
        shutil.copy2(voice_config_script, backup_path)
        print(f"Backed up original script to {backup_path}")

    # Create new wrapper script that uses uv
    project_dir = Path(__file__).parent.parent
    wrapper_content = f'''#!/bin/bash
# Claude Voice Configuration Tool - Wrapper Script
# This script wraps the new packaged voice configuration tool for backwards compatibility.

exec uv --directory {project_dir} run voice-config "$@"
'''

    hooks_dir.mkdir(parents=True, exist_ok=True)
    with voice_config_script.open('w') as f:
        f.write(wrapper_content)

    # Make executable
    Path(voice_config_script).chmod(0o755)
    print(f"Updated voice configuration script at {voice_config_script}")


def main() -> None:
    """Main installation function."""
    print("Installing Claude Voice Notification System hooks...")

    try:
        update_voice_notify_script()
        update_voice_config_script()
        print("\n✓ Installation completed successfully!")
        print("\nThe voice notification system is now ready to use.")
        print("You can test it with: voice-config test")

    except Exception as e:
        print(f"❌ Installation failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
