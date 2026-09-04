#!/usr/bin/env bash
# PreToolUse(Bash) — WARN (never block) when a bare `chezmoi apply|diff|status`
# runs from inside a Claude Code worktree, where it will silently operate on the
# MAIN checkout's content instead of the edits in front of you.
#
# Why this is invisible without a guard: chezmoi's source directory is pinned in
# ~/.config/chezmoi/chezmoi.toml, and NOTHING in the environment overrides it —
# CHEZMOI_SOURCE_DIR and CHEZMOI_SOURCE are both ignored (verified 2026-09);
# only the --source flag takes effect. So a worktree under
# <sourceDir>/.claude/worktrees/<name> is invisible to chezmoi: `chezmoi apply`
# there exits 0, reports a normal diff, and applies main's version of every file
# you just changed. There is no error and no empty result to notice.
#
# Warn, don't block: operating on main's content is occasionally what you want
# (checking what the applied state currently is), and the repo's justfile and
# mise tasks already pass --source for you. Same posture and command-position
# regex as chezmoi-drift-guard.sh, which is the sibling guard for the *other*
# silent-overwrite failure (apply clobbering un-captured target edits).
#
# Registered user-globally (modify_settings.json) so it fires regardless of cwd.
set -euo pipefail

input=$(cat)

tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null || echo "")
[ "$tool" = "Bash" ] || exit 0

cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null || echo "")
[ -z "$cmd" ] && exit 0

# Already explicit about its source tree — nothing to warn about.
case "$cmd" in
    *--source*) exit 0 ;;
esac

# Only fire when the session is actually standing in a Claude Code worktree.
# `cwd` is the session's directory; a command that cd's elsewhere itself is out
# of scope (and would have to name that path, which a reader can see).
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null || echo "")
case "$cwd" in
    */.claude/worktrees/*) ;;
    *) exit 0 ;;
esac

# `chezmoi` must start a command (line start, after ;|&&, inside $( ), or after
# a shell-wrapper prefix itself at a command position), and the subcommand must
# follow within the same segment. A bare substring match also fires on commit
# messages and PR bodies that merely MENTION "chezmoi apply" — the false
# positive chezmoi-drift-guard.sh was fixed for in 2026-07. Backtick is
# deliberately not an anchor: markdown inline code in a message body would
# false-positive.
printf '%s\n' "$cmd" | grep -qE '(^|[;&|]|[$][(]|(^|[;&|(])[[:space:]]*(bash|sh|zsh|eval)[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*["'"'"'])[[:space:]]*(command[[:space:]]+)?chezmoi[[:space:]][^;&|]*\b(apply|diff|status)\b' || exit 0

msg="Heads-up: this 'chezmoi' command runs from a Claude Code worktree (${cwd}), but chezmoi's source dir is PINNED in ~/.config/chezmoi/chezmoi.toml and no environment variable overrides it — so without --source it will operate on the MAIN checkout's content, silently ignoring the edits in this worktree. It will still exit 0. Either use the repo's recipes ('just apply' / 'just diff' / 'just status', or 'mise run apply'), which pass --source for you, or add: --source \"\$(git rev-parse --show-toplevel)\". If you meant to inspect main's applied state, proceed."

jq -nc --arg c "$msg" '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        additionalContext: $c
    }
}'
exit 0
