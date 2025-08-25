#!/usr/bin/env python3
"""
Casual Summarizer for Claude Voice Notifications

Generates natural, conversational summaries of Claude's activities
using the Gemini API for more engaging voice notifications.
"""

import json
import os
import random
from typing import Dict, Optional, Any, List
import logging

logger = logging.getLogger(__name__)

try:
    from google import genai
    from google.genai import types
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    logger.warning("google-genai not installed. Falling back to template-based summaries.")


class CasualSummarizer:
    """Generate casual, conversational summaries of Claude's activities."""

    def __init__(self):
        """Initialize the summarizer with Gemini API if available."""
        self.gemini_model = None

        if GEMINI_AVAILABLE:
            api_key = os.getenv("GOOGLE_API_KEY")
            if api_key:
                try:
                    client = genai.Client(api_key=api_key)
                    self.gemini_model = client
                    logger.info("Gemini API initialized for casual summarization")
                except Exception as e:
                    logger.error(f"Failed to initialize Gemini: {e}")

        # Fallback templates for when Gemini is unavailable
        self.templates = {
            'success': [
                "I just {action} {target}!",
                "Hey! I've {action} {target} for you.",
                "All done! I {action} {target}.",
                "Great news - I've {action} {target}!"
            ],
            'error': [
                "I ran into some issues while {action} {target}.",
                "Hmm, there were problems {action} {target}.",
                "I encountered errors when {action} {target}.",
                "Something went wrong while {action} {target}."
            ],
            'test_success': [
                "Good news! All {count} tests passed!",
                "Tests are looking great - {count} passed without issues!",
                "Perfect! {count} tests ran successfully!"
            ],
            'test_failure': [
                "Heads up - {failed} tests failed out of {total}.",
                "We've got {failed} failing tests to look at.",
                "Test results: {passed} passed, but {failed} need attention."
            ],
            'git_operation': [
                "I've {action} your git repository.",
                "Git operation complete: {action}.",
                "Version control updated - {action}."
            ],
            'bug_fix': [
                "I fixed the {issue} in {location}!",
                "Bug squashed! The {issue} is resolved.",
                "Problem solved - fixed {issue}!"
            ],
            'creation': [
                "I created {what} for you!",
                "New {what} is ready to go!",
                "Just finished creating {what}!"
            ],
            'general': [
                "I've completed the task you requested.",
                "Task finished successfully!",
                "All done with that!"
            ]
        }

    def generate_summary(self, context: Dict[str, Any], event_type: str) -> str:
        """
        Generate a casual summary based on the context and event type.

        Args:
            context: Parsed context from event_context_parser
            event_type: Type of event (success, error, etc.)

        Returns:
            Casual, conversational summary string
        """
        if self.gemini_model:
            return self._generate_with_gemini(context, event_type)
        else:
            return self._generate_with_templates(context, event_type)

    def _generate_with_gemini(self, context: Dict[str, Any], event_type: str) -> str:
        """Use Gemini API to generate a natural summary."""
        try:
            # Build a comprehensive prompt
            prompt = self._build_gemini_prompt(context, event_type)

            response = self.gemini_model.models.generate_content(
                model="gemini-2.0-flash-exp",
                contents=prompt
            )

            if response and response.text:
                # Clean up the response
                summary = response.text.strip()
                # Remove quotes if Gemini added them
                if summary.startswith('"') and summary.endswith('"'):
                    summary = summary[1:-1]
                return summary

        except Exception as e:
            logger.error(f"Gemini generation failed: {e}")

        # Fall back to templates
        return self._generate_with_templates(context, event_type)

    def _build_gemini_prompt(self, context: Dict[str, Any], event_type: str) -> str:
        """Build a prompt for Gemini to generate a casual summary."""

        # Start with the base instruction
        prompt = """Generate a brief, casual, and friendly voice notification message based on the following context.
The message should be conversational, like a helpful colleague telling you what they just did.
Keep it under 15 words and make it natural for text-to-speech.

Context:
"""

        # Add relevant context details
        if context.get('primary_activity'):
            prompt += f"- Primary activity: {context['primary_activity']}\n"

        if context.get('files_modified'):
            files_list = ', '.join(context['files_modified'][:3])
            prompt += f"- Files modified: {files_list}\n"

        if context.get('tools_used'):
            tools_list = ', '.join(context['tools_used'][:3])
            prompt += f"- Tools used: {tools_list}\n"

        if context.get('commands_run'):
            prompt += f"- Commands run: {', '.join(context['commands_run'][:2])}\n"

        if context.get('tests_results'):
            results = context['tests_results']
            prompt += f"- Test results: {results}\n"

        if context.get('errors_encountered'):
            prompt += f"- Errors: {len(context['errors_encountered'])} encountered\n"

        if context.get('git_operations'):
            prompt += f"- Git operations: {', '.join(context['git_operations'][:2])}\n"

        # Add tone guidance based on event type
        tone_map = {
            'success': "cheerful and satisfied",
            'error': "concerned but helpful",
            'test_success': "happy and encouraging",
            'test_failure': "supportive and informative",
            'git_operation': "professional and clear",
            'bug_fix': "proud and accomplished",
            'creation': "excited and enthusiastic",
            'general': "friendly and casual"
        }

        tone = tone_map.get(event_type, "friendly and casual")
        prompt += f"\nTone: {tone}\n"
        prompt += f"Event type: {event_type}\n"

        # Add examples for consistency
        prompt += """
Examples of good messages:
- "Just fixed those TypeScript errors in your components!"
- "I've updated your Docker config and it's ready to go!"
- "Created the new API endpoints you needed!"
- "Ran into some build issues - check the logs!"

Now generate a similar casual message for the above context:"""

        return prompt

    def _generate_with_templates(self, context: Dict[str, Any], event_type: str) -> str:
        """Generate a summary using fallback templates."""
        templates = self.templates.get(event_type, self.templates['general'])
        template = random.choice(templates)

        # Fill in template variables based on context
        try:
            if event_type == 'success':
                action = self._get_action_verb(context)
                target = self._get_target(context)
                return template.format(action=action, target=target)

            elif event_type == 'error':
                action = self._get_action_verb(context) + "ing"
                target = self._get_target(context)
                return template.format(action=action, target=target)

            elif event_type == 'test_success':
                count = context.get('tests_results', {}).get('passed', 'all')
                return template.format(count=count)

            elif event_type == 'test_failure':
                results = context.get('tests_results', {})
                failed = results.get('failed', 'some')
                passed = results.get('passed', 0)
                total = passed + failed if isinstance(failed, int) else 'multiple'
                return template.format(failed=failed, total=total, passed=passed)

            elif event_type == 'git_operation':
                ops = context.get('git_operations', [])
                action = ops[0] if ops else 'updated'
                return template.format(action=action)

            elif event_type == 'bug_fix':
                issue = "issue" if not context.get('errors_encountered') else "error"
                location = self._get_location(context)
                return template.format(issue=issue, location=location)

            elif event_type == 'creation':
                what = self._get_what_created(context)
                return template.format(what=what)

            else:
                return template

        except Exception as e:
            logger.error(f"Template formatting failed: {e}")
            return random.choice(self.templates['general'])

    def _get_action_verb(self, context: Dict[str, Any]) -> str:
        """Extract or infer the main action verb."""
        activity = context.get('primary_activity')

        if activity:
            verb_map = {
                'created': 'created',
                'modified': 'updated',
                'fixed': 'fixed',
                'analyzed': 'analyzed',
                'configured': 'configured',
                'documented': 'documented'
            }
            return verb_map.get(activity, 'completed')

        # Infer from tools used
        if 'Write' in context.get('tools_used', []):
            return 'created'
        elif 'Edit' in context.get('tools_used', []):
            return 'updated'
        elif 'Bash' in context.get('tools_used', []):
            return 'executed'

        return 'completed'

    def _get_target(self, context: Dict[str, Any]) -> str:
        """Determine what was acted upon."""
        # Check for files
        if context.get('files_modified'):
            count = len(context['files_modified'])
            if count == 1:
                file = os.path.basename(context['files_modified'][0])
                return file
            else:
                return f"{count} files"

        # Check for specific tools/operations
        if context.get('git_operations'):
            return "the repository"

        if context.get('tests_results'):
            return "the tests"

        if context.get('commands_run'):
            return "the commands"

        return "the task"

    def _get_location(self, context: Dict[str, Any]) -> str:
        """Get location description for fixes."""
        if context.get('files_modified'):
            if len(context['files_modified']) == 1:
                return os.path.basename(context['files_modified'][0])
            else:
                return "your code"
        return "the project"

    def _get_what_created(self, context: Dict[str, Any]) -> str:
        """Determine what was created."""
        files = context.get('files_modified', [])

        if files:
            if len(files) == 1:
                file = files[0]
                if file.endswith('.py'):
                    return "a Python module"
                elif file.endswith('.js') or file.endswith('.ts'):
                    return "a JavaScript module"
                elif file.endswith('.md'):
                    return "documentation"
                elif file.endswith('.json'):
                    return "a configuration"
                else:
                    return f"a new {os.path.splitext(file)[1][1:]} file"
            else:
                return f"{len(files)} new files"

        return "new content"

    def get_personalized_greeting(self, project_name: Optional[str] = None) -> str:
        """Generate a personalized greeting based on context."""
        greetings = [
            "Hey there!",
            "Hi!",
            "Hello!",
            "Alright,",
            "So,",
            "Great news -",
            "Quick update -"
        ]

        if project_name:
            greetings.extend([
                f"For {project_name}:",
                f"In {project_name}:",
                f"About {project_name}:"
            ])

        return random.choice(greetings)

    def add_personality(self, summary: str, event_type: str) -> str:
        """Add personality touches to the summary."""
        # Add enthusiasm for successes
        if event_type in ['success', 'creation', 'test_success']:
            enthusiastic_endings = [
                " Nice!",
                " All set!",
                " Done!",
                " Ready to go!",
                ""  # Sometimes no addition is best
            ]
            if not any(summary.endswith(e) for e in ['!', '?']):
                summary += random.choice(enthusiastic_endings)

        # Add empathy for errors
        elif event_type in ['error', 'test_failure']:
            if not any(phrase in summary.lower() for phrase in ['but', 'though', 'however']):
                empathetic_additions = [
                    " Let me know if you need help!",
                    " Want me to investigate?",
                    " Check the details above.",
                    ""
                ]
                summary += random.choice(empathetic_additions)

        return summary


def main():
    """Main entry point for testing the summarizer."""
    import sys

    # Read context from stdin (would come from event_context_parser)
    try:
        input_data = json.loads(sys.stdin.read())
        context = input_data.get('context', {})
        event_type = input_data.get('event_type', 'general')
    except:
        # Test data if no stdin
        context = {
            'primary_activity': 'fixed',
            'files_modified': ['src/main.py', 'tests/test_main.py'],
            'tools_used': ['Edit', 'Bash'],
            'success_indicators': ['All tests passed']
        }
        event_type = 'bug_fix'

    summarizer = CasualSummarizer()

    # Generate summary
    summary = summarizer.generate_summary(context, event_type)

    # Add personality
    summary = summarizer.add_personality(summary, event_type)

    # Add optional greeting
    if random.random() > 0.5:
        greeting = summarizer.get_personalized_greeting()
        summary = f"{greeting} {summary}"

    print(summary)


if __name__ == "__main__":
    main()
