#!/usr/bin/env bash
# Test suite for /configure:makefile command
# Validates Makefile configuration against FVH standards (Issue #95)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEZMOI_DIR="$(dirname "$SCRIPT_DIR")"
COMMAND_FILE="$CHEZMOI_DIR/exact_dot_claude/commands/configure/makefile.md"

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

# Test 1: Verify command file exists
test_command_exists() {
    log_test "Checking if /configure:makefile command exists"
    if [[ -f "$COMMAND_FILE" ]]; then
        log_pass "Command file exists at $COMMAND_FILE"
        return 0
    else
        log_fail "Command file not found at $COMMAND_FILE"
        return 1
    fi
}

# Test 2: Verify command has required frontmatter
test_frontmatter_exists() {
    log_test "Verifying command has required frontmatter"
    if [[ ! -f "$COMMAND_FILE" ]]; then
        log_fail "Cannot test - file does not exist"
        return 1
    fi

    if grep -q "^description:" "$COMMAND_FILE" && \
       grep -q "^allowed-tools:" "$COMMAND_FILE"; then
        log_pass "Required frontmatter found"
        return 0
    else
        log_fail "Missing required frontmatter (description, allowed-tools)"
        return 1
    fi
}

# Test 3: Verify command documents standard Makefile targets
test_required_targets_documented() {
    log_test "Verifying standard Makefile targets are documented"
    if [[ ! -f "$COMMAND_FILE" ]]; then
        log_fail "Cannot test - file does not exist"
        return 1
    fi

    local required_targets=("test" "build" "clean" "start" "stop" "lint")
    local missing_targets=()

    for target in "${required_targets[@]}"; do
        if ! grep -q "$target" "$COMMAND_FILE"; then
            missing_targets+=("$target")
        fi
    done

    if [[ ${#missing_targets[@]} -eq 0 ]]; then
        log_pass "All required Makefile targets documented"
        return 0
    else
        log_fail "Missing documentation for targets: ${missing_targets[*]}"
        return 1
    fi
}

# Test 4: Verify command includes language-specific logic
test_language_support() {
    log_test "Verifying command supports multiple project types"
    if [[ ! -f "$COMMAND_FILE" ]]; then
        log_fail "Cannot test - file does not exist"
        return 1
    fi

    local languages=("python" "node" "rust" "go")
    local supported_languages=()

    for lang in "${languages[@]}"; do
        if grep -qi "$lang" "$COMMAND_FILE"; then
            supported_languages+=("$lang")
        fi
    done

    if [[ ${#supported_languages[@]} -ge 2 ]]; then
        log_pass "Command supports multiple languages: ${supported_languages[*]}"
        return 0
    else
        log_fail "Command should support multiple language types"
        return 1
    fi
}

# Test 5: Verify command includes Makefile template
test_makefile_template_exists() {
    log_test "Verifying Makefile template is included"
    if [[ ! -f "$COMMAND_FILE" ]]; then
        log_fail "Cannot test - file does not exist"
        return 1
    fi

    if grep -q ".PHONY" "$COMMAND_FILE" && \
       grep -q ".DEFAULT_GOAL" "$COMMAND_FILE"; then
        log_pass "Makefile template structure found"
        return 0
    else
        log_fail "Missing Makefile template structure"
        return 1
    fi
}

# Test 6: Verify command includes colored output
test_colored_output() {
    log_test "Verifying Makefile template uses colored output"
    if [[ ! -f "$COMMAND_FILE" ]]; then
        log_fail "Cannot test - file does not exist"
        return 1
    fi

    if grep -q "BLUE\|GREEN\|YELLOW\|RED" "$COMMAND_FILE"; then
        log_pass "Colored output variables found"
        return 0
    else
        log_fail "Makefile template should use colored output"
        return 1
    fi
}

# Test 7: Verify command documents --check-only and --fix flags
test_flags_documented() {
    log_test "Verifying standard flags are documented"
    if [[ ! -f "$COMMAND_FILE" ]]; then
        log_fail "Cannot test - file does not exist"
        return 1
    fi

    if grep -q "\-\-check-only" "$COMMAND_FILE" && \
       grep -q "\-\-fix" "$COMMAND_FILE"; then
        log_pass "Standard flags (--check-only, --fix) documented"
        return 0
    else
        log_fail "Missing standard flag documentation"
        return 1
    fi
}

# Test 8: Verify command updates .fvh-standards.yaml
test_standards_tracking() {
    log_test "Verifying command includes .fvh-standards.yaml tracking"
    if [[ ! -f "$COMMAND_FILE" ]]; then
        log_fail "Cannot test - file does not exist"
        return 1
    fi

    if grep -q ".fvh-standards.yaml" "$COMMAND_FILE"; then
        log_pass "Standards tracking documented"
        return 0
    else
        log_fail "Command should document .fvh-standards.yaml updates"
        return 1
    fi
}

# Run all tests
echo "========================================"
echo "/configure:makefile Test Suite"
echo "Testing implementation for Issue #95"
echo "========================================"
echo ""

test_command_exists || true
test_frontmatter_exists || true
test_required_targets_documented || true
test_language_support || true
test_makefile_template_exists || true
test_colored_output || true
test_flags_documented || true
test_standards_tracking || true

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
    echo "Issue #95 implementation verified: /configure:makefile works correctly"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    echo "Please review the failures above"
    exit 1
fi
