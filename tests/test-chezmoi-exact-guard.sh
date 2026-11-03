#!/usr/bin/env bash
# Regression test for exact_dot_claude/hooks/executable_chezmoi-exact-guard.sh.
#
# What is being protected
# ------------------------
# 1. Wrapper-invocation detection. The hook's fast-bail check strips quoted
#    string literals before matching `chezmoi ... apply`, so that a
#    `gh pr create --body "... chezmoi apply ..."` call (prose, not an
#    invocation) doesn't false-positive. That same strip once hid a REAL
#    invocation wrapped in a shell (`bash -c "chezmoi apply --force ~/.claude"`),
#    so a deleting apply ran unblocked. Pinned: the wrapped form is BLOCKED
#    (exit 2) when a deletion is pending, and the prose case passes (exit 0).
# 2. Retired-clean deletions. A ` D` line for a file chezmoi wrote (entryState
#    record of type file) whose content still matches the recorded
#    contentsSHA256 is a rule retired from source that nobody edited since:
#    the apply goes through. A stray (no record), an `MD` line (target edited
#    since chezmoi wrote it), a hash mismatch, and a failing `chezmoi state get`
#    all stay BLOCKED. The decision lives in hooks/chezmoi-deletion-check.sh.
#
# Isolation: a stub `chezmoi` is put first on PATH and HOME points at a temp
# dir, so no real chezmoi state or home file is read.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HOOK="${HOOK:-$REPO_DIR/exact_dot_claude/hooks/executable_chezmoi-exact-guard.sh}"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
pass_count=0; fail_count=0

command -v jq >/dev/null 2>&1 || { echo "SKIP: jq not installed"; exit 0; }
# The chezmoi source tree encodes the executable bit in the `executable_`
# filename prefix, not necessarily in the on-disk mode, so only require the
# file to exist — it is run via `bash "$HOOK"` below, not executed directly.
[ -f "$HOOK" ] || { echo "FAIL: hook not found: $HOOK"; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
STUB_DIR="$WORK/bin"
FAKE_HOME="$WORK/home"
mkdir -p "$STUB_DIR" "$FAKE_HOME/.claude/rules" "$WORK/state"

# Stub: `status` prints $STUB_STATUS (default: one stray deletion);
# `state get --key=<path>` prints $WORK/state/<basename> if present, nothing
# otherwise (what real chezmoi does for a never-written path), and fails when
# STUB_STATE_FAIL=1.
cat >"$STUB_DIR/chezmoi" <<EOF
#!/usr/bin/env bash
case "\$1" in
    status) printf '%s\n' "\${STUB_STATUS- D .claude/rules/orphaned.md}" ;;
    state)
        [ "\${STUB_STATE_FAIL:-0}" = 1 ] && { echo "stub: state get failed" >&2; exit 1; }
        for a in "\$@"; do
            case "\$a" in --key=*) k="\${a#--key=}" ;; esac
        done
        f="$WORK/state/\$(basename "\$k")"
        [ -f "\$f" ] && cat "\$f"
        ;;
esac
exit 0
EOF
chmod +x "$STUB_DIR/chezmoi"
PATH="$STUB_DIR:$PATH" command -v chezmoi | grep -q "^$STUB_DIR/" ||
    { echo "FAIL: chezmoi stub is not first on PATH"; exit 1; }

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum <"$1"; else shasum -a 256 <"$1"; fi | awk '{print $1}'
}

# A rule chezmoi wrote and nobody touched since: record matches content.
printf 'retired rule\n' >"$FAKE_HOME/.claude/rules/retired.md"
jq -n --arg h "$(sha256_of "$FAKE_HOME/.claude/rules/retired.md")" \
    '{type:"file", mode:420, contentsSHA256:$h}' >"$WORK/state/retired.md"
# A rule chezmoi wrote, edited afterwards: record no longer matches content.
printf 'edited rule\n' >"$FAKE_HOME/.claude/rules/edited.md"
jq -n '{type:"file", mode:420, contentsSHA256:"0000000000000000000000000000000000000000000000000000000000000000"}' \
    >"$WORK/state/edited.md"
# A stray chezmoi never wrote: no state record.
printf 'stray\n' >"$FAKE_HOME/.claude/rules/stray.md"

run_hook() {
    local cmd="$1"
    jq -n --arg cmd "$cmd" '{tool_name:"Bash", tool_input:{command:$cmd}}' |
        HOME="$FAKE_HOME" PATH="$STUB_DIR:$PATH" bash "$HOOK" >"$WORK/out" 2>&1
    echo $?
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
        sed 's/^/    /' "$WORK/out"
        fail_count=$((fail_count + 1))
    fi
}

# --- 1. wrapper detection (default stub status: a stray deletion) ---------
check "wrapped apply (bash -c \"...\") with a pending deletion is BLOCKED" \
    'bash -c "chezmoi apply --force ~/.claude"' 2

check "wrapped apply (sh -c '...') with a pending deletion is BLOCKED" \
    "sh -c 'chezmoi apply --force ~/.claude'" 2

check "prose mentioning chezmoi apply inside a PR body is NOT blocked" \
    'gh pr create --body "See chezmoi apply docs for details"' 0

check "plain unwrapped apply with a pending deletion still BLOCKED (regression)" \
    'chezmoi apply --force' 2

# --- 2. retired-clean vs blocking deletions --------------------------------
export STUB_STATUS=" D .claude/rules/retired.md"
check "retired-clean ' D' (chezmoi wrote it, content unchanged) is ALLOWED" \
    'chezmoi apply ~/.claude' 0

export STUB_STATUS=" D .claude/rules/stray.md"
check "stray ' D' (no entryState record) is BLOCKED" \
    'chezmoi apply ~/.claude' 2

export STUB_STATUS="MD .claude/rules/retired.md"
check "'MD' (target edited since chezmoi wrote it) is BLOCKED even with a matching record" \
    'chezmoi apply ~/.claude' 2

export STUB_STATUS=" D .claude/rules/edited.md"
check "' D' whose content no longer matches the recorded hash is BLOCKED" \
    'chezmoi apply ~/.claude' 2

export STUB_STATUS=" D .claude/rules/retired.md
 D .claude/rules/stray.md"
check "retired-clean plus a stray in one apply is BLOCKED" \
    'chezmoi apply ~/.claude' 2

export STUB_STATUS=" D .claude/rules/retired.md" STUB_STATE_FAIL=1
check "'chezmoi state get' failure fails closed (BLOCKED)" \
    'chezmoi apply ~/.claude' 2
unset STUB_STATE_FAIL STUB_STATUS

echo ""
echo "Passed: $pass_count, Failed: $fail_count"
[ "$fail_count" -eq 0 ]
