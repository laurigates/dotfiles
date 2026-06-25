#!/usr/bin/env bash
# PreToolUse(Bash) — WARN (never block) when `chezmoi apply` would overwrite
# local target edits that have not yet been captured into the source.
#
# `chezmoi apply` renders source → target, silently clobbering any edits made
# directly to a target file. That is the exact data-loss this repo's
# capture-drift workflow exists to prevent. Unlike apply-time DELETIONS
# (handled by chezmoi-exact-guard.sh, which BLOCKS), overwriting target edits
# is *often intentional* — so this guard only warns and lets the apply proceed,
# surfacing the drift + the capture command via additionalContext.
#
# Detection: `chezmoi status` FIRST column == M, i.e. the target was modified
# since chezmoi last wrote it (genuine local drift). This deliberately does NOT
# use `chezmoi re-add --dry-run` / the status SECOND column, which flag any
# source≠target delta and so fire on the normal "edit source, then apply" flow —
# crying wolf on every apply that follows a source edit (chezmoi issue #4180's
# ambiguity). Column 1 isolates real target drift. `just capture-drift` lists
# specifics incl. templated sources (which need `chezmoi merge`, not re-add).
# See rules/chezmoi-conventions.md ("re-add Skips Templates").
#
# Registered user-globally (modify_settings.json) so it fires regardless of cwd.
set -euo pipefail

input=$(cat)

tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null || echo "")
[ "$tool" = "Bash" ] || exit 0

cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null || echo "")
[ -z "$cmd" ] && exit 0

# Only inspect `chezmoi ... apply` invocations.
case "$cmd" in
    *chezmoi*apply*) ;;
    *) exit 0 ;;
esac

# Dry runs and verbose previews write nothing — no drift to lose.
case "$cmd" in
    *--dry-run*|*" -n "*) exit 0 ;;
esac

command -v chezmoi >/dev/null 2>&1 || exit 0

# Count targets modified since chezmoi last wrote them (status col1 == M).
pending=$(chezmoi status 2>/dev/null | awk 'substr($0,1,1)=="M"' | grep -c . || true)
pending=${pending:-0}
[ "$pending" -eq 0 ] && exit 0

msg="Heads-up: ${pending} chezmoi target file(s) have local edits made since chezmoi last wrote them, which this 'chezmoi apply' will OVERWRITE. If those edits are wanted, capture them first: 'just capture-drift' (preview) then 'just capture-drift-apply'. Templated sources also need 'chezmoi merge'. If the overwrite is intended, proceed."

jq -nc --arg c "$msg" '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        additionalContext: $c
    }
}'
exit 0
