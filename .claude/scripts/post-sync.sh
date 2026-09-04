#!/usr/bin/env bash
# post-sync.sh — make a freshly pulled chezmoi source tree actually EFFECTIVE.
#
# Run by .claude/scripts/repos-sync-nudge.sh (and by ~/repos/.routines/spine-sync.sh)
# after a SUCCESSFUL fast-forward, never on its own schedule. A pulled rule that
# is never applied is not in effect: `~/.claude/rules/*` is rendered from
# `exact_dot_claude/rules/*`, so a `git pull` here changes nothing a session
# reads until `chezmoi apply` runs.
#
# Scope is deliberately `~/.claude` only — the Claude Code config spine this
# whole freshness chain exists for. Applying the rest of the dotfiles tree
# unattended is a much larger blast radius and is not what a pull of a rule file
# warrants.
#
# The pre-flight is this repo's own documented order (status → decide → apply),
# from .claude/rules/chezmoi-apply-hazards.md:
#
#   * `chezmoi status` column 1 == M  →  the TARGET was edited since chezmoi last
#     wrote it. Applying would silently overwrite that edit. Same discriminator
#     exact_dot_claude/hooks/chezmoi-drift-guard.sh uses; column 2 alone is a
#     pending SOURCE edit, which is the normal case this script exists to apply.
#   * A `D` in either column  →  a deletion is in play (an `exact_` directory
#     purging an unmanaged target, or a target already removed). Never resolve
#     that unattended.
#
# Either case: REPORT ONLY, exit 0, and let a human look. `--force` must never
# appear in this file — it only suppresses the prompt that is protecting
# target-side edits, and adds no safety. `chezmoi update` must never be used
# either: it defaults to `git pull --autostash --rebase`, which would autostash a
# working tree this script has no business touching.
set -uo pipefail

TARGET="${HOME}/.claude"

command -v chezmoi >/dev/null 2>&1 || exit 0
[ -d "$TARGET" ] || exit 0

status="$(chezmoi status "$TARGET" 2>/dev/null)" || {
    echo "post-sync: 'chezmoi status ${TARGET}' failed — skipping apply."
    exit 0
}

# Nothing pending and nothing drifted: the quiet, overwhelmingly common case.
[ -z "$status" ] && exit 0

# Column 1 is the target-vs-last-written state, column 2 the source-vs-target
# delta. Both are single characters; the path starts at column 4.
blockers="$(printf '%s\n' "$status" | awk '
    { c1 = substr($0,1,1); c2 = substr($0,2,1); p = substr($0,4) }
    c1 == "M" { printf "  %s  (target edited since chezmoi last wrote it)\n", p; next }
    c1 == "D" { printf "  %s  (target deleted since chezmoi last wrote it)\n", p; next }
    c2 == "D" { printf "  %s  (apply would DELETE this target)\n", p; next }
')"

if [ -n "$blockers" ]; then
    echo "post-sync: NOT applying — ~/.claude has local drift or a pending deletion:"
    printf '%s\n' "$blockers"
    echo "  Review with: chezmoi diff ~/.claude   Capture edits with: just capture-drift"
    exit 0
fi

pending="$(printf '%s\n' "$status" | awk 'substr($0,2,1) != " " { print substr($0,4) }')"
[ -z "$pending" ] && exit 0
count="$(printf '%s\n' "$pending" | grep -c .)"

if ! out="$(chezmoi apply "$TARGET" 2>&1)"; then
    echo "post-sync: 'chezmoi apply ${TARGET}' failed:"
    printf '%s\n' "$out"
    exit 1
fi

echo "post-sync: applied ${count} file(s) to ~/.claude (effective next session, not this one):"
printf '%s\n' "$pending" | sed 's/^/  /'

# The apply is only believable if the tree is clean afterwards — a non-force
# apply SKIPS drifted files and still exits 0, so exit status alone proves
# nothing about whether the tree synced.
left="$(chezmoi status "$TARGET" 2>/dev/null | awk 'substr($0,2,1) != " " { print substr($0,4) }')"
if [ -n "$left" ]; then
    echo "post-sync: still out of sync after apply (chezmoi skipped these):"
    printf '%s\n' "$left" | sed 's/^/  /'
fi
exit 0
