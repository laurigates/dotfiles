#!/usr/bin/env bash
# Regression test: entries that other programs write under ~/.claude must
# survive `chezmoi apply`.
#
# What is being protected
# ------------------------
# ~/.claude is an exact_ directory (exact_dot_claude/), so apply DELETES every
# entry that is neither in the source tree nor matched by
# exact_dot_claude/.chezmoiignore. Claude Code, Claude Desktop and other tools
# write runtime state there, and it goes missing two ways:
#   - a tool starts writing a new entry and nobody registers it (state/,
#     written by Claude Code; settings.json.bak, writer unknown);
#   - an ignore line with no recorded owner is removed as an apparent
#     oversight (scheduled-tasks/, which holds Claude Desktop's task prompts;
#     see #399).
#
# How
# ---
# Seed a scratch destination with one fixture per known entry, run
# `chezmoi status` for this source tree against it, and fail on any ` D`
# (pending deletion) line. Config, cache and persistent state are scratch
# files, so neither the real ~/.claude nor the real chezmoi state is read.
# The destination holds nothing but the fixtures, so every ` D` line names a
# fixture. A deliberately unregistered canary must be reported as ` D`; that
# proves the run could see a deletion, so a clean result is not vacuous.
#
# RUNTIME_ENTRIES is kept separate from .chezmoiignore on purpose. Deriving
# the fixtures from the ignore file would drop an entry's fixture together
# with its ignore line, and the test could never fail. When a tool starts
# writing a new entry, add it here AND register it in
# exact_dot_claude/.chezmoiignore with an owner comment.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'

# Paths relative to ~/.claude. Each is created as a file; parent directories
# are created as needed, so `dir/fixture` stands for a runtime directory.
RUNTIME_ENTRIES=(
    # Claude Desktop local scheduled tasks (#399)
    scheduled-tasks/example-task/SKILL.md
    # Claude Code
    state/mcp-discover-verdicts.json
    # Writer unknown
    settings.json.bak
    # .chezmoiignore "Runtime directories created by Claude Code"
    cache/fixture
    downloads/fixture
    file-history/fixture
    paste-cache/fixture
    plans/fixture.md
    plugins/fixture
    projects/fixture
    session-env/fixture
    shell-snapshots/fixture
    tasks/fixture
    backups/fixture
    ide/fixture
    telemetry/fixture
    usage-data/fixture
    teams/fixture
    chrome/fixture
    sessions/fixture
    .last-cleanup
    .last-update
    daemon/fixture
    daemon.lock
    daemon.log
    daemon.status.json
    gh-pr-status-cache.json
    jobs/fixture
    .last-update-result.json
    feedback/fixture
    # .chezmoiignore "Runtime files created by Claude Code"
    .credentials.json
    settings.json.backup.20260101T000000Z
    policy-limits.json
    remote-settings.json
    .update.lock
    debug/fixture
    history.jsonl
    stats-cache.json
    statsig/fixture
    todos/fixture
    mcp-needs-auth-cache.json
    settings.local.json
    # Other tools (see the owner comments in .chezmoiignore)
    friction-reports/fixture.md
    skill-usage.jsonl
    skills/notebooklm/SKILL.md
)
CANARY="runtime-ignored-test-canary"

command -v chezmoi >/dev/null 2>&1 || { echo "${RED}FAIL${NC}: chezmoi not installed"; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
dest="$tmp/home"

for entry in "${RUNTIME_ENTRIES[@]}" "$CANARY"; do
    mkdir -p "$(dirname "$dest/.claude/$entry")"
    printf 'fixture\n' > "$dest/.claude/$entry"
done
: > "$tmp/chezmoi.toml"

# --exclude=scripts,externals: no run_ scripts, no external downloads.
# exact_dot_claude/modify_settings.json still runs (it needs jq); it only
# reads stdin and writes stdout.
status_out=$(chezmoi status \
    --source="$REPO_DIR" \
    --destination="$dest" \
    --config="$tmp/chezmoi.toml" \
    --cache="$tmp/cache" \
    --persistent-state="$tmp/chezmoistate.boltdb" \
    --exclude=scripts,externals \
    "$dest/.claude" 2>"$tmp/stderr")
rc=$?
if [ "$rc" -ne 0 ]; then
    echo "${RED}FAIL${NC}: chezmoi status exited $rc"
    cat "$tmp/stderr"
    exit 1
fi

# Status column 2 compares the destination with the target state; `D` there
# means apply would delete the entry.
deletions=$(awk 'substr($0, 2, 1) == "D" { print substr($0, 4) }' <<<"$status_out")

if ! grep -qxF ".claude/$CANARY" <<<"$deletions"; then
    echo "${RED}FAIL${NC}: control: the unregistered canary .claude/$CANARY was not"
    echo "      reported as a pending deletion, so this run cannot detect one."
    echo "      chezmoi status output (first 20 lines):"
    head -20 <<<"$status_out"
    exit 1
fi

unexpected=$(grep -vxF ".claude/$CANARY" <<<"$deletions")
if [ -n "$unexpected" ]; then
    echo "${RED}FAIL${NC}: chezmoi apply would DELETE these runtime entries under ~/.claude."
    echo "      Register each in exact_dot_claude/.chezmoiignore with an owner comment:"
    while IFS= read -r path; do
        echo "        $path"
    done <<<"$unexpected"
    exit 1
fi

echo "${GREEN}PASS${NC}: ${#RUNTIME_ENTRIES[@]} runtime entries survive chezmoi apply (canary deletion detected)"
