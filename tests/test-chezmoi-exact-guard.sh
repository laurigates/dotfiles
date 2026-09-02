#!/usr/bin/env bash
# Regression test for exact_dot_claude/hooks/executable_chezmoi-exact-guard.sh's
# wrapper-invocation detection.
#
# What is being protected
# ------------------------
# The hook's fast-bail check strips quoted string literals before matching
# `chezmoi ... apply`, so that a `gh pr create --body "... chezmoi apply ..."`
# call (prose, not an invocation) doesn't false-positive. Before this fix,
# that same strip also hid a REAL invocation wrapped in a shell: a command
# like `bash -c "chezmoi apply --force ~/.claude"` had its whole quoted
# argument discarded, so the guard never saw the apply and a deleting apply
# ran unblocked. This test pins: (1) the wrapped form still gets BLOCKED
# (exit 2) when a deletion is pending, and (2) the prose case that motivated
# the quote-strip in the first place still passes (exit 0).
#
# Isolation: a stub `chezmoi` is put first on PATH so `chezmoi status`
# reports a deterministic pending deletion — no real chezmoi state is read.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HOOK="$REPO_DIR/exact_dot_claude/hooks/executable_chezmoi-exact-guard.sh"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
pass_count=0; fail_count=0

command -v jq >/dev/null 2>&1 || { echo "SKIP: jq not installed"; exit 0; }
# The chezmoi source tree encodes the executable bit in the `executable_`
# filename prefix, not necessarily in the on-disk mode, so only require the
# file to exist — it is run via `bash "$HOOK"` below, not executed directly.
[ -f "$HOOK" ] || { echo "FAIL: hook not found: $HOOK"; exit 1; }

STUB_DIR=$(mktemp -d)
trap 'rm -rf "$STUB_DIR"' EXIT

cat > "$STUB_DIR/chezmoi" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "status" ]; then
    echo " D .claude/rules/orphaned.md"
fi
exit 0
EOF
chmod +x "$STUB_DIR/chezmoi"

run_hook() {
    local cmd="$1"
    jq -n --arg cmd "$cmd" '{tool_name:"Bash", tool_input:{command:$cmd}}' \
        | PATH="$STUB_DIR:$PATH" bash "$HOOK" >/tmp/exact-guard-test-out.$$ 2>&1
    echo $?
    rm -f /tmp/exact-guard-test-out.$$
}

check() {
    local desc="$1" cmd="$2" expected="$3"
    local actual
    actual=$(run_hook "$cmd")
    if [ "$actual" = "$expected" ]; then
        echo "${GREEN}PASS${NC}: $desc (exit $actual)"
        pass_count=$((pass_count + 1))
    else
        echo "${RED}FAIL${NC}: $desc — expected exit $expected, got $actual"
        fail_count=$((fail_count + 1))
    fi
}

check "wrapped apply (bash -c \"...\") with a pending deletion is BLOCKED" \
    'bash -c "chezmoi apply --force ~/.claude"' 2

check "wrapped apply (sh -c '...') with a pending deletion is BLOCKED" \
    "sh -c 'chezmoi apply --force ~/.claude'" 2

check "prose mentioning chezmoi apply inside a PR body is NOT blocked" \
    'gh pr create --body "See chezmoi apply docs for details"' 0

check "plain unwrapped apply with a pending deletion still BLOCKED (regression)" \
    'chezmoi apply --force' 2

echo ""
echo "Passed: $pass_count, Failed: $fail_count"
[ "$fail_count" -eq 0 ]
