#!/usr/bin/env bash
# Regression test: `just renovate-triage` holds platform-chart PRs and PRs whose
# only passing checks are PR-title checks, and names the checks behind SAFE (#532).
#
# One run put four Helm chart bumps for cluster-wide components (argo-cd,
# cert-manager, external-dns, ...) in SAFE and printed a merge line for each;
# a GitOps controller deploys those on merge. In another repo the only check
# was the `conventional-commits` workflow's `Fix PR title` job, which says
# nothing about the bumped dependency, and the PR still counted as tested.
#
# The recipe is run, not grepped: `just` executes it against a stub `gh` that
# serves five fixture PRs.
#   #1 cert-manager chart patch, real CI green   -> HOLD-platform, no merge line
#   #2 patch bump, only a PR-title check green   -> HOLD-nochecks, no merge line
#   #3 patch bump, real CI and title check green -> SAFE, merge line, check named
#   #4 patch bump, real CI green, title check red -> HOLD-failing, no merge line
#   #5 patch bump, real CI green, title check running -> HOLD-pending, no merge line
# A PR-title check does not count as CI, but a red or running one still holds
# the PR, as it did before #532.
# A second run passes a different `platform` regex and expects #1 and #3 to
# swap buckets, which shows the verdict follows the parameter. A third run
# passes an empty regex and expects no HOLD-platform bucket.
#
# Usage: tests/test-renovate-triage-buckets.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JUST_DIR="$(dirname "$SCRIPT_DIR")/private_dot_config/just"

command -v just >/dev/null || { echo "FAIL: just is not on PATH; this test runs the recipe with it"; exit 1; }
command -v python3 >/dev/null || { echo "FAIL: python3 is not on PATH; the recipe is a python3 script"; exit 1; }
[ -f "$JUST_DIR/justfile" ] || { echo "FAIL: missing $JUST_DIR/justfile"; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/fx"

# --- Fixtures -------------------------------------------------------------
cat >"$WORK/fx/search.json" <<'EOF'
[{"number": 1, "repository": {"nameWithOwner": "example-org/infra"}},
 {"number": 2, "repository": {"nameWithOwner": "example-org/titleonly"}},
 {"number": 3, "repository": {"nameWithOwner": "example-org/app"}},
 {"number": 4, "repository": {"nameWithOwner": "example-org/titlefail"}},
 {"number": 5, "repository": {"nameWithOwner": "example-org/titlewait"}}]
EOF

STABILITY='{"__typename": "StatusContext", "context": "renovate/stability-days", "state": "SUCCESS"}'
CI_TEST='{"__typename": "CheckRun", "name": "unit-tests", "workflowName": "CI", "status": "COMPLETED", "conclusion": "SUCCESS"}'
TITLE_CHECK='{"__typename": "CheckRun", "name": "Fix PR title", "workflowName": "conventional-commits", "status": "COMPLETED", "conclusion": "SUCCESS"}'
TITLE_FAIL='{"__typename": "CheckRun", "name": "Fix PR title", "workflowName": "conventional-commits", "status": "COMPLETED", "conclusion": "FAILURE"}'
TITLE_WAIT='{"__typename": "CheckRun", "name": "Fix PR title", "workflowName": "conventional-commits", "status": "IN_PROGRESS", "conclusion": ""}'

# pr <number> <title> <table row> <checks json array>
pr() {
    cat >"$WORK/fx/pr-$1.json" <<EOF
{"number": $1, "title": "$2", "isDraft": false, "mergeStateStatus": "CLEAN", "mergeable": "MERGEABLE",
 "body": "| Package | Update | Change |\n|---|---|---|\n| $3 |\n",
 "statusCheckRollup": $4}
EOF
}
# The table rows carry literal backticks, as Renovate writes them.
# shellcheck disable=SC2016
{
pr 1 "chore(deps): update helm release cert-manager to v1.21.2" \
    'cert-manager | patch | `v1.21.1` -> `v1.21.2`' "[$STABILITY, $CI_TEST]"
pr 2 "chore(deps): update dependency pandas to v2.3.4" \
    'pandas | patch | `2.3.3` -> `2.3.4`' "[$STABILITY, $TITLE_CHECK]"
pr 3 "chore(deps): update dependency requests to v2.32.5" \
    'requests | patch | `2.32.4` -> `2.32.5`' "[$STABILITY, $CI_TEST, $TITLE_CHECK]"
pr 4 "chore(deps): update dependency numpy to v2.3.5" \
    'numpy | patch | `2.3.4` -> `2.3.5`' "[$STABILITY, $CI_TEST, $TITLE_FAIL]"
pr 5 "chore(deps): update dependency scipy to v1.16.4" \
    'scipy | patch | `1.16.3` -> `1.16.4`' "[$STABILITY, $CI_TEST, $TITLE_WAIT]"
}

# --- Stub gh ---------------------------------------------------------------
# Logs one line of arguments per call. `search prs` returns the five PRs,
# `pr view <n>` returns that PR's fixture, anything else fails loudly.
cat >"$WORK/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$GH_LOG"
case "$1 $2" in
    "search prs") cat "$GH_FX/search.json" ;;
    "pr view") cat "$GH_FX/pr-$3.json" ;;
    *) echo "stub gh: unexpected call: $*" >&2; exit 64 ;;
esac
EOF
chmod +x "$WORK/bin/gh"
[ -x "$WORK/bin/gh" ] || { echo "FAIL: stub gh is not executable"; exit 1; }

fail=0
OUT=""

# triage [platform regex]: run the recipe against the stub; output lands in $OUT.
# With no argument the recipe's default `platform` applies.
triage() {
    local log="$WORK/gh.log" args=(example-org app/renovate 2)
    [ "$#" -gt 0 ] && args+=("$1")
    : >"$log"
    if ! OUT=$(GH_LOG="$log" GH_FX="$WORK/fx" PATH="$WORK/bin:$PATH" \
        just --justfile "$JUST_DIR/justfile" --working-directory "$WORK" renovate-triage "${args[@]}" 2>&1); then
        echo "FAIL: renovate-triage exited non-zero against the stub gh:"
        printf '  %s\n' "${OUT//$'\n'/$'\n'  }"
        return 1
    fi
    # Five `pr view` calls in the log show the stub answered, not a real gh.
    local views
    views=$(grep -cE '^pr view [1-5] ' "$log")
    if [ "$views" -ne 5 ]; then
        echo "FAIL: expected 5 \`gh pr view\` calls through the stub, logged $views"
        return 1
    fi
}

# has <description> <fixed string>: $OUT contains the string on some line.
has() {
    if grep -qF -- "$2" <<<"$OUT"; then echo "PASS: $1"; else echo "FAIL: $1 (no line contains: $2)"; fail=1; fi
}
# lacks <description> <fixed string>: no line of $OUT contains the string.
lacks() {
    if grep -qF -- "$2" <<<"$OUT"; then echo "FAIL: $1 (found: $2)"; fail=1; else echo "PASS: $1"; fi
}
# safe_line <repo#n>: the SAFE listing line for that PR, empty when absent.
safe_line() { grep -E "^#   $1  " <<<"$OUT"; }

# --- Default platform regex ------------------------------------------------
if triage; then
    has "cert-manager chart PR is HOLD-platform" "== HOLD-platform: example-org/infra(1)"
    lacks "cert-manager chart PR gets no merge line" "gh pr merge 1 -R example-org/infra"
    has "title-check-only PR is HOLD-nochecks" "== HOLD-nochecks: example-org/titleonly(1)"
    lacks "title-check-only PR gets no merge line" "gh pr merge 2 -R example-org/titleonly"
    has "plain patch PR gets a merge line" "gh pr merge 3 -R example-org/app --squash --delete-branch"
    line=$(safe_line "example-org/app#3")
    if grep -qF "unit-tests" <<<"$line"; then
        echo "PASS: SAFE listing names the passing check"
    else
        echo "FAIL: SAFE listing for example-org/app#3 does not name unit-tests: ${line:-<no line>}"; fail=1
    fi
    if grep -qF "Fix PR title" <<<"$line"; then
        echo "FAIL: SAFE listing counts the PR-title check as a passing check: $line"; fail=1
    else
        echo "PASS: SAFE listing leaves the PR-title check out"
    fi
    has "failing PR-title check is HOLD-failing" "== HOLD-failing: example-org/titlefail(1)"
    lacks "failing PR-title check gets no merge line" "gh pr merge 4 -R example-org/titlefail"
    has "running PR-title check is HOLD-pending" "== HOLD-pending: example-org/titlewait(1)"
    lacks "running PR-title check gets no merge line" "gh pr merge 5 -R example-org/titlewait"
else
    fail=1
fi

# --- A different platform regex moves the verdict ---------------------------
if triage 'requests'; then
    has "platform=requests holds the requests PR" "== HOLD-platform: example-org/app(1)"
    lacks "platform=requests: requests PR gets no merge line" "gh pr merge 3 -R example-org/app"
    has "platform=requests: cert-manager PR gets a merge line" "gh pr merge 1 -R example-org/infra --squash --delete-branch"
else
    fail=1
fi

# --- An empty platform regex switches the bucket off -------------------------
if triage ''; then
    lacks "platform='' reports no HOLD-platform bucket" "== HOLD-platform"
    has "platform='': cert-manager PR gets a merge line" "gh pr merge 1 -R example-org/infra --squash --delete-branch"
else
    fail=1
fi

exit "$fail"
