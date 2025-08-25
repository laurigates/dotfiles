#!/bin/bash

# Test script for enhanced voice notification pipeline
# Tests the event context parser, casual summarizer, and voice notification

set -euo pipefail

HOOKS_DIR="$HOME/.claude/hooks"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Testing Enhanced Voice Notification Pipeline"
echo "============================================"

# Test 1: Simple success case
echo -e "\nTest 1: Simple success notification"
echo "-----------------------------------"
TEST_INPUT='Successfully updated configuration files and ran tests.'
echo "$TEST_INPUT" | python3 "$SCRIPT_DIR/event_context_parser.py" | python3 "$SCRIPT_DIR/casual_summarizer.py"

# Test 2: File modification with tools
echo -e "\nTest 2: File modification context"
echo "---------------------------------"
TEST_INPUT='Edit(file_path="/Users/lgates/project/main.py")
Modified main.py to fix the import error.
All tests passed successfully.'
echo "$TEST_INPUT" | python3 "$SCRIPT_DIR/event_context_parser.py" | python3 "$SCRIPT_DIR/casual_summarizer.py"

# Test 3: Error scenario
echo -e "\nTest 3: Error handling"
echo "----------------------"
TEST_INPUT='Bash(command="pytest")
Error: 3 tests failed
TypeError: unsupported operand type'
echo "$TEST_INPUT" | python3 "$SCRIPT_DIR/event_context_parser.py" | python3 "$SCRIPT_DIR/casual_summarizer.py"

# Test 4: Git operation
echo -e "\nTest 4: Git operation"
echo "---------------------"
TEST_INPUT='git commit -m "feat: add voice notifications"
Successfully committed changes to repository.'
echo "$TEST_INPUT" | python3 "$SCRIPT_DIR/event_context_parser.py" | python3 "$SCRIPT_DIR/casual_summarizer.py"

# Test 5: Full pipeline with voice (if available)
echo -e "\nTest 5: Full pipeline with voice notification"
echo "---------------------------------------------"
if command -v python3 >/dev/null 2>&1 && [[ -f "$SCRIPT_DIR/voice-notify.py" ]]; then
    TEST_INPUT='Created new Python module for data processing.
    Added comprehensive test coverage.
    All 25 tests passed successfully!'

    # Parse context
    CONTEXT_JSON=$(echo "$TEST_INPUT" | python3 "$SCRIPT_DIR/event_context_parser.py")

    # Generate summary
    SUMMARY=$(echo "$CONTEXT_JSON" | python3 "$SCRIPT_DIR/casual_summarizer.py")

    # Extract event type
    EVENT_TYPE=$(echo "$CONTEXT_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('event_type', 'general'))" 2>/dev/null || echo "general")

    echo "Generated summary: $SUMMARY"
    echo "Event type: $EVENT_TYPE"

    # Trigger voice notification
    echo "Triggering voice notification..."
    python3 "$SCRIPT_DIR/voice-notify.py" "$SUMMARY" "test_project" "$EVENT_TYPE"

    echo "Voice notification sent!"
else
    echo "Voice notification script not available, skipping voice test"
fi

echo -e "\nPipeline test complete!"
echo "======================="
echo "If you heard a voice notification, the pipeline is working correctly!"
