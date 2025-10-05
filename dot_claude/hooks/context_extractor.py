#!/usr/bin/env python3
"""
Unified Context Extractor for Claude Code Hooks

Single source of truth for extracting context from Claude Code transcripts.
Provides a simple, reliable way to get meaningful information about what Claude did.
"""

import json
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Any
import logging

# Configure logging based on DEBUG environment variable
log_level = logging.DEBUG if os.getenv("CLAUDE_HOOKS_DEBUG") else logging.WARNING
logging.basicConfig(
    level=log_level,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stderr),
        logging.FileHandler('/tmp/claude_hooks_debug.log', mode='a')
    ]
)
logger = logging.getLogger(__name__)


class ContextExtractor:
    """Extract meaningful context from Claude Code transcript files."""

    def extract_from_transcript(self, transcript_path: str, max_messages: int = 20) -> Dict[str, Any]:
        """
        Extract context from the last N messages of a transcript file.
        Uses jq for efficient extraction when available, falls back to Python parsing.

        Returns a simplified context with:
        - files_modified: List of filenames that were changed
        - commands_run: List of commands that were executed
        - primary_activity: What Claude mainly did
        - test_results: Test outcome if tests were run
        - git_operations: Any git commands that were run
        - success: Whether the operation appears successful
        """
        context = {
            'files_modified': [],
            'commands_run': [],
            'primary_activity': 'general',
            'test_results': None,
            'git_operations': [],
            'success': True,
            'errors': []
        }

        try:
            transcript_file = Path(transcript_path)
            if not transcript_file.exists():
                logger.warning(f"Transcript not found: {transcript_path}")
                return context

            # Try to use jq for efficient extraction of last N messages
            messages = self._extract_recent_messages_with_jq(transcript_path, max_messages)

            if not messages:
                # Fallback to Python-based extraction
                logger.debug("jq extraction failed, using Python fallback")
                messages = self._extract_recent_messages_python(transcript_path, max_messages)

            # Process each message
            for entry in messages:
                try:
                    self._process_entry(entry, context)
                except Exception as e:
                    logger.debug(f"Error processing entry: {e}")
                    continue

            # Determine primary activity based on what we found
            context['primary_activity'] = self._determine_primary_activity(context)
            logger.info(f"Extracted context: {context}")

        except Exception as e:
            logger.error(f"Error extracting context: {e}")
            context['success'] = False
            context['errors'].append(str(e))

        return context

    def _extract_recent_messages_with_jq(self, transcript_path: str, max_messages: int) -> List[Dict]:
        """Use jq to efficiently extract the last N messages from transcript."""
        import subprocess

        try:
            # Use jq to get last N lines as JSON objects
            cmd = [
                'jq', '-s', f'.[max(0, length - {max_messages}):][]',
                str(transcript_path)
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)

            if result.returncode != 0:
                logger.debug(f"jq failed: {result.stderr}")
                return []

            # Parse the JSON objects
            messages = []
            for line in result.stdout.strip().split('\n'):
                if line.strip():
                    try:
                        messages.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue

            logger.debug(f"Extracted {len(messages)} messages using jq")
            return messages

        except (subprocess.TimeoutExpired, FileNotFoundError, Exception) as e:
            logger.debug(f"jq extraction failed: {e}")
            return []

    def _extract_recent_messages_python(self, transcript_path: str, max_lines: int) -> List[Dict]:
        """Fallback Python-based extraction of recent messages."""
        try:
            with open(transcript_path, 'r') as f:
                lines = f.readlines()
                recent_lines = lines[-max_lines:] if len(lines) > max_lines else lines

            messages = []
            for line in recent_lines:
                if not line.strip():
                    continue
                try:
                    messages.append(json.loads(line))
                except json.JSONDecodeError:
                    continue

            logger.debug(f"Extracted {len(messages)} messages using Python fallback")
            return messages

        except Exception as e:
            logger.debug(f"Python extraction failed: {e}")
            return []

    def _process_entry(self, entry: Dict, context: Dict) -> None:
        """Process a single transcript entry to extract relevant info."""

        # Look for tool usage in assistant messages
        if entry.get('type') == 'assistant' or entry.get('role') == 'assistant':
            # Check for tool_use field
            if 'tool_use' in entry:
                tools = entry['tool_use'] if isinstance(entry['tool_use'], list) else [entry['tool_use']]
                for tool in tools:
                    if isinstance(tool, dict):
                        self._extract_tool_info(tool, context)

        # Check for tool results
        if entry.get('type') == 'tool_result':
            output = entry.get('output', '')
            if isinstance(output, str):
                # Check for test results
                if 'passed' in output.lower() or 'failed' in output.lower():
                    match = re.search(r'(\d+)\s+(?:test|tests)\s+(?:passed|failed)', output, re.IGNORECASE)
                    if match:
                        context['test_results'] = match.group(0)

                # Check for errors
                if 'error' in output.lower() or 'exception' in output.lower():
                    context['errors'].append('Tool execution error')
                    context['success'] = False

    def _extract_tool_info(self, tool: Dict, context: Dict) -> None:
        """Extract information from a tool use entry."""
        tool_name = tool.get('name', '')
        tool_input = tool.get('input', {})

        # File modification tools
        if tool_name in ['Edit', 'Write', 'MultiEdit']:
            file_path = tool_input.get('file_path', '')
            if file_path:
                filename = Path(file_path).name
                if filename not in context['files_modified']:
                    context['files_modified'].append(filename)
                    logger.debug(f"Found file modification: {filename}")

        # Command execution
        elif tool_name == 'Bash':
            command = tool_input.get('command', '')
            if command:
                # Store command (truncated for readability)
                cmd_display = command if len(command) <= 100 else command[:100] + '...'
                context['commands_run'].append(cmd_display)
                logger.debug(f"Found command: {cmd_display}")

                # Check for git commands
                if command.startswith('git '):
                    git_parts = command.split()
                    if len(git_parts) > 1:
                        git_op = git_parts[1]  # e.g., 'add', 'commit', 'push'
                        context['git_operations'].append(f"git {git_op}")

                # Check for test commands
                if any(test_cmd in command for test_cmd in ['pytest', 'test', 'jest', 'cargo test']):
                    # This is a test command, results will come in tool_result
                    pass

    def _determine_primary_activity(self, context: Dict) -> str:
        """Determine what Claude primarily did based on the context."""

        # If there were errors, that's the primary activity
        if context['errors'] and not context['success']:
            return 'error_encountered'

        # Test results take priority
        if context['test_results']:
            if 'failed' in context['test_results']:
                return 'tests_failed'
            else:
                return 'tests_passed'

        # Git operations
        if context['git_operations']:
            if 'git commit' in context['git_operations']:
                return 'git_commit'
            elif 'git push' in context['git_operations']:
                return 'git_push'
            else:
                return 'git_operation'

        # File modifications
        if context['files_modified']:
            file_count = len(context['files_modified'])
            if file_count == 1:
                file = context['files_modified'][0]
                if file.endswith('.py'):
                    return 'modified_python'
                elif file.endswith(('.js', '.ts', '.jsx', '.tsx')):
                    return 'modified_javascript'
                elif file.endswith('.md'):
                    return 'updated_docs'
                else:
                    return 'modified_file'
            else:
                return 'modified_files'

        # Commands run
        if context['commands_run']:
            for cmd in context['commands_run']:
                if 'lint' in cmd or 'ruff' in cmd or 'eslint' in cmd:
                    return 'linting'
                elif 'build' in cmd:
                    return 'building'
                elif 'install' in cmd:
                    return 'installing'
            return 'ran_commands'

        return 'general'


def extract_context(transcript_path: str) -> Dict[str, Any]:
    """
    Simple function to extract context from a transcript.

    This is the main entry point for other scripts to use.
    """
    extractor = ContextExtractor()
    return extractor.extract_from_transcript(transcript_path)


def main():
    """Main entry point for command-line usage."""
    if len(sys.argv) < 2:
        # Try to read from stdin as JSON
        try:
            input_data = json.loads(sys.stdin.read())
            transcript_path = input_data.get('transcript_path')
            if not transcript_path:
                print(json.dumps({'error': 'No transcript_path in input'}))
                sys.exit(1)
        except:
            print(json.dumps({'error': 'Usage: context_extractor.py <transcript_path> or JSON via stdin'}))
            sys.exit(1)
    else:
        transcript_path = sys.argv[1]

    context = extract_context(transcript_path)

    # Output as JSON
    print(json.dumps(context))


if __name__ == '__main__':
    main()
