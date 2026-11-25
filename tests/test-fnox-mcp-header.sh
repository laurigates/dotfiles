#!/usr/bin/env bash
# Regression test for dot_local/bin/executable_fnox-mcp-header (ADR-0026).
#
# Contract:
#   OK       prints {"HEADER":"value"} as one line of valid JSON, exit 0; a value
#            with quotes and backslashes survives JSON encoding intact.
#   Missing  fnox cannot resolve the secret: exit 1, nothing on stdout.
#   Empty    fnox resolves to an empty value: exit 1, nothing on stdout.
#   Usage    wrong argument count, or an empty HEADER or SECRET: exit 2.
#
# fnox is a stub on PATH, so the real keychain is never read.
#
# Usage: tests/test-fnox-mcp-header.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$(dirname "$SCRIPT_DIR")/dot_local/bin/executable_fnox-mcp-header"

checks=0
fails=0
check() {
    local desc="$1"
    shift
    checks=$((checks + 1))
    if ! "$@"; then
        printf 'FAIL: %s\n' "$desc"
        fails=$((fails + 1))
    fi
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"

# `fnox get NAME` prints $FNOX_STUB_NAME when it is set (even empty), else fails.
cat >"$WORK/bin/fnox" <<'STUB'
#!/usr/bin/env bash
[[ "${1:-}" == get && -n "${2:-}" ]] || exit 1
var="FNOX_STUB_$2"
[[ -n "${!var+x}" ]] || { echo "stub fnox: $2 not found" >&2; exit 1; }
printf '%s\n' "${!var}"
STUB
chmod +x "$WORK/bin/fnox"
export PATH="$WORK/bin:$PATH"

check "fnox resolves to the executable stub" test "$(command -v fnox)" = "$WORK/bin/fnox"
check "fnox-mcp-header exists and is executable" test -x "$SCRIPT"

# run <name> [args...]: stdout to <name>.out, stderr to <name>.err, exit to <name>.rc
run() {
    local name="$1"
    shift
    "$SCRIPT" "$@" >"$WORK/$name.out" 2>"$WORK/$name.err"
    echo $? >"$WORK/$name.rc"
}
rc() { cat "$WORK/$1.rc"; }

TRICKY='abc"def\ghi'
FNOX_STUB_API_KEY="$TRICKY" run ok X-Goog-Api-Key API_KEY
check "ok: exit 0" test "$(rc ok)" = 0
check "ok: one line" test "$(wc -l <"$WORK/ok.out" | tr -d ' ')" = 1
check "ok: header carries the exact value" \
    test "$(jq -r '."X-Goog-Api-Key"' "$WORK/ok.out")" = "$TRICKY"
check "ok: only that header" test "$(jq -r 'keys | length' "$WORK/ok.out")" = 1

run missing X-Goog-Api-Key NOPE
check "missing: exit 1" test "$(rc missing)" = 1
check "missing: stdout empty" test ! -s "$WORK/missing.out"

FNOX_STUB_EMPTY="" run empty X-Goog-Api-Key EMPTY
check "empty: exit 1" test "$(rc empty)" = 1
check "empty: stdout empty" test ! -s "$WORK/empty.out"

run usage OnlyOneArg
check "usage: exit 2" test "$(rc usage)" = 2

FNOX_STUB_API_KEY=v run emptyheader "" API_KEY
check "empty header: exit 2" test "$(rc emptyheader)" = 2
check "empty header: stdout empty" test ! -s "$WORK/emptyheader.out"

printf '%d checks, %d failed\n' "$checks" "$fails"
[[ "$fails" -eq 0 ]]
