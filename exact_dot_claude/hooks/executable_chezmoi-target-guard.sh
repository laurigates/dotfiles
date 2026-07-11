#!/usr/bin/env bash
# PreToolUse(Write|Edit) — block direct writes to chezmoi-managed ~/.claude
# targets and point at the source file instead.
#
# ~/.claude is rendered from exact_dot_claude/ in the chezmoi source repo.
# A direct edit to a target there is clobbered by the next `chezmoi apply`
# (or, for a NEW file in rules/ or skills/, silently loads forever without
# ever being captured in version control — see chezmoi-conventions.md,
# "A rule created directly in the target is never captured to source").
# This guard blocks the write and computes the exact source path to edit,
# so the correct move is one step away.
#
# Decision table (path under ~/.claude only; everything else exits 0 fast):
#   - listed in .chezmoiignore (friction-reports/, skills/notebooklm/,
#     runtime dirs, settings.local.json) ......................... allow
#   - settings.json .................. allow + drift warning (managed via
#     modify_settings.json overlay; direct target edits of unpinned keys
#     are part of the documented workflow)
#   - chezmoi-managed (source-path resolves) ..................... BLOCK,
#     print the source path + apply command
#   - unmanaged NEW file under rules/, skills/, or CLAUDE.md ..... BLOCK,
#     print the translated exact_dot_claude/ path
#   - unmanaged elsewhere (~/.claude/foo.tmp etc.) ............... allow
#
# Registered user-globally (modify_settings.json) so it fires regardless of
# the session's cwd.
set -euo pipefail

input=$(cat)

tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null || echo "")
case "$tool" in
    Write|Edit|MultiEdit|NotebookEdit) ;;
    *) exit 0 ;;
esac

path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input" 2>/dev/null || echo "")
[ -z "$path" ] && exit 0

# Normalize: expand a literal leading ~/, resolve relative paths against the
# session cwd reported in the hook input.
# shellcheck disable=SC2088 # matching a literal "~/" prefix in tool input, not expanding it
case "$path" in
    "~/"*) path="$HOME/${path#\~/}" ;;
esac
case "$path" in
    /*) ;;
    *)
        cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null || echo "")
        path="${cwd:-$PWD}/$path"
        ;;
esac

claude_dir="$HOME/.claude"
case "$path" in
    "$claude_dir"/*) ;;
    *) exit 0 ;;
esac

command -v chezmoi >/dev/null 2>&1 || exit 0

rel="${path#"$HOME"/}" # .claude/...

# settings.json: managed via a modify_ script overlay — direct target edits
# are legitimate for unpinned keys. Warn about pinned-key revert, allow.
if [ "$path" = "$claude_dir/settings.json" ]; then
    jq -nc '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "allow",
            additionalContext: "Heads-up: ~/.claude/settings.json is chezmoi-managed via a modify_ overlay (exact_dot_claude/modify_settings.json). Keys PINNED in that overlay (env, permissions, hooks, plugins, statusLine, mode flags) revert on the next chezmoi apply — edit the overlay for those. Unpinned keys pass through and this direct edit is fine."
        }
    }'
    exit 0
fi

# Intentionally unmanaged paths (.chezmoiignore) stay writable. `chezmoi
# ignored` misses patterns nested below the top level (skills/notebooklm/),
# so probe the nearest EXISTING ancestor instead: a path that is neither
# managed (source-path fails) nor reported by `chezmoi unmanaged` is ignored.
while IFS= read -r ig; do
    case "$rel" in
        "$ig" | "$ig"/*) exit 0 ;;
    esac
done < <(chezmoi ignored 2>/dev/null | grep '^\.claude' || true)

# Probe the nearest existing DIRECTORY (chezmoi unmanaged applies ignore
# patterns when walking a directory, but not to an explicit file argument).
probe="$path"
while [ ! -d "$probe" ] && [ "$probe" != "$claude_dir" ]; do
    probe=$(dirname "$probe")
done
if ! chezmoi source-path "$probe" >/dev/null 2>&1 &&
    [ -z "$(chezmoi unmanaged "$probe" 2>/dev/null)" ]; then
    exit 0 # ignored subtree (e.g. skills/notebooklm/)
fi

if src=$(chezmoi source-path "$path" 2>/dev/null); then
    cat >&2 <<EOF
BLOCKED: $path is a chezmoi-managed target — a direct edit here is
clobbered by the next 'chezmoi apply'.

Edit the chezmoi source instead:
  $src

then sync:
  chezmoi apply -v ~/.claude

Related: chezmoi-expert skill; chezmoi-conventions rule
(~/.local/share/chezmoi/.claude/rules/chezmoi-conventions.md).
EOF
    exit 2
fi

# Unmanaged and not ignored: only guard the trees where an orphan is harmful —
# rules/ and CLAUDE.md load into every session, skills/ are auto-discovered —
# yet the file would never be captured into version control.
case "$rel" in
    .claude/rules/* | .claude/skills/* | .claude/CLAUDE.md) ;;
    *) exit 0 ;;
esac

src_root=$(chezmoi source-path "$claude_dir" 2>/dev/null) || exit 0
suggested="$src_root/${rel#.claude/}"

cat >&2 <<EOF
BLOCKED: $path is inside the chezmoi-managed ~/.claude tree but not managed.
A file created directly here loads into sessions while never existing in the
dotfiles repo — invisible to version control and to other machines.

Create it in the chezmoi source instead:
  $suggested

then sync:
  chezmoi apply -v ~/.claude

If it should intentionally stay unmanaged, add it to
exact_dot_claude/.chezmoiignore with an ownership comment instead.

Related: chezmoi-expert skill; chezmoi-conventions rule
(~/.local/share/chezmoi/.claude/rules/chezmoi-conventions.md).
EOF
exit 2
