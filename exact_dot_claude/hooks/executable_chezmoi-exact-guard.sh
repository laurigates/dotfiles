#!/usr/bin/env bash
# PreToolUse(Bash) — block `chezmoi apply` when it would DELETE target files.
#
# exact_ source dirs (exact_dot_claude/ → ~/.claude/) remove every target
# entry that is in neither the source nor a .chezmoiignore, and --force makes
# the removal silent. Path-scoped `chezmoi diff <target>` does NOT surface
# pending deletions; only `chezmoi status` D-lines do. This guard runs that
# status check so an apply can never silently delete unmanaged files.
# Incident reference: ~/.local/share/chezmoi/.claude/rules/chezmoi-conventions.md
# ("exact_ Dirs DELETE Unmanaged Files").
#
# Registered user-globally (modify_settings.json) so it fires regardless of
# the session's cwd — applies are often run far from the dotfiles repo.
set -euo pipefail

input=$(cat)

tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null || echo "")
[ "$tool" = "Bash" ] || exit 0

cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null || echo "")
[ -z "$cmd" ] && exit 0

# Fast bail: only inspect commands that actually INVOKE `chezmoi ... apply`.
# Strip quoted string literals first, so the words `chezmoi`/`apply` appearing
# inside an argument or heredoc body (e.g. a `gh pr create --body` that
# documents a chezmoi command) don't trip the guard — a real invocation is
# never wrapped in quotes. Then require `chezmoi` at a command position with
# `apply` as its own following token, so prose like "run chezmoi apply, then…"
# (trailing punctuation, no shell boundary) is ignored too.
code=$(sed -e "s/'[^']*'//g" -e 's/"[^"]*"//g' <<<"$cmd")
grep -Eq '(^|[[:space:];&|(])chezmoi[[:space:]]([^|;&]*[[:space:]])?apply([[:space:]]|[;&|)]|$)' <<<"$code" || exit 0

# Dry runs and verbose previews are safe
case "$cmd" in
    *--dry-run*|*" -n "*) exit 0 ;;
esac

command -v chezmoi >/dev/null 2>&1 || exit 0

# Pending deletions: `chezmoi status` lines whose second column is D.
# Paths are reported relative to ~. Keep paths bare here; indent at print time.
deletions=$(chezmoi status 2>/dev/null | awk '$1 == "D" || substr($0,2,1) == "D" { print "~/" $NF }' || true)
[ -z "$deletions" ] && exit 0

# If the apply is path-scoped, only block when a pending deletion falls
# under one of the given paths. Extract non-flag args after `apply`.
scoped_paths=$(awk '{
    seen=0
    for (i=1; i<=NF; i++) {
        if ($i == "apply") { seen=1; continue }
        if (seen && $i !~ /^-/) print $i
    }
}' <<<"$cmd")

if [ -n "$scoped_paths" ]; then
    relevant=""
    while IFS= read -r del; do
        del_abs="${del/#\~/$HOME}"
        while IFS= read -r p; do
            p_abs="${p/#\~/$HOME}"
            case "$del_abs" in
                "$p_abs"|"$p_abs"/*) relevant+="$del"$'\n' ;;
            esac
        done <<<"$scoped_paths"
    done <<<"$deletions"
    deletions="${relevant%$'\n'}"
    [ -z "$deletions" ] && exit 0
fi

cat >&2 <<EOF
BLOCKED: this 'chezmoi apply' would DELETE the following target file(s)
(unmanaged entries inside an exact_-managed tree are removed on apply,
silently under --force):

$(sed 's/^/  /' <<<"$deletions")

Before re-running, register or resolve each one:
  - keep + manage:     chezmoi add <target>
  - keep, unmanaged:   add a commented entry to the exact_ dir's .chezmoiignore
  - deletion intended: rm the target file yourself, then apply

See ~/.local/share/chezmoi/.claude/rules/chezmoi-conventions.md ("exact_ Dirs
DELETE Unmanaged Files") for the full guard rationale.
EOF
exit 2
