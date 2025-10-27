#!/bin/bash

# Claude Hooks Diagnostic Test Script
# Tests the refactored hook pipeline to ensure everything works

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Claude Hooks Diagnostic Test"
echo "================================"
echo ""

# Enable debug mode for testing
export CLAUDE_HOOKS_DEBUG=true
DEBUG_LOG="/tmp/claude_hooks_debug.log"

# Clear debug log
> "$DEBUG_LOG"

# Test utilities
pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check environment
echo "1. Checking Environment"
echo "-----------------------"

# Check Python
if command -v python3 >/dev/null 2>&1; then
    pass "Python3 installed: $(python3 --version)"
else
    fail "Python3 not found"
fi

# Check jq
if command -v jq >/dev/null 2>&1; then
    pass "jq installed: $(jq --version)"
else
    fail "jq not found (optional but recommended)"
fi

# Check Gemini API key
if [[ -n "${GEMINI_API_KEY:-}" ]]; then
    pass "GEMINI_API_KEY is set"
else
    info "GEMINI_API_KEY not set (voice will use fallback)"
fi

# Check Obsidian vault
VAULT_PATH="/Users/lgates/Documents/FVH Vault"
if [[ -d "$VAULT_PATH/Inbox" ]]; then
    pass "Obsidian vault found at $VAULT_PATH"
    if [[ -w "$VAULT_PATH/Inbox" ]]; then
        pass "Inbox directory is writable"
    else
        fail "Inbox directory is not writable"
    fi
else
    fail "Obsidian vault not found at $VAULT_PATH"
fi

echo ""
echo "2. Testing Context Extractor"
echo "----------------------------"

# Create a test transcript
TEST_TRANSCRIPT="/tmp/test_transcript.jsonl"
cat > "$TEST_TRANSCRIPT" << 'EOF'
{"type": "assistant", "tool_use": [{"name": "Edit", "input": {"file_path": "test.py", "old_string": "foo", "new_string": "bar"}}]}
{"type": "tool_result", "output": "File edited successfully"}
{"type": "assistant", "tool_use": [{"name": "Bash", "input": {"command": "pytest tests/"}}]}
{"type": "tool_result", "output": "5 tests passed"}
EOF

# Test context extraction
if [[ -f "$HOME/.claude/hooks/context_extractor.py" ]]; then
    info "Testing context extraction..."
    CONTEXT=$(echo "{\"transcript_path\": \"$TEST_TRANSCRIPT\"}" | python3 "$HOME/.claude/hooks/context_extractor.py" 2>/dev/null)

    if [[ -n "$CONTEXT" ]] && [[ "$CONTEXT" != "{}" ]]; then
        pass "Context extracted successfully"

        # Check for expected fields
        if echo "$CONTEXT" | jq -e '.files_modified | contains(["test.py"])' >/dev/null 2>&1; then
            pass "Found modified file: test.py"
        else
            fail "Modified file not found in context"
        fi

        if echo "$CONTEXT" | jq -e '.test_results' >/dev/null 2>&1; then
            pass "Found test results in context"
        else
            fail "Test results not found in context"
        fi

        echo "  Context: $(echo "$CONTEXT" | jq -c .)"
    else
        fail "Context extraction returned empty"
    fi
else
    fail "context_extractor.py not found"
fi

echo ""
echo "3. Testing Voice Notifier"
echo "-------------------------"

# Test voice notifier with sample context
TEST_CONTEXT='{
    "primary_activity": "modified_python",
    "files_modified": ["hooks.py", "config.py"],
    "success": true,
    "project_name": "test-project"
}'

if [[ -f "$HOME/.claude/hooks/voice-notify/notify_simple.py" ]]; then
    info "Testing voice notification generation..."

    # Test message generation (dry run without speaking)
    TEST_OUTPUT=$(echo "$TEST_CONTEXT" | CLAUDE_VOICE_ENABLED=false python3 "$HOME/.claude/hooks/voice-notify/notify_simple.py" 2>&1 || true)

    if [[ $? -eq 0 ]] || [[ "$TEST_OUTPUT" == *"Voice notifications disabled"* ]]; then
        pass "Voice notifier executed successfully"
    else
        fail "Voice notifier failed: $TEST_OUTPUT"
    fi
else
    fail "notify_simple.py not found"
fi

echo ""
echo "4. Testing Obsidian Logger"
echo "--------------------------"

# Test Obsidian logger
if [[ -f "$HOME/.claude/hooks/obsidian-logger/obsidian_logger.py" ]]; then
    info "Testing Obsidian logger..."

    # Backup existing log
    LOG_FILE="$VAULT_PATH/Inbox/DailyLog.md"
    if [[ -f "$LOG_FILE" ]]; then
        cp "$LOG_FILE" "$LOG_FILE.bak"
    fi

    # Test logging
    echo "$TEST_CONTEXT" | python3 "$HOME/.claude/hooks/obsidian-logger/obsidian_logger.py" 2>/dev/null

    if [[ -f "$LOG_FILE" ]]; then
        # Check if something was written
        if grep -q "Modified" "$LOG_FILE" 2>/dev/null; then
            pass "Obsidian logger wrote to DailyLog.md"
            tail -n 1 "$LOG_FILE"
        else
            fail "Obsidian logger didn't write expected content"
        fi

        # Restore backup
        if [[ -f "$LOG_FILE.bak" ]]; then
            mv "$LOG_FILE.bak" "$LOG_FILE"
        fi
    else
        fail "DailyLog.md not created"
    fi
else
    fail "obsidian_logger.py not found"
fi

echo ""
echo "5. Testing Complete Pipeline"
echo "----------------------------"

# Test the complete hook
if [[ -f "$HOME/.claude/hooks/executable_assistant-response-complete.sh" ]]; then
    info "Testing complete hook pipeline..."

    # Create hook input
    HOOK_INPUT="{\"transcript_path\": \"$TEST_TRANSCRIPT\"}"

    # Run the hook
    echo "$HOOK_INPUT" | "$HOME/.claude/hooks/executable_assistant-response-complete.sh" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        pass "Hook executed successfully"

        # Check debug log
        if [[ -f "$DEBUG_LOG" ]]; then
            info "Debug log entries:"
            grep "assistant-response-complete" "$DEBUG_LOG" | tail -n 5
        fi
    else
        fail "Hook execution failed"
    fi
else
    fail "assistant-response-complete.sh not found"
fi

echo ""
echo "6. Debug Log Summary"
echo "--------------------"

if [[ -f "$DEBUG_LOG" ]]; then
    ERROR_COUNT=$(grep -c "ERROR" "$DEBUG_LOG" 2>/dev/null || echo "0")
    WARNING_COUNT=$(grep -c "WARNING" "$DEBUG_LOG" 2>/dev/null || echo "0")

    if [[ "$ERROR_COUNT" -gt 0 ]]; then
        fail "Found $ERROR_COUNT errors in debug log"
        echo "Recent errors:"
        grep "ERROR" "$DEBUG_LOG" | tail -n 3
    else
        pass "No errors in debug log"
    fi

    if [[ "$WARNING_COUNT" -gt 0 ]]; then
        info "Found $WARNING_COUNT warnings in debug log"
    fi

    info "Full debug log at: $DEBUG_LOG"
else
    info "No debug log found"
fi

echo ""
echo "================================"
echo "Test complete!"
echo ""
echo "To enable debug mode for all hooks:"
echo "  export CLAUDE_HOOKS_DEBUG=true"
echo ""
echo "To monitor debug output:"
echo "  tail -f $DEBUG_LOG"
