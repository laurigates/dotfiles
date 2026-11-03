#!/usr/bin/env bash
# Regression test for .claude/scripts/post-sync.sh's deletion handling.
#
# What is being protected
# ------------------------
# post-sync.sh applies ~/.claude unattended after a pull, and reports instead
# of applying whenever something could lose data. A ` D` line for a file
# chezmoi wrote and nobody edited since (a rule retired from source) is not
# such a case: it is applied like any other source change. The decision is
# shared with chezmoi-exact-guard.sh via hooks/chezmoi-deletion-check.sh.
# Pinned: retired-clean is applied; a stray, an `MD` line and a failing
# `chezmoi state get` are reported and not applied.
#
# Isolation: a stub `chezmoi` is put first on PATH and HOME points at a temp
# dir; the stub records whether `apply` ran instead of applying anything.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPT="${SCRIPT:-$REPO_DIR/.claude/scripts/post-sync.sh}"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
pass_count=0; fail_count=0

command -v jq >/dev/null 2>&1 || { echo "SKIP: jq not installed"; exit 0; }
[ -f "$SCRIPT" ] || { echo "FAIL: script not found: $SCRIPT"; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
STUB_DIR="$WORK/bin"
FAKE_HOME="$WORK/home"
mkdir -p "$STUB_DIR" "$FAKE_HOME/.claude/rules" "$WORK/state"

# Stub: `status` prints $STUB_STATUS until `apply` has run, then nothing;
# `state get` behaves as in test-chezmoi-exact-guard.sh.
cat >"$STUB_DIR/chezmoi" <<EOF
#!/usr/bin/env bash
case "\$1" in
    status) [ -f "$WORK/applied" ] || printf '%s\n' "\$STUB_STATUS" ;;
    apply) touch "$WORK/applied" ;;
    state)
        [ "\${STUB_STATE_FAIL:-0}" = 1 ] && exit 1
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

printf 'retired rule\n' >"$FAKE_HOME/.claude/rules/retired.md"
jq -n --arg h "$(sha256_of "$FAKE_HOME/.claude/rules/retired.md")" \
    '{type:"file", mode:420, contentsSHA256:$h}' >"$WORK/state/retired.md"
printf 'stray\n' >"$FAKE_HOME/.claude/rules/stray.md"

# check <desc> <status> <applied: yes|no>
check() {
    local desc="$1" status="$2" want="$3" got=no
    rm -f "$WORK/applied"
    STUB_STATUS="$status" HOME="$FAKE_HOME" PATH="$STUB_DIR:$PATH" bash "$SCRIPT" >"$WORK/out" 2>&1
    [ -f "$WORK/applied" ] && got=yes
    if [ "$got" = "$want" ]; then
        echo "${GREEN}PASS${NC}: $desc (applied: $got)"
        pass_count=$((pass_count + 1))
    else
        echo "${RED}FAIL${NC}: $desc — expected applied: $want, got $got"
        sed 's/^/    /' "$WORK/out"
        fail_count=$((fail_count + 1))
    fi
}

check "retired-clean ' D' is applied" " D .claude/rules/retired.md" yes
check "a source edit alongside a retired-clean ' D' is applied" \
    " M .claude/rules/other.md
 D .claude/rules/retired.md" yes
check "stray ' D' is reported, not applied" " D .claude/rules/stray.md" no
check "'MD' is reported, not applied" "MD .claude/rules/retired.md" no
export STUB_STATE_FAIL=1
check "'chezmoi state get' failure is reported, not applied" " D .claude/rules/retired.md" no
unset STUB_STATE_FAIL

echo ""
echo "Passed: $pass_count, Failed: $fail_count"
[ "$fail_count" -eq 0 ]
