#!/usr/bin/env bash
# Regression test: `just renovate-triage` leaves archived repos out of its PR search (#538).
#
# An archived repo is read-only, so its Renovate PRs can be neither merged nor
# closed. Counted in, they inflated every number the report printed: one run
# reported 318 open PRs where 223 were actionable, and all 105 HOLD-blocked PRs
# sat in archived repos. The recipe's `gh search prs` now passes
# `--archived=false`. (`renovate-risk` keeps archived repos on purpose and files
# their dossiers under archived/, so it is not checked here.)
#
# The recipe is run, not grepped: `just` executes it against a stub `gh` that
# records each call's arguments and returns no PRs. Every `gh search prs` call
# must carry `--archived=false`. The same run against a copy of the recipe with
# the flag removed must fail, so the check is shown to be able to fail.
#
# Usage: tests/test-renovate-triage-archived.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JUST_DIR="$(dirname "$SCRIPT_DIR")/private_dot_config/just"

command -v just >/dev/null || { echo "FAIL: just is not on PATH; this test runs the recipe with it"; exit 1; }
command -v python3 >/dev/null || { echo "FAIL: python3 is not on PATH; the recipe is a python3 script"; exit 1; }
[ -f "$JUST_DIR/justfile" ] || { echo "FAIL: missing $JUST_DIR/justfile"; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Stub gh: log one line of arguments per call, answer every call with no PRs.
mkdir -p "$WORK/bin"
cat >"$WORK/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$GH_LOG"
echo '[]'
EOF
chmod +x "$WORK/bin/gh"
[ -x "$WORK/bin/gh" ] || { echo "FAIL: stub gh is not executable"; exit 1; }

# Run renovate-triage from the justfile in $1 against the stub gh.
# Print FAIL lines; exit 0 when every search excludes archived repos.
check() {
    local justfile="$1" log="$WORK/gh.log" out searches
    : >"$log"
    if ! out=$(GH_LOG="$log" PATH="$WORK/bin:$PATH" \
        just --justfile "$justfile" --working-directory "$WORK" renovate-triage 2>&1); then
        echo "FAIL: renovate-triage exited non-zero against the stub gh:"
        printf '  %s\n' "${out//$'\n'/$'\n'  }"
        return 1
    fi
    searches=$(grep -E '^search prs( |$)' "$log")
    # No search call at all means the stub was never reached (a real gh ran,
    # or the recipe changed shape), and would pass the loop below vacuously.
    if [ -z "$searches" ]; then
        echo "FAIL: renovate-triage made no \`gh search prs\` call through the stub"
        return 1
    fi
    local rc=0 line
    while IFS= read -r line; do
        case " $line " in
            *" --archived=false "*) ;;
            *) echo "FAIL: search without --archived=false: gh $line"; rc=1 ;;
        esac
    done <<<"$searches"
    return "$rc"
}

fail=0

# --- Control: the check fails when the flag is removed --------------------
# The flag is removed as the quoted argument the recipe passes to gh(); exactly
# one such argument must exist before, and none after, or the edit missed.
FLAG_ARG='"--archived=false", '
cp -R "$JUST_DIR" "$WORK/control"
before=$(grep -cF -- "$FLAG_ARG" "$WORK/control/git.just")
sed -i 's/"--archived=false", //' "$WORK/control/git.just"
after=$(grep -cF -- "$FLAG_ARG" "$WORK/control/git.just")
if [ "$before" -ne 1 ] || [ "$after" -ne 0 ]; then
    echo "FAIL: control expected one $FLAG_ARG in git.just to strip, found $before before and $after after"
    fail=1
elif check "$WORK/control/justfile" >"$WORK/control.out"; then
    echo "FAIL: control passed with --archived=false removed; the check cannot fail"
    fail=1
fi

# --- The real recipe ------------------------------------------------------
if check "$JUST_DIR/justfile"; then
    echo "PASS: every renovate-triage PR search excludes archived repos"
else
    fail=1
fi

exit "$fail"
