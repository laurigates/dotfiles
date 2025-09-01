#!/usr/bin/env python3
"""
Transcript Context Extractor for Claude Voice Notifications

Extracts minimal relevant context from Claude Code transcript files (JSONL format)
to provide meaningful voice notifications about what was actually done.
"""

import json
import sys
import re
from pathlib import Path
from typing import Dict, List, Optional, Any
import logging

logger = logging.getLogger(__name__)


class TranscriptContextExtractor:
    """Extract meaningful context from Claude Code transcript files."""

    def __init__(self):
        """Initialize the extractor with patterns for detecting actions."""
        self.tool_patterns = {
            'Edit': r'"tool":\s*"Edit".*?"file_path":\s*"([^"]+)"',
            'MultiEdit': r'"tool":\s*"MultiEdit".*?"file_path":\s*"([^"]+)"',
            'Write': r'"tool":\s*"Write".*?"file_path":\s*"([^"]+)"',
            'Bash': r'"tool":\s*"Bash".*?"command":\s*"([^"]+)"',
            'Read': r'"tool":\s*"Read".*?"file_path":\s*"([^"]+)"',
            'Grep': r'"tool":\s*"Grep".*?"pattern":\s*"([^"]+)"',
        }

        self.test_patterns = [
            r'(\d+) tests? passed',
            r'(\d+) tests? failed',
            r'All tests passed',
            r'test.*success',
            r'test.*fail'
        ]

        self.error_patterns = [
            r'error:',
            r'Error:',
            r'TypeError',
            r'SyntaxError',
            r'failed',
            r'exception'
        ]

    def extract_from_transcript(self, transcript_path: str, max_lines: int = 100) -> Dict[str, Any]:
        """
        Extract context from the last N lines of a transcript file.

        Args:
            transcript_path: Path to the JSONL transcript file
            max_lines: Maximum number of lines to read from the end

        Returns:
            Context dictionary with extracted information
        """
        context = {
            'files_modified': [],
            'commands_run': [],
            'tools_used': [],
            'git_operations': [],  # Now properly initialized
            'primary_activity': None,
            'test_results': None,
            'errors_encountered': [],
            'last_user_request': None,
            'success_indicators': []
        }

        try:
            transcript_file = Path(transcript_path)
            if not transcript_file.exists():
                logger.warning(f"Transcript file not found: {transcript_path}")
                return context

            # Read the last N lines of the JSONL file
            lines = []
            with open(transcript_file, 'r') as f:
                # Read all lines (each is a JSON object)
                for line in f:
                    lines.append(line.strip())

            # Take only the last max_lines
            recent_lines = lines[-max_lines:] if len(lines) > max_lines else lines

            # Process each JSON line
            for line in recent_lines:
                if not line:
                    continue

                try:
                    entry = json.loads(line)
                    self._process_entry(entry, context)
                except json.JSONDecodeError:
                    # Some lines might not be valid JSON
                    continue

            # Determine primary activity
            context['primary_activity'] = self._determine_primary_activity(context)

        except Exception as e:
            logger.error(f"Error extracting transcript context: {e}")

        return context

    def _process_entry(self, entry: Dict, context: Dict) -> None:
        """Process a single transcript entry."""
        # Check for user messages
        if entry.get('type') == 'user' or entry.get('role') == 'user':
            content = entry.get('content', '')
            if content and len(content) < 200:  # Keep short messages only
                context['last_user_request'] = content[:100]

        # Check for assistant messages with tool use
        if entry.get('type') == 'assistant' or entry.get('role') == 'assistant':
            content = entry.get('content', '')

            # Look for tool usage
            if 'tool_use' in entry or 'tools' in entry:
                self._extract_tools(entry, context)

            # Check content for patterns
            if isinstance(content, str):
                self._extract_from_content(content, context)

        # Check for tool results
        if entry.get('type') == 'tool_result':
            self._process_tool_result(entry, context)

    def _extract_tools(self, entry: Dict, context: Dict) -> None:
        """Extract tool usage from an entry."""
        # Check for tool_use field
        if 'tool_use' in entry:
            tools = entry['tool_use'] if isinstance(entry['tool_use'], list) else [entry['tool_use']]
            for tool in tools:
                if isinstance(tool, dict):
                    tool_name = tool.get('name', '')
                    if tool_name and tool_name not in context['tools_used']:
                        context['tools_used'].append(tool_name)

                    # Extract specific tool data
                    if tool_name == 'Edit' or tool_name == 'Write' or tool_name == 'MultiEdit':
                        file_path = tool.get('input', {}).get('file_path', '')
                        if file_path and file_path not in context['files_modified']:
                            context['files_modified'].append(Path(file_path).name)

                    elif tool_name == 'Bash':
                        command = tool.get('input', {}).get('command', '')
                        if command:
                            # Preserve full command for better context (up to 200 chars)
                            context['commands_run'].append(command[:200])

                            # Detect git operations
                            if command.startswith(('git ', 'gh ')):
                                # Extract git operation type
                                git_cmd_parts = command.split()
                                if len(git_cmd_parts) > 1:
                                    git_op = ' '.join(git_cmd_parts[:2])  # e.g., "git add", "git commit"
                                    if 'git_operations' not in context:
                                        context['git_operations'] = []
                                    context['git_operations'].append(git_op)

    def _extract_from_content(self, content: str, context: Dict) -> None:
        """Extract information from text content."""
        # Check for test results
        for pattern in self.test_patterns:
            match = re.search(pattern, content, re.IGNORECASE)
            if match:
                context['test_results'] = match.group(0)
                if 'passed' in match.group(0).lower() and 'failed' not in match.group(0).lower():
                    context['success_indicators'].append('tests passed')
                break

        # Check for errors
        for pattern in self.error_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                context['errors_encountered'].append(pattern)
                break

        # Look for success indicators
        success_words = ['completed', 'successfully', 'fixed', 'resolved', 'created', 'updated']
        for word in success_words:
            if word in content.lower():
                context['success_indicators'].append(word)

    def _process_tool_result(self, entry: Dict, context: Dict) -> None:
        """Process tool result entries."""
        output = entry.get('output', '')
        if isinstance(output, str):
            # Check for file operations
            if 'has been created' in output or 'has been updated' in output:
                context['success_indicators'].append('file operation successful')

            # Check for test results in output
            if 'passed' in output or 'failed' in output:
                for pattern in self.test_patterns:
                    match = re.search(pattern, output, re.IGNORECASE)
                    if match:
                        context['test_results'] = match.group(0)
                        break

    def _determine_primary_activity(self, context: Dict) -> Optional[str]:
        """Determine the primary activity from the context."""
        # Priority order for determining primary activity
        if context['errors_encountered'] and not context['success_indicators']:
            return 'encountered_errors'

        if context['test_results']:
            if 'failed' in str(context['test_results']):
                return 'tests_failed'
            else:
                return 'tests_passed'

        # Check for specific git operations
        if context['git_operations']:
            if 'git commit' in context['git_operations']:
                return 'git_commit'
            elif 'git push' in context['git_operations']:
                return 'git_push'
            elif 'git add' in context['git_operations']:
                return 'git_staging'
            else:
                return 'git_operation'

        # Check for specific command types
        if context['commands_run']:
            for cmd in context['commands_run']:
                cmd_lower = cmd.lower()
                if 'lint' in cmd_lower or 'ruff' in cmd_lower or 'eslint' in cmd_lower:
                    return 'linting'
                elif 'test' in cmd_lower or 'pytest' in cmd_lower or 'jest' in cmd_lower:
                    return 'testing'
                elif 'build' in cmd_lower or 'compile' in cmd_lower:
                    return 'building'
                elif 'install' in cmd_lower or 'npm i' in cmd or 'pip install' in cmd:
                    return 'installing_dependencies'

        if context['files_modified']:
            # More specific file operation detection
            modified_files = context['files_modified']
            if any(f.endswith('.py') for f in modified_files):
                return 'modified_python_files'
            elif any(f.endswith(('.ts', '.tsx', '.js', '.jsx')) for f in modified_files):
                return 'modified_javascript_files'
            elif any(f.endswith(('.md', '.txt', '.rst')) for f in modified_files):
                return 'updated_documentation'
            elif any(f.endswith(('.yml', '.yaml', '.json', '.toml')) for f in modified_files):
                return 'updated_configuration'
            elif 'Write' in context['tools_used']:
                return 'created_files'
            else:
                return 'modified_files'

        if context['commands_run']:
            return 'ran_commands'

        if context['success_indicators']:
            return 'completed_task'

        return None


def main():
    """Main entry point for testing or direct invocation."""
    # Read JSON input from stdin
    try:
        input_data = json.loads(sys.stdin.read())
        transcript_path = input_data.get('transcript_path')
        project_name = input_data.get('project_name', 'current project')
    except:
        # Fallback for testing
        if len(sys.argv) > 1:
            transcript_path = sys.argv[1]
            project_name = 'test project'
        else:
            print(json.dumps({'error': 'No transcript path provided'}))
            sys.exit(1)

    extractor = TranscriptContextExtractor()
    context = extractor.extract_from_transcript(transcript_path)

    # Add project name to context
    context['project_name'] = project_name

    # Determine event type based on context
    if context['errors_encountered'] and not context['success_indicators']:
        event_type = 'error'
    elif context['test_results']:
        event_type = 'test_success' if 'passed' in str(context['test_results']) else 'test_failure'
    elif context['primary_activity'] == 'created_files':
        event_type = 'creation'
    elif context['success_indicators']:
        event_type = 'success'
    else:
        event_type = 'general'

    # Output the context
    output = {
        'context': context,
        'event_type': event_type
    }

    print(json.dumps(output))


if __name__ == "__main__":
    main()
