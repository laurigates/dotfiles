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
    # Use assignment, not ((x++)): under `set -e` the post-increment returns
    # exit 1 when the pre-value is 0, which would abort after the first PASS.
    pass_count=$((pass_count + 1))
}

log_fail() {
    echo -e "${RED}✗ FAIL:${NC} $*"
    fail_count=$((fail_count + 1))
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

# bare_precommit_calls <file>: print "<line>: <text>" for each line that uses
# pre-commit outside the `if command -v pre-commit` branch. Comments and echo
# lines are messages, not calls. The branch runs from the `if` to the `else`
# or `fi` at the same indentation, so a nested if inside it does not end it.
#
# This replaced a `grep -A 3 "if command -v pre-commit" | grep "pre-commit
# install"` window. The script grew a comment and a core.hooksPath guard
# between the `if` and `pre-commit install`, the window stopped reaching it,
# and the test failed on a correct script (#439).
bare_precommit_calls() {
    awk '
        /^[[:space:]]*if command -v pre-commit/ { match($0, /^[[:space:]]*/); indent = RLENGTH; inside = 1; next }
        inside {
            match($0, /^[[:space:]]*/)
            if (RLENGTH == indent && $0 ~ /^[[:space:]]*(else|fi)([[:space:]]|$)/) inside = 0
            next
        }
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*echo[[:space:]]/ { next }
        /pre-commit/ { printf "%d: %s\n", NR, $0 }
    ' "$1"
}

# Test 5: Verify no bare pre-commit calls (must be conditional)
test_no_bare_precommit_calls() {
    log_test "Verifying pre-commit is never called without checking availability"
    local bare
    bare=$(bare_precommit_calls "$SETUP_SCRIPT")
    if [[ -n "$bare" ]]; then
        echo "$bare"
        log_fail "Found pre-commit call outside conditional check"
        return 1
    fi
    # A detector that finds nothing proves nothing: plant a bare call before
    # the check and another in the not-installed branch; both must be found.
    local planted found
    planted=$(mktemp)
    awk '/^if command -v pre-commit/ { print "pre-commit run --all-files"; seen = 1 }
         { print }
         seen && /^else/ && !planted { print "pre-commit install"; planted = 1 }' "$SETUP_SCRIPT" > "$planted"
    found=$(bare_precommit_calls "$planted" | wc -l)
    rm -f "$planted"
    if [[ $found -ne 2 ]]; then
        log_fail "Detector found $found of 2 planted bare pre-commit calls"
        return 1
    fi
    log_pass "pre-commit calls are all inside the availability check (detector finds planted bare calls)"
    return 0
}

# Test 6: Verify helpful skip messages exist
test_skip_messages_exist() {
    log_test "Verifying helpful skip messages for missing commands"
    local messages_found=0

    if grep -q "Skipping pre-commit hooks installation" "$SETUP_SCRIPT"; then
        messages_found=$((messages_found + 1))
    fi

    if grep -q "Skipping neovim plugin installation" "$SETUP_SCRIPT"; then
        messages_found=$((messages_found + 1))
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
    local temp_script
    temp_script=$(mktemp)
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
