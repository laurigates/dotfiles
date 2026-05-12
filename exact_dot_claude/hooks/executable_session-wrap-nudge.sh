#!/usr/bin/env bash
# Stop hook — nudges the agent to propose /session-wrap when the user is
# signaling end-of-session AND the session is FVH-scoped.
#
# Fires at most once per session_id (state file). Conservative on all
# three axes (turn count, FVH context, wind-down phrasing) so it stays
# quiet on quick lookups and non-FVH work.

set -euo pipefail

input=$(cat)

# Hard exits — never loop or run without the data we need
stop_active=$(jq -r '.stop_hook_active // false' <<<"$input" 2>/dev/null || echo "false")
[ "$stop_active" = "true" ] && exit 0

session_id=$(jq -r '.session_id // empty' <<<"$input" 2>/dev/null || echo "")
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null || echo "")
transcript=$(jq -r '.transcript_path // empty' <<<"$input" 2>/dev/null || echo "")

[ -z "$session_id" ] && exit 0
[ -z "$transcript" ] && exit 0
[ ! -f "$transcript" ] && exit 0

# At most one nudge per session
state_dir="${HOME}/.cache/claude-session-wrap-nudge"
mkdir -p "$state_dir"
state_file="$state_dir/$session_id"
[ -f "$state_file" ] && exit 0

# Need substantial conversation — short sessions don't warrant a wrap
user_turns=$(grep -c '"role":"user"' "$transcript" 2>/dev/null || echo 0)
[ "$user_turns" -lt 6 ] && exit 0

# FVH context detection: cwd path, git remote, or active taskwarrior project
fvh=0
case "$cwd" in
    *ForumVirium*|*forumvirium*|*ForumViriumHelsinki*) fvh=1 ;;
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

# Wind-down signal in the last 3 user messages. Recent messages are at the
# end of the transcript, so tail is enough — no need for tac/portability hacks.
recent=$(grep '"role":"user"' "$transcript" 2>/dev/null | tail -3 || true)
if ! echo "$recent" | grep -Eiq '\b(wrap up|wrap this|wrap the session|done for (today|now|the day)|calling it|good night|signing off|end of day|gotta go|heading out|i.?m done|thats it for|that.?s it for)\b'; then
    exit 0
fi

# Mark and emit. `decision: block` injects the reason as continued context
# so the agent will produce one more response — a /session-wrap suggestion.
touch "$state_file"

reason="The user is wrapping up an FVH-scoped session. Before letting the session end, briefly offer to run /session-wrap — it captures loose threads (PRs awaiting review, decisions deferred, manual follow-ups) to taskwarrior plus the FVH Obsidian daily note. Apply the skill's signal filter aggressively: if nothing follow-up-worthy actually surfaced, just acknowledge the wrap and end. Do not run /session-wrap without user confirmation."

jq -nc --arg r "$reason" '{decision: "block", reason: $r}'
