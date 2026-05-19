#!/usr/bin/env bash
# SessionStart hook — nudges the agent to propose /session-spinup when the
# user is starting/resuming an FVH-scoped session AND there is at least one
# loose thread waiting (taskwarrior, daily-note Todos, or git state).
#
# Fires at most once per session_id (state file). Silent on compact/clear —
# those are mid-session continuations where the user already has context.

set -euo pipefail

input=$(cat)

session_id=$(jq -r '.session_id // empty' <<<"$input" 2>/dev/null || echo "")
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null || echo "")
source=$(jq -r '.source // empty' <<<"$input" 2>/dev/null || echo "")

[ -z "$session_id" ] && exit 0

# Only nudge on fresh entry — compact/clear preserve in-memory context
case "$source" in
    startup|resume) ;;
    *) exit 0 ;;
esac

# At most one nudge per session
state_dir="${HOME}/.cache/claude-session-spinup-nudge"
mkdir -p "$state_dir"
state_file="$state_dir/$session_id"
[ -f "$state_file" ] && exit 0

# FVH context detection: cwd path, git remote, or active taskwarrior project
fvh=0
case "$cwd" in
    *ForumVirium*|*forumvirium*) fvh=1 ;;
esac

if [ "$fvh" = 0 ] && [ -d "$cwd" ]; then
    remote=$(git -C "$cwd" config --get remote.origin.url 2>/dev/null || true)
    case "$remote" in
        *ForumVirium*|*forumvirium*) fvh=1 ;;
    esac
fi

if [ "$fvh" = 0 ] && command -v task >/dev/null 2>&1; then
    if task +ACTIVE export 2>/dev/null \
        | jq -e '[.[].project // ""] | map(test("^(fvh|infrastructure)")) | any' \
            >/dev/null 2>&1; then
        fvh=1
    fi
fi

[ "$fvh" = 0 ] && exit 0

# "Something to surface" gate — at least one of these must be non-empty.
# The hook only signals presence; the skill enumerates the items.
has_threads=0

# 1. Pending or +ACTIVE taskwarrior tasks under an FVH-ish project.
#    Uses `export | jq` (exit 0 on empty) per parallel-safe-queries rule.
if command -v task >/dev/null 2>&1; then
    pending_count=$(task '(status:pending or +ACTIVE)' export 2>/dev/null \
        | jq -r '[.[] | select((.project // "") | test("^(fvh|infrastructure)"))] | length' \
        2>/dev/null || echo 0)
    if [ "${pending_count:-0}" -gt 0 ]; then
        has_threads=1
    fi
fi

# 2. Unchecked Todos in the most recent FVH daily note (last 7 days).
if [ "$has_threads" = 0 ]; then
    notes_dir="${HOME}/Documents/LakuVault/FVH/notes"
    if [ -d "$notes_dir" ]; then
        for offset in 0 1 2 3 4 5 6 7; do
            day=$(date -v-"${offset}"d +%Y-%m-%d 2>/dev/null || date -d "-${offset} day" +%Y-%m-%d 2>/dev/null || echo "")
            [ -z "$day" ] && continue
            note="$notes_dir/$day.md"
            [ -f "$note" ] || continue
            # Extract the ## Todo section (stop at next ## or ### Recurring reminders).
            todo_lines=$(awk '
                /^## Todo[[:space:]]*$/ { in_todo = 1; next }
                in_todo && /^### Recurring reminders/ { in_todo = 0 }
                in_todo && /^## / { in_todo = 0 }
                in_todo { print }
            ' "$note" 2>/dev/null | grep -c '^- \[ \]' 2>/dev/null || echo 0)
            if [ "${todo_lines:-0}" -gt 0 ]; then
                has_threads=1
                break
            fi
        done
    fi
fi

# 3. Git state — uncommitted changes or unpushed commits on the current branch.
if [ "$has_threads" = 0 ] && [ -d "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    dirty=$(git -C "$cwd" status --porcelain 2>/dev/null | head -n1 || true)
    if [ -n "$dirty" ]; then
        has_threads=1
    else
        unpushed=$(git -C "$cwd" log '@{u}..HEAD' --oneline 2>/dev/null | head -n1 || true)
        if [ -n "$unpushed" ]; then
            has_threads=1
        fi
    fi
fi

[ "$has_threads" = 0 ] && exit 0

# Mark and emit. `decision: block` injects the reason as continued context
# so the agent's first response will offer /session-spinup.
touch "$state_file"

reason="The user is opening an FVH-scoped session and there is at least one open thread to surface (taskwarrior queue, an unchecked Todo from a recent FVH daily note, uncommitted changes, or unpushed commits). Briefly offer to run /session-spinup — it is read-only and surfaces the project's open threads (taskwarrior, FVH daily-note Todos, current git state, open PRs) before the user dives in. Offer the skill; do not run it without user confirmation."

jq -nc --arg r "$reason" '{decision: "block", reason: $r}'
