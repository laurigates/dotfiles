#!/usr/bin/env python3
"""
Obsidian Daily Logger for Claude Code

Logs Claude Code activities to an Obsidian vault for daily note processing.
Uses Gemini API for intelligent summarization of activities.
"""

import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO if os.getenv("DEBUG") else logging.WARNING,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

try:
    from google import genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    logger.warning("google-genai not installed. Falling back to template-based logging.")

from config import Config


class ObsidianLogger:
    """Logs Claude Code activities to Obsidian vault."""

    def __init__(self):
        """Initialize the logger with configuration."""
        self.config = Config
        self.gemini_client = None

        if GEMINI_AVAILABLE and Config.USE_GEMINI and Config.GEMINI_API_KEY:
            try:
                self.gemini_client = genai.Client(api_key=Config.GEMINI_API_KEY)
                logger.info("Gemini API initialized for activity logging")
            except Exception as e:
                logger.error(f"Failed to initialize Gemini: {e}")

    def log_activity(self, context: Dict[str, Any]) -> bool:
        """
        Log an activity to the Obsidian vault.

        Args:
            context: Parsed context from Claude's activity

        Returns:
            True if successfully logged, False otherwise
        """
        if not Config.ENABLED:
            logger.debug("Obsidian logger is disabled")
            return False

        try:
            # Ensure log file exists
            Config.ensure_log_file_exists()

            # Generate log entry
            log_entry = self._generate_log_entry(context)

            if not log_entry:
                logger.debug("No meaningful activity to log")
                return False

            # Append to log file
            self._append_to_log(log_entry)
            logger.info(f"Logged activity: {log_entry}")
            return True

        except Exception as e:
            logger.error(f"Failed to log activity: {e}")
            return False

    def _generate_log_entry(self, context: Dict[str, Any]) -> Optional[str]:
        """Generate a formatted log entry from context."""
        # Get timestamp
        timestamp = datetime.now().strftime(Config.DATE_FORMAT)

        # Get activity summary
        if self.gemini_client and Config.USE_GEMINI:
            summary = self._generate_with_gemini(context)
        else:
            summary = self._generate_with_template(context)

        if not summary:
            return None

        # Get project name if available
        project = context.get('project_name', '')
        if project:
            project = f" ({project})"

        # Format the entry
        entry = f"[{timestamp}] {summary}{project}"
        return entry

    def _generate_with_gemini(self, context: Dict[str, Any]) -> Optional[str]:
        """Generate a summary using Gemini API."""
        try:
            prompt = self._build_gemini_prompt(context)

            response = self.gemini_client.models.generate_content(
                model=Config.GEMINI_MODEL,
                contents=prompt
            )

            if response and response.text:
                summary = response.text.strip()
                # Remove quotes if present
                if summary.startswith('"') and summary.endswith('"'):
                    summary = summary[1:-1]
                return summary

        except Exception as e:
            logger.error(f"Gemini generation failed: {e}")

        # Fall back to template
        return self._generate_with_template(context)

    def _build_gemini_prompt(self, context: Dict[str, Any]) -> str:
        """Build a prompt for Gemini to generate a concise log entry."""
        prompt = """OUTPUT ONLY THE LOG ENTRY. NO PREAMBLE. NO EXPLANATION.

Generate a single-line activity log entry that describes what was done.
Start with an appropriate emoji, then a very brief description (5-10 words max).
Be specific about the main action taken.

Context:
"""

        # Add activity type
        activity = context.get('primary_activity', 'general')
        prompt += f"- Activity type: {activity}\n"

        # Add files if present
        if context.get('files_modified'):
            files = context['files_modified'][:2]
            prompt += f"- Files: {', '.join(files)}\n"

        # Add commands if present
        if context.get('commands_run'):
            cmd = context['commands_run'][0]
            if len(cmd) > 50:
                cmd = cmd[:50] + "..."
            prompt += f"- Command: {cmd}\n"

        # Add test results if present
        if context.get('tests_results'):
            prompt += f"- Tests: {context['tests_results']}\n"

        # Add git operations if present
        if context.get('git_operations'):
            prompt += f"- Git: {', '.join(context['git_operations'][:2])}\n"

        # Add errors if present
        if context.get('errors_encountered'):
            prompt += f"- Errors: {len(context['errors_encountered'])} found\n"

        prompt += """
Examples of good log entries:
🔧 Fixed linting errors in voice-notify.py
📝 Created obsidian logger hook module
✅ All 42 tests passing
🚀 Deployed to production environment
🐛 Debugged authentication issue
📦 Built project for release
♻️ Refactored database connection logic

OUTPUT ONLY THE LOG ENTRY:"""

        return prompt

    def _generate_with_template(self, context: Dict[str, Any]) -> Optional[str]:
        """Generate a summary using templates based on context."""
        activity = context.get('primary_activity', 'general')
        emoji = Config.ACTIVITY_EMOJIS.get(activity, '💡')

        # Build summary based on activity type
        if activity == 'tests_passed' and context.get('tests_results'):
            return f"{emoji} All tests passed"

        elif activity == 'tests_failed' and context.get('tests_results'):
            results = context['tests_results']
            failed = results.get('failed', 'some')
            return f"{emoji} {failed} tests failed"

        elif activity == 'git_commit' and context.get('git_operations'):
            return f"{emoji} Made git commit"

        elif activity in ['created', 'modified', 'fixed'] and context.get('files_modified'):
            files = context['files_modified']
            if len(files) == 1:
                filename = Path(files[0]).name
                return f"{emoji} {activity.capitalize()} {filename}"
            else:
                return f"{emoji} {activity.capitalize()} {len(files)} files"

        elif activity == 'building':
            return f"{emoji} Built project"

        elif activity == 'linting':
            return f"{emoji} Ran linter"

        elif activity == 'installing_dependencies':
            return f"{emoji} Installed dependencies"

        elif context.get('commands_run'):
            cmd = context['commands_run'][0].split()[0]
            return f"{emoji} Ran {cmd}"

        elif context.get('files_modified'):
            count = len(context['files_modified'])
            return f"{emoji} Modified {count} file{'s' if count > 1 else ''}"

        # Don't log if no meaningful activity
        return None

    def _append_to_log(self, entry: str):
        """Append an entry to the log file."""
        with open(Config.LOG_FILE_PATH, 'a', encoding='utf-8') as f:
            f.write(f"{entry}\n")


def parse_context_from_stdin() -> Dict[str, Any]:
    """Parse context from stdin (from event_context_parser or direct)."""
    try:
        input_data = sys.stdin.read()

        # Try to parse as JSON
        data = json.loads(input_data)

        # Check if it's from event_context_parser
        if 'context' in data:
            context = data['context']
        else:
            context = data

        # Try to get project name from git
        project_name = None
        try:
            import subprocess
            result = subprocess.run(
                ['git', 'rev-parse', '--show-toplevel'],
                capture_output=True,
                text=True,
                timeout=1
            )
            if result.returncode == 0:
                project_name = Path(result.stdout.strip()).name
        except:
            pass

        if project_name:
            context['project_name'] = project_name

        return context

    except Exception as e:
        logger.error(f"Failed to parse context: {e}")
        return {}


def main():
    """Main entry point for the logger."""
    # Parse context from stdin
    context = parse_context_from_stdin()

    if not context:
        logger.debug("No context to log")
        return

    # Initialize logger and log the activity
    logger_instance = ObsidianLogger()
    success = logger_instance.log_activity(context)

    # Exit silently regardless of success
    sys.exit(0)


if __name__ == "__main__":
    main()
