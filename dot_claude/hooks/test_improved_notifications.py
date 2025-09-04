#!/usr/bin/env python3
"""Test script for improved voice notifications with actual context."""

import json
import sys
import os

# Add the hooks directory to the path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from casual_summarizer import CasualSummarizer

# Test cases with different contexts
test_cases = [
    {
        "name": "Python file update",
        "context": {
            "primary_activity": "modified_python_files",
            "files_modified": ["notify.py", "config.py"],
            "tools_used": ["Edit", "MultiEdit"],
            "success_indicators": ["updated"]
        },
        "event_type": "success"
    },
    {
        "name": "Tests passed",
        "context": {
            "primary_activity": "tests_passed",
            "test_results": "15 tests passed",
            "commands_run": ["pytest tests/"],
            "success_indicators": ["tests passed"]
        },
        "event_type": "test_success"
    },
    {
        "name": "Git commit",
        "context": {
            "primary_activity": "git_commit",
            "git_operations": ["git add", "git commit"],
            "files_modified": ["README.md", "setup.py"],
            "success_indicators": ["committed"]
        },
        "event_type": "git_operation"
    },
    {
        "name": "Documentation update",
        "context": {
            "primary_activity": "updated_documentation",
            "files_modified": ["README.md", "CONTRIBUTING.md", "docs/api.md"],
            "tools_used": ["Edit", "Write"],
            "success_indicators": ["updated"]
        },
        "event_type": "success"
    },
    {
        "name": "Linting",
        "context": {
            "primary_activity": "linting",
            "commands_run": ["ruff check . --fix", "ruff format ."],
            "success_indicators": ["completed"]
        },
        "event_type": "success"
    },
    {
        "name": "Build project",
        "context": {
            "primary_activity": "building",
            "commands_run": ["npm run build", "webpack --mode production"],
            "success_indicators": ["built"]
        },
        "event_type": "success"
    },
    {
        "name": "Install dependencies",
        "context": {
            "primary_activity": "installing_dependencies",
            "commands_run": ["uv sync", "npm install"],
            "success_indicators": ["installed"]
        },
        "event_type": "success"
    },
    {
        "name": "Multiple file modifications",
        "context": {
            "files_modified": ["app.ts", "components/Header.tsx", "utils/helpers.js", "styles.css", "index.html"],
            "tools_used": ["Edit", "MultiEdit"],
            "success_indicators": ["modified"]
        },
        "event_type": "success"
    },
    {
        "name": "Single command execution",
        "context": {
            "commands_run": ["docker-compose up -d --build"],
            "tools_used": ["Bash"],
            "success_indicators": ["executed"]
        },
        "event_type": "success"
    }
]

def test_summaries():
    """Test the summarizer with various contexts."""
    summarizer = CasualSummarizer()

    print("Testing Improved Voice Notifications")
    print("=" * 50)
    print()

    for test_case in test_cases:
        print(f"Test: {test_case['name']}")
        print("-" * 30)

        # Generate summary
        summary = summarizer.generate_summary(test_case['context'], test_case['event_type'])

        print(f"Context: {json.dumps(test_case['context'], indent=2)}")
        print(f"Event Type: {test_case['event_type']}")
        print(f"Generated Message: '{summary}'")
        print()

    # Test with minimal context (should fall back gracefully)
    print("Test: Minimal context fallback")
    print("-" * 30)
    minimal_context = {
        "success_indicators": ["completed"]
    }
    summary = summarizer.generate_summary(minimal_context, "general")
    print(f"Generated Message: '{summary}'")
    print()

if __name__ == "__main__":
    test_summaries()
