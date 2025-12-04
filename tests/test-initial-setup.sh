#!/usr/bin/env bash
# Test suite for run_once_before_00-initial-setup.sh.tmpl
# Validates that the script handles missing commands gracefully (Issue #128)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEZMOI_DIR="$(dirname "$SCRIPT_DIR")"
SETUP_SCRIPT="$CHEZMOI_DIR/run_once_before_00-initial-setup.sh.tmpl"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass_count=0
fail_count=0

# Test helper functions
log_test() {
    echo -e "${YELLOW}TEST:${NC} $*"
}

log_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $*"
    ((pass_count++))
}

log_fail() {
    echo -e "${RED}✗ FAIL:${NC} $*"
    ((fail_count++))
}

# Test 1: Verify script exists
test_script_exists() {
    log_test "Checking if initial setup script exists"
    if [[ -f "$SETUP_SCRIPT" ]]; then
        log_pass "Setup script exists at $SETUP_SCRIPT"
        return 0
    else
        log_fail "Setup script not found at $SETUP_SCRIPT"
        return 1
    fi
}

# Test 2: Verify pre-commit command check exists
test_precommit_check_exists() {
    log_test "Verifying pre-commit command availability check"
    if grep -q "if command -v pre-commit" "$SETUP_SCRIPT"; then
        log_pass "pre-commit availability check found"
        return 0
    else
        log_fail "pre-commit availability check NOT found (Issue #128)"
        return 1
    fi
}

# Test 3: Verify nvim command check exists
test_nvim_check_exists() {
    log_test "Verifying nvim command availability check"
    if grep -q "if command -v nvim" "$SETUP_SCRIPT"; then
        log_pass "nvim availability check found"
        return 0
    else
        log_fail "nvim availability check NOT found"
        return 1
    fi
}

# Test 4: Verify script uses set -euo pipefail (fail-fast)
test_failfast_enabled() {
    log_test "Verifying fail-fast mode is enabled"
    if grep -q "set -euo pipefail" "$SETUP_SCRIPT"; then
        log_pass "Fail-fast mode enabled with 'set -euo pipefail'"
        return 0
    else
        log_fail "Fail-fast mode NOT enabled"
        return 1
    fi
}

# Test 5: Verify no bare pre-commit calls (must be conditional)
test_no_bare_precommit_calls() {
    log_test "Verifying pre-commit is never called without checking availability"
    # Look for pre-commit calls NOT preceded by command -v check
    # This regex finds 'pre-commit' that's not in a comment or command -v line
    if grep -n "pre-commit" "$SETUP_SCRIPT" | grep -v "command -v pre-commit" | grep -v "^[[:space:]]*#" | grep -v "pre-commit not installed"; then
        # Found pre-commit usage - check if it's inside the conditional block
        if grep -A 3 "if command -v pre-commit" "$SETUP_SCRIPT" | grep -q "pre-commit install"; then
            log_pass "pre-commit calls are properly conditional"
            return 0
        else
            log_fail "Found pre-commit call outside conditional check"
            return 1
        fi
    else
        # No pre-commit calls found outside the check
        log_pass "No bare pre-commit calls found"
        return 0
    fi
}

# Test 6: Verify helpful skip messages exist
test_skip_messages_exist() {
    log_test "Verifying helpful skip messages for missing commands"
    local messages_found=0

    if grep -q "Skipping pre-commit hooks installation" "$SETUP_SCRIPT"; then
        ((messages_found++))
    fi

    if grep -q "Skipping neovim plugin installation" "$SETUP_SCRIPT"; then
        ((messages_found++))
    fi

    if [[ $messages_found -eq 2 ]]; then
        log_pass "Found helpful skip messages for both pre-commit and nvim"
        return 0
    else
        log_fail "Missing skip messages ($messages_found/2 found)"
        return 1
    fi
}

# Test 7: Verify script syntax is valid
test_script_syntax() {
    log_test "Verifying script has valid bash syntax"
    # Create a temporary file with template variables replaced
    local temp_script=$(mktemp)
    # Replace chezmoi template with a dummy path for syntax checking
    sed 's/{{ .chezmoi.sourceDir }}/\/tmp\/chezmoi/g' "$SETUP_SCRIPT" > "$temp_script"

    if bash -n "$temp_script" 2>/dev/null; then
        log_pass "Script syntax is valid"
        rm -f "$temp_script"
        return 0
    else
        log_fail "Script has syntax errors"
        rm -f "$temp_script"
        return 1
    fi
}

# Run all tests
echo "========================================"
echo "Initial Setup Script Test Suite"
echo "Testing fix for Issue #128"
echo "========================================"
echo ""

test_script_exists
test_precommit_check_exists
test_nvim_check_exists
test_failfast_enabled
test_no_bare_precommit_calls
test_skip_messages_exist
test_script_syntax

# Summary
echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo -e "${GREEN}Passed:${NC} $pass_count"
echo -e "${RED}Failed:${NC} $fail_count"
echo ""

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo "Issue #128 fix verified: Script handles missing commands gracefully"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    echo "Please review the failures above"
    exit 1
fi
