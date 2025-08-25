#!/usr/bin/env python3
"""
Event Context Parser for Claude Voice Notifications

Extracts meaningful context from Claude's hook input to provide
rich information for voice notifications.
"""

import json
import re
import sys
from typing import Dict, List, Optional, Any
from pathlib import Path


class EventContextParser:
    """Parse Claude's response to extract meaningful context for notifications."""

    def __init__(self):
        """Initialize the parser with patterns for common Claude activities."""
        self.tool_patterns = {
            'file_operations': [
                r'(?:Read|Write|Edit|MultiEdit|NotebookEdit)\(',
                r'modified (\S+)',
                r'created (\S+)',
                r'deleted (\S+)'
            ],
            'bash_commands': [
                r'Bash\(command="([^"]+)"',
                r'```bash\n([^`]+)\n```',
                r'Running: (.+)'
            ],
            'search_operations': [
                r'(?:Grep|Glob|LS)\(',
                r'searching for (.+)',
                r'found (\d+) (?:files?|results?)'
            ],
            'git_operations': [
                r'git (?:commit|push|pull|merge|checkout)',
                r'(?:created|updated) (?:branch|PR|pull request)',
                r'committed changes'
            ],
            'testing': [
                r'(?:pytest|npm test|cargo test|go test)',
                r'(\d+) tests? (?:passed|failed)',
                r'test coverage: (\d+)%'
            ],
            'errors': [
                r'(?:error|exception|failed|failure)',
                r'TypeError|ValueError|SyntaxError|RuntimeError',
                r'compilation failed'
            ]
        }

        self.activity_keywords = {
            'created': ['created', 'added', 'implemented', 'built', 'generated'],
            'modified': ['modified', 'updated', 'changed', 'edited', 'refactored'],
            'fixed': ['fixed', 'resolved', 'corrected', 'repaired', 'debugged'],
            'analyzed': ['analyzed', 'reviewed', 'examined', 'inspected', 'investigated'],
            'configured': ['configured', 'setup', 'installed', 'initialized'],
            'documented': ['documented', 'explained', 'described', 'annotated']
        }

    def parse_stdin(self, input_data: str) -> Dict[str, Any]:
        """
        Parse stdin data from Claude's response.

        Args:
            input_data: Raw input from stdin

        Returns:
            Parsed context dictionary
        """
        context = {
            'tools_used': [],
            'files_modified': [],
            'commands_run': [],
            'errors_encountered': [],
            'tests_results': None,
            'git_operations': [],
            'primary_activity': None,
            'success_indicators': [],
            'task_summary': None
        }

        # Try to parse as JSON first (some hooks may send structured data)
        try:
            json_data = json.loads(input_data)
            if isinstance(json_data, dict):
                return self._parse_json_context(json_data)
        except (json.JSONDecodeError, ValueError):
            pass

        # Fall back to text parsing
        return self._parse_text_context(input_data)

    def _parse_json_context(self, data: Dict) -> Dict[str, Any]:
        """Parse structured JSON context from hooks."""
        context = {
            'tools_used': data.get('tools', []),
            'files_modified': data.get('files', []),
            'commands_run': data.get('commands', []),
            'errors_encountered': data.get('errors', []),
            'tests_results': data.get('tests'),
            'git_operations': data.get('git', []),
            'primary_activity': data.get('activity'),
            'success_indicators': data.get('success', []),
            'task_summary': data.get('summary')
        }
        return context

    def _parse_text_context(self, text: str) -> Dict[str, Any]:
        """Parse unstructured text from Claude's response."""
        context = {
            'tools_used': self._extract_tools(text),
            'files_modified': self._extract_files(text),
            'commands_run': self._extract_commands(text),
            'errors_encountered': self._extract_errors(text),
            'tests_results': self._extract_test_results(text),
            'git_operations': self._extract_git_operations(text),
            'primary_activity': self._determine_primary_activity(text),
            'success_indicators': self._extract_success_indicators(text),
            'task_summary': self._generate_summary(text)
        }
        return context

    def _extract_tools(self, text: str) -> List[str]:
        """Extract tools used from the text."""
        tools = set()

        # Look for tool invocations
        tool_names = ['Read', 'Write', 'Edit', 'MultiEdit', 'Bash', 'Grep',
                      'Glob', 'LS', 'WebFetch', 'Task', 'TodoWrite']
        for tool in tool_names:
            if tool in text:
                tools.add(tool)

        # Look for MCP tool invocations
        mcp_pattern = r'mcp__(\w+)__(\w+)'
        for match in re.finditer(mcp_pattern, text):
            tools.add(f"{match.group(1)}:{match.group(2)}")

        return list(tools)

    def _extract_files(self, text: str) -> List[str]:
        """Extract file paths that were modified."""
        files = set()

        # Common file operation patterns
        patterns = [
            r'(?:modified|created|updated|wrote to|edited) ([/\w\-_.]+\.\w+)',
            r'File: ([/\w\-_.]+\.\w+)',
            r'([/\w\-_.]+\.\w+)(?:\s+(?:modified|created|updated))',
            r'`([/\w\-_.]+\.\w+)`'
        ]

        for pattern in patterns:
            for match in re.finditer(pattern, text, re.IGNORECASE):
                file_path = match.group(1)
                if self._is_valid_file_path(file_path):
                    files.add(file_path)

        return list(files)

    def _extract_commands(self, text: str) -> List[str]:
        """Extract bash commands that were run."""
        commands = []

        # Look for command patterns
        patterns = [
            r'Bash\(command="([^"]+)"',
            r'Running: (.+)',
            r'Executing: (.+)',
            r'```bash\n([^`]+)\n```'
        ]

        for pattern in patterns:
            for match in re.finditer(pattern, text):
                command = match.group(1).strip()
                if command and not command in commands:
                    commands.append(command)

        return commands

    def _extract_errors(self, text: str) -> List[str]:
        """Extract error messages and issues."""
        errors = []

        # Error patterns
        patterns = [
            r'((?:Error|Exception|Failed|Failure):.+)',
            r'(\w+Error:.+)',
            r'(FAILED.+)',
            r'(✗.+)'
        ]

        for pattern in patterns:
            for match in re.finditer(pattern, text):
                error = match.group(1).strip()
                if error and error not in errors:
                    errors.append(error)

        return errors

    def _extract_test_results(self, text: str) -> Optional[Dict]:
        """Extract test results if present."""
        # Look for test result patterns
        patterns = [
            r'(\d+) (?:tests?) passed',
            r'(\d+) (?:tests?) failed',
            r'(\d+) (?:tests?) skipped',
            r'test coverage: (\d+)%'
        ]

        results = {}
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                if 'passed' in pattern:
                    results['passed'] = int(match.group(1))
                elif 'failed' in pattern:
                    results['failed'] = int(match.group(1))
                elif 'skipped' in pattern:
                    results['skipped'] = int(match.group(1))
                elif 'coverage' in pattern:
                    results['coverage'] = int(match.group(1))

        return results if results else None

    def _extract_git_operations(self, text: str) -> List[str]:
        """Extract git operations performed."""
        operations = []

        patterns = [
            r'git (\w+)',
            r'(committed|pushed|pulled|merged) .+',
            r'created (?:branch|PR|pull request) (.+)'
        ]

        for pattern in patterns:
            for match in re.finditer(pattern, text, re.IGNORECASE):
                operations.append(match.group(0))

        return operations

    def _determine_primary_activity(self, text: str) -> Optional[str]:
        """Determine the primary activity type."""
        text_lower = text.lower()

        # Check for activity keywords
        activity_scores = {}
        for activity, keywords in self.activity_keywords.items():
            score = sum(1 for keyword in keywords if keyword in text_lower)
            if score > 0:
                activity_scores[activity] = score

        if activity_scores:
            return max(activity_scores, key=activity_scores.get)

        return None

    def _extract_success_indicators(self, text: str) -> List[str]:
        """Extract indicators of successful completion."""
        indicators = []

        success_patterns = [
            r'✓ (.+)',
            r'Successfully (.+)',
            r'Completed (.+)',
            r'(\d+) tests? passed',
            r'All checks passed'
        ]

        for pattern in success_patterns:
            for match in re.finditer(pattern, text):
                indicators.append(match.group(0))

        return indicators

    def _generate_summary(self, text: str) -> Optional[str]:
        """Generate a brief summary of the main action."""
        # Look for summary-like sentences
        lines = text.split('\n')
        for line in lines:
            if any(keyword in line.lower() for keyword in ['completed', 'finished', 'done', 'created', 'fixed']):
                return line.strip()

        # Fall back to first meaningful line
        for line in lines:
            if len(line.strip()) > 20 and not line.startswith('#'):
                return line.strip()[:100] + '...' if len(line) > 100 else line.strip()

        return None

    def _is_valid_file_path(self, path: str) -> bool:
        """Check if a string looks like a valid file path."""
        # Basic validation - has extension and reasonable characters
        if not re.match(r'^[\w\-_./]+\.\w+$', path):
            return False

        # Avoid matching version numbers or URLs
        if re.match(r'^\d+\.\d+', path) or path.startswith('http'):
            return False

        return True

    def get_event_type(self, context: Dict) -> str:
        """Determine the event type from context."""
        if context.get('errors_encountered'):
            return 'error'
        elif context.get('tests_results'):
            if context['tests_results'].get('failed', 0) > 0:
                return 'test_failure'
            else:
                return 'test_success'
        elif context.get('git_operations'):
            return 'git_operation'
        elif context.get('primary_activity') == 'fixed':
            return 'bug_fix'
        elif context.get('primary_activity') == 'created':
            return 'creation'
        elif context.get('success_indicators'):
            return 'success'
        else:
            return 'general'


def main():
    """Main entry point for testing the parser."""
    parser = EventContextParser()

    # Read from stdin
    input_data = sys.stdin.read()

    # Parse the context
    context = parser.parse_stdin(input_data)
    event_type = parser.get_event_type(context)

    # Output the parsed context
    output = {
        'context': context,
        'event_type': event_type
    }

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
