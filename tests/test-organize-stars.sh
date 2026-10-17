#!/usr/bin/env bash
# Regression test: organize-stars.sh must not report success when gh fails, and
# its counters must not abort the run (#443).
#
# Both bugs were silent under `set -euo pipefail`:
#   1. `local x=$(cmd)` takes the exit status of `local` (0), so a failed
#      `gh api user/starred` left the repo list empty. The run logged "No new
#      starred repos to process" and exited 0, and the workflow went green. The
#      same shape hid a failed state-file jq read, and the list-ID fetch ran in
#      a process substitution, which discards its exit status.
#   2. `((failed++))` and `((success++))` return status 1 while the counter is 0,
#      so the first counted star aborted the run: no summary, no state saved.
#
# Every gh call goes to a stub on PATH. The stub logs its arguments and fails
# closed: a call the test does not expect exits 97. Nothing reaches the network
# or a real account. Each scenario runs the script in its own temp directory,
# because the state file path is relative; LOG_FILE points into that directory.
#
# Checked here:
#   Static   no post-increment counter `((x++))` / `((x--))` in the script, and
#            no `local|export|readonly x=$(...)` that hides a failure (comment
#            lines are skipped). Planted lines prove each pattern matches the bad
#            shape and not the fix.
#   Fail     gh fails on every call: non-zero exit, no "No new starred repos".
#   Lists    the list-ID fetch fails: non-zero exit, and no repo is checked
#            against a list cache that never loaded.
#   NoLists  the account has no GitHub Lists (nodes: []): exit 0, each star is
#            reported as "List ... not found", and the cache loop does not
#            crash on an empty subscript.
#   State    a state file jq cannot parse: non-zero exit, no star is re-added.
#            With PROCESS_ALL=true ("ignore state") the same file is not read:
#            exit 0, the star is added, and the file is rewritten.
#   Count    one star whose list exists: exit 0, "Success: 1", state saved.
#            No state file yet: load_state's default applies, so every star is
#            processed (the tolerance that is meant to exist).
#   Mixed    one star with a list and one without: both counters run, exit 0.
#   Failed   a list add fails: the failed counter runs and the summary prints.
#   Empty    no stars: exit 0 with "No new starred repos to process".
#
# Usage: tests/test-organize-stars.sh

# SC2016: the planted lines are literal shell text, so their $ must not expand.
# shellcheck disable=SC2016
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPT="$REPO_DIR/.github/scripts/organize-stars.sh"

checks=0
fails=0

# check <desc> <cmd...>: pass when the command succeeds.
check() {
    local desc="$1"
    shift
    checks=$((checks + 1))
    if ! "$@"; then
        printf 'FAIL: %s\n' "$desc"
        fails=$((fails + 1))
    fi
}

# check_not <desc> <cmd...>: pass when the command fails.
check_not() {
    local desc="$1"
    shift
    checks=$((checks + 1))
    if "$@"; then
        printf 'FAIL: %s\n' "$desc"
        fails=$((fails + 1))
    fi
}

# no_match <desc> <regex> <file>: fail, printing the lines, when the regex
# matches a line that is not a comment.
no_match() {
    local desc="$1" re="$2" file="$3" hits
    checks=$((checks + 1))
    hits=$(grep -nE -- "$re" "$file" | grep -vE '^[0-9]+:[[:space:]]*#' || true)
    if [ -n "$hits" ]; then
        printf 'FAIL: %s\n%s\n' "$desc" "$hits"
        fails=$((fails + 1))
    fi
}

# A counter post-increment: 0++ evaluates to 0 and returns status 1.
POSTINC_RE='\(\([[:space:]]*[A-Za-z_][A-Za-z0-9_]*(\+\+|--)'
# A declaration whose command substitution hides the command's exit status.
DECL_SUBST_RE='(local|export|readonly)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*="?\$\('

# --- Controls: the patterns flag the bad shape and pass the fixed one ----------
for line in '  ((failed++))' '  ((success--))'; do
    check "control: post-increment pattern misses '$line'" grep -qE "$POSTINC_RE" <<<"$line"
done
for line in '  failed=$((failed + 1))' '  ((++failed))'; do
    check_not "control: post-increment pattern matches the safe '$line'" grep -qE "$POSTINC_RE" <<<"$line"
done
check "control: declaration pattern misses 'local last=\$(cmd)'" \
    grep -qE "$DECL_SUBST_RE" <<<'    local last=$(echo x)'
check "control: declaration pattern misses 'export A=\"\$(cmd)\"'" \
    grep -qE "$DECL_SUBST_RE" <<<'    export A="$(echo x)"'
check_not "control: declaration pattern matches the split 'local last'" \
    grep -qE "$DECL_SUBST_RE" <<<'    local last'
check_not "control: declaration pattern matches the split 'last=\$(cmd)'" \
    grep -qE "$DECL_SUBST_RE" <<<'    last=$(echo x)'

# --- Static: the script itself -----------------------------------------------
no_match "post-increment counter aborts under set -e while the counter is 0; use x=\$((x + 1))" \
    "$POSTINC_RE" "$SCRIPT"
no_match "declaration hides the exit status of its command substitution; split it into local x; x=\$(cmd)" \
    "$DECL_SUBST_RE" "$SCRIPT"

# --- Runtime: stubbed gh ------------------------------------------------------
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/fixtures"

# Stub gh. STUB_MODE picks the failure to inject. STUB_STARRED is the output of
# `gh api user/starred --paginate --jq ...`: one JSON object per line.
cat >"$WORK/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$STUB_LOG"
case "$*" in
    "api user/starred"*)
        if [ "$STUB_MODE" = fail-all ]; then
            echo "HTTP 401: Bad credentials" >&2
            exit 1
        fi
        cat "$STUB_STARRED"
        ;;
    *updateUserListsForItem*)
        if [ "$STUB_MODE" = mutation-fail ]; then
            echo "Resource not accessible by integration" >&2
            exit 1
        fi
        echo '{"data":{"updateUserListsForItem":{"item":{"nameWithOwner":"octo/x"}}}}'
        ;;
    *viewer*lists*)
        if [ "$STUB_MODE" = fail-all ] || [ "$STUB_MODE" = lists-fail ]; then
            echo "HTTP 502" >&2
            exit 1
        fi
        if [ "$STUB_MODE" = lists-empty ]; then
            echo '{"data":{"viewer":{"lists":{"nodes":[]}}}}'
            exit 0
        fi
        echo '{"data":{"viewer":{"lists":{"nodes":[{"id":"L_mcp","name":"MCP"}]}}}}'
        ;;
    *)
        echo "gh stub: unexpected call: $*" >&2
        exit 97
        ;;
esac
EOF
chmod +x "$WORK/bin/gh"

cat >"$WORK/fixtures/mcp.jsonl" <<'EOF'
{"name":"octo/mcp-server","id":"R_mcp","starred_at":"2026-10-01T00:00:00Z","language":"TypeScript","topics":"mcp,llm"}
EOF
cat >"$WORK/fixtures/both.jsonl" <<'EOF'
{"name":"octo/mcp-server","id":"R_mcp","starred_at":"2026-10-01T00:00:00Z","language":"TypeScript","topics":"mcp,llm"}
{"name":"octo/plain-tool","id":"R_plain","starred_at":"2026-10-02T00:00:00Z","language":"Go","topics":""}
EOF
: >"$WORK/fixtures/empty.jsonl"

if ! command -v jq >/dev/null 2>&1; then
    echo "FAIL: jq is required; the script parses gh output with it"
    exit 1
fi

# new_case <name>: a fresh directory with the .github/ the script writes into.
new_case() {
    CASE_DIR="$WORK/$1"
    mkdir -p "$CASE_DIR/.github"
    : >"$CASE_DIR/gh-calls.log"
}

# run_organizer <stub mode> <fixture> [process_all]: run the script in $CASE_DIR;
# RC is its exit status. process_all defaults to false, as in the workflow.
run_organizer() {
    (
        cd "$CASE_DIR" || exit 1
        PATH="$WORK/bin:$PATH" \
        LOG_FILE="$CASE_DIR/star-organizer.log" \
        PROCESS_ALL="${3:-false}" \
        STUB_MODE="$1" \
        STUB_STARRED="$WORK/fixtures/$2" \
        STUB_LOG="$CASE_DIR/gh-calls.log" \
        bash "$SCRIPT" >"$CASE_DIR/out.txt" 2>&1
    )
    RC=$?
}

out_file() { printf '%s/out.txt' "$CASE_DIR"; }
state_file() { printf '%s/.github/star-organizer-state.json' "$CASE_DIR"; }

# Fail: gh cannot reach the API. The run must stop; it must not log success.
new_case fail-all
run_organizer fail-all mcp.jsonl
check "gh failing on every call: the run must exit non-zero (got $RC)" test "$RC" -ne 0
check_not "gh failing on every call: no 'No new starred repos' success line" \
    grep -qF -- 'No new starred repos' "$(out_file)"

# Lists: the starred fetch works, the list-ID fetch fails.
new_case lists-fail
run_organizer lists-fail mcp.jsonl
check "list-ID fetch failing: the run must exit non-zero (got $RC)" test "$RC" -ne 0
check_not "list-ID fetch failing: no star is checked against an empty list cache" \
    grep -qF -- 'not found for' "$(out_file)"
check_not "list-ID fetch failing: nothing is added to a list" \
    grep -qF -- 'updateUserListsForItem' "$CASE_DIR/gh-calls.log"

# Lists, empty: an account with no GitHub Lists is not an error. The cache loop
# must not run once on an empty string: bash 5.2 rejects the empty subscript.
new_case lists-empty
run_organizer lists-empty mcp.jsonl
check "account with no lists: the run must exit 0 (got $RC)" test "$RC" -eq 0
check_not "account with no lists: no 'bad array subscript' from the list cache" \
    grep -qF -- 'bad array subscript' "$(out_file)"
check "account with no lists: the missing list is reported" \
    grep -qF -- "List 'MCP' not found for octo/mcp-server" "$(out_file)"
check "account with no lists: the summary reports Failed: 1" \
    grep -qF -- 'Failed: 1' "$(out_file)"
check_not "account with no lists: nothing is added to a list" \
    grep -qF -- 'updateUserListsForItem' "$CASE_DIR/gh-calls.log"

# State: a state file that exists but jq cannot parse must stop the run.
new_case state-corrupt
printf '{not json\n' >"$(state_file)"
run_organizer ok mcp.jsonl
check "unparseable state file: the run must exit non-zero (got $RC)" test "$RC" -ne 0
check_not "unparseable state file: no star is re-added from scratch" \
    grep -qF -- 'updateUserListsForItem' "$CASE_DIR/gh-calls.log"

# State + PROCESS_ALL: "ignore state" must not depend on the state parsing, or
# the manual escape hatch for a corrupt file is gone.
new_case state-corrupt-all
printf '{not json\n' >"$(state_file)"
run_organizer ok mcp.jsonl true
check "PROCESS_ALL with an unparseable state file: the run must exit 0 (got $RC)" test "$RC" -eq 0
check "PROCESS_ALL with an unparseable state file: logs 'ignoring state'" \
    grep -qF -- 'Processing ALL starred repos (ignoring state)' "$(out_file)"
check "PROCESS_ALL with an unparseable state file: the star is added" \
    grep -qF -- "Added octo/mcp-server to 'MCP'" "$(out_file)"
check "PROCESS_ALL with an unparseable state file: the file is rewritten" \
    grep -qF -- '"last_starred_at": "2026-10-01T00:00:00Z"' "$(state_file)"

# State + PROCESS_ALL with a valid state newer than the star: still processed.
new_case state-ignored
printf '{"last_run": null, "last_starred_at": "2026-12-31T00:00:00Z"}\n' >"$(state_file)"
run_organizer ok mcp.jsonl true
check "PROCESS_ALL with a newer state: the star is still added" \
    grep -qF -- "Added octo/mcp-server to 'MCP'" "$(out_file)"
new_case state-honoured
printf '{"last_run": null, "last_starred_at": "2026-12-31T00:00:00Z"}\n' >"$(state_file)"
run_organizer ok mcp.jsonl
check "newer state without PROCESS_ALL: the star is skipped" \
    grep -qF -- 'No new starred repos to process' "$(out_file)"

# Count: no state file yet, one star whose list exists.
new_case count
run_organizer ok mcp.jsonl
check "one star with a list: the run must exit 0 (got $RC)" test "$RC" -eq 0
check "one star with a list: the summary reports Success: 1" \
    grep -qF -- 'Success: 1' "$(out_file)"
check "one star with a list: the summary reports Failed: 0" \
    grep -qF -- 'Failed: 0' "$(out_file)"
check "one star with a list: the state file records its starred_at" \
    grep -qF -- '"last_starred_at": "2026-10-01T00:00:00Z"' "$(state_file)" 2>/dev/null

# Mixed: the first star counts as a success, the second has no list and fails.
new_case mixed
run_organizer ok both.jsonl
check "mixed stars: the run must exit 0 (got $RC)" test "$RC" -eq 0
check "mixed stars: the summary reports Total processed: 2" \
    grep -qF -- 'Total processed: 2' "$(out_file)"
check "mixed stars: the summary reports Success: 1" \
    grep -qF -- 'Success: 1' "$(out_file)"
check "mixed stars: the summary reports Failed: 1" \
    grep -qF -- 'Failed: 1' "$(out_file)"
check "mixed stars: the missing list is reported" \
    grep -qF -- "List 'Utilities' not found for octo/plain-tool" "$(out_file)"

# Failed: the list exists, the add is rejected.
new_case mutation-fail
run_organizer mutation-fail mcp.jsonl
check "rejected list add: the summary still prints (Total processed: 1)" \
    grep -qF -- 'Total processed: 1' "$(out_file)"
check "rejected list add: the summary reports Success: 0" \
    grep -qF -- 'Success: 0' "$(out_file)"
check "rejected list add: the failure is logged" \
    grep -qF -- "Failed to add octo/mcp-server to 'MCP'" "$(out_file)"

# Empty: no stars at all is the one real success case.
new_case empty
run_organizer ok empty.jsonl
check "no starred repos: the run must exit 0 (got $RC)" test "$RC" -eq 0
check "no starred repos: logs 'No new starred repos to process'" \
    grep -qF -- 'No new starred repos to process' "$(out_file)"

if [ "$fails" -eq 0 ]; then
    echo "PASS: organize-stars.sh fails on gh errors and counts without aborting ($checks checks)"
    exit 0
fi
echo "FAIL: $fails of $checks organize-stars.sh checks failed"
exit 1
