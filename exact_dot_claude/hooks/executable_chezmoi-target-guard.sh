#!/usr/bin/env bash
# PreToolUse(Write|Edit|MultiEdit|NotebookEdit|Bash) — block direct writes to
# chezmoi-managed ~/.claude targets and point at the source file instead.
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
#     print the source path to create
#   - unmanaged elsewhere (~/.claude/foo.tmp etc.) ............... allow
#
# Bash: the same table, applied to the DESTINATIONS of shell writes (>, >>,
# tee, cp, mv, install, ln, sed -i, rm) that land in rules/, skills/ or
# CLAUDE.md. Read-only commands name no destination and pass. rm of an
# unmanaged file passes: that is how a stray is removed. Heredoc bodies and
# quoted strings containing whitespace are prose, not paths, and are not
# scanned; a write wrapped in `bash -c "..."` is therefore not seen.
#
# Opt out: CLAUDE_HOOKS_DISABLE_CHEZMOI_TARGET_GUARD=1.
#
# Registered user-globally (modify_settings.json) so it fires regardless of
# the session's cwd.
set -euo pipefail

[ "${CLAUDE_HOOKS_DISABLE_CHEZMOI_TARGET_GUARD:-}" = "1" ] && exit 0

input=$(cat)

tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null || echo "")
case "$tool" in
    Write | Edit | MultiEdit | NotebookEdit | Bash) ;;
    *) exit 0 ;;
esac

cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null || echo "")
claude_dir="$HOME/.claude"

# normalize <path> — expand a leading ~/, $HOME/ or ${HOME}/, and resolve a
# relative path against the session cwd reported in the hook input.
normalize() {
    local p="$1"
    # shellcheck disable=SC2088,SC2016 # matching literal "~/" and "$HOME" text in tool input
    case "$p" in
        "~") p="$HOME" ;;
        "~/"*) p="$HOME/${p#\~/}" ;;
        '$HOME') p="$HOME" ;;
        '$HOME/'*) p="$HOME/${p#\$HOME/}" ;;
        '${HOME}') p="$HOME" ;;
        '${HOME}/'*) p="$HOME/${p#\$\{HOME\}/}" ;;
    esac
    case "$p" in
        /*) ;;
        *) p="${cwd:-$PWD}/$p" ;;
    esac
    [ "$p" = "/" ] || p="${p%/}"
    printf '%s\n' "$p"
}

# is_ignored <abs-path> — exit 0 when .chezmoiignore covers the path.
is_ignored() {
    local path="$1" rel="${1#"$HOME"/}" ig probe
    while IFS= read -r ig; do
        case "$rel" in
            "$ig" | "$ig"/*) return 0 ;;
        esac
    done < <(chezmoi ignored 2>/dev/null | grep '^\.claude' || true)
    # `chezmoi ignored` misses patterns nested below the top level
    # (skills/notebooklm/), so probe the nearest EXISTING directory as well
    # (chezmoi unmanaged applies ignore patterns when walking a directory, not
    # to an explicit file argument): one that is neither managed (source-path
    # fails) nor reported by `chezmoi unmanaged` is ignored.
    probe="$path"
    while [ ! -d "$probe" ] && [ "$probe" != "$claude_dir" ]; do
        probe=$(dirname "$probe")
    done
    if ! chezmoi source-path "$probe" >/dev/null 2>&1 &&
        [ -z "$(chezmoi unmanaged "$probe" 2>/dev/null)" ]; then
        return 0
    fi
    return 1
}

# suggest_source <abs-path> — source path for a target chezmoi does not manage
# yet: the nearest managed ancestor's source path plus the remainder, so a
# prefixed directory (exact_rules/) is spelled the way chezmoi spells it.
suggest_source() {
    local anc="$1" rest="" src
    while [ "$anc" != "$claude_dir" ] && [ "$anc" != "/" ]; do
        rest="/$(basename "$anc")$rest"
        anc=$(dirname "$anc")
        if src=$(chezmoi source-path "$anc" 2>/dev/null); then
            printf '%s%s\n' "$src" "$rest"
            return 0
        fi
    done
    return 1
}

# check_path <abs-path> <verb> — return 0 to allow, or print the block message
# and exit 2. <verb> is "write" for file tools, or the shell verb for Bash.
check_path() {
    local path="$1" verb="$2" rel src suggested
    rel="${path#"$HOME"/}" # .claude/...

    is_ignored "$path" && return 0

    if src=$(chezmoi source-path "$path" 2>/dev/null); then
        if [ "$verb" = "rm" ]; then
            cat >&2 <<EOF
BLOCKED: $path is a chezmoi-managed target — removing it here does not
retire it; the next 'chezmoi apply' puts it back.

Remove it from the chezmoi source instead:
  git rm $src

then apply (exact_ dirs such as rules/ remove the target on apply):
  chezmoi apply -v ~/.claude
EOF
            exit 2
        fi
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

    # Unmanaged and not ignored: only guard the trees where an orphan is
    # harmful — rules/ and CLAUDE.md load into every session, skills/ are
    # auto-discovered — yet the file would never be captured into version
    # control. Removing such an orphan is the remedy, not the harm.
    case "$rel" in
        .claude/rules/* | .claude/skills/* | .claude/CLAUDE.md) ;;
        *) return 0 ;;
    esac
    [ "$verb" = "rm" ] && return 0

    suggested=$(suggest_source "$path") || return 0

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
}

# bash_destinations <command> — print "<verb><TAB><path>" for every write
# destination a shell command names. A heuristic, not a parser: it drops
# heredoc bodies and whitespace-containing quoted strings (prose), then reads
# redirections, splits on ; & | && ||, and reads each segment's verb and args.
bash_destinations() {
    printf '%s\n' "$1" |
        awk -v q="'" '
            BEGIN { hd = "<<-?[ \t]*[\"" q "]?[A-Za-z_][A-Za-z0-9_]*[\"" q "]?" }
            delim != "" {
                line = $0
                if (strip) sub(/^\t+/, "", line)
                if (line == delim) delim = ""
                next
            }
            {
                print
                if (match($0, hd)) {
                    d = substr($0, RSTART, RLENGTH)
                    strip = (d ~ /^<<-/)
                    sub(/^<<-?[ \t]*/, "", d)
                    gsub("[\"" q "]", "", d)
                    delim = d
                }
            }
        ' |
        tr '\n' '\036' |
        sed -E -e "s/'[^']*[[:space:]][^']*'//g" -e 's/"[^"]*[[:space:]][^"]*"//g' |
        tr '\036' '\n' |
        tr -d "\"'" |
        awk '
            function emit(verb, p) { print verb "\t" p }
            function segment(s,    n, i, k, verb, inplace, tdir, last, cnt, a, j) {
                gsub(/[()]/, " ", s)
                n = split(s, w, /[ \t]+/)
                k = 1
                while (k <= n && (w[k] == "" || w[k] == "{" || w[k] == "}" || w[k] ~ /^[A-Za-z_][A-Za-z0-9_]*=/ || w[k] == "sudo" || w[k] == "command" || w[k] == "env")) k++
                if (k > n) return
                verb = w[k]; sub(/.*\//, "", verb)
                if (verb == "gsed") verb = "sed"
                if (verb == "ginstall") verb = "install"
                inplace = 0; tdir = ""; last = ""; cnt = 0
                for (i = k + 1; i <= n; i++) {
                    a = w[i]
                    if (a == "") continue
                    if (a == "-t" && i < n) { tdir = w[++i]; continue }
                    if (a ~ /^--target-directory=/) { tdir = a; sub(/^--target-directory=/, "", tdir); continue }
                    if (a ~ /^-i/ || a ~ /^--in-place/) { inplace = 1; continue }
                    if (a ~ /^-/) continue
                    args[++cnt] = a; last = a
                }
                if (verb == "tee" || verb == "rm" || (verb == "sed" && inplace)) {
                    for (j = 1; j <= cnt; j++) emit(verb, args[j])
                } else if (verb == "cp" || verb == "mv" || verb == "install" || verb == "ln") {
                    if (tdir != "") emit(verb, tdir)
                    else if (cnt >= 2) emit(verb, last)
                    # mv also removes its sources: check each one as an rm.
                    if (verb == "mv") {
                        nsrc = (tdir != "") ? cnt : cnt - 1
                        for (j = 1; j <= nsrc; j++) emit("rm", args[j])
                    }
                }
            }
            {
                line = $0
                # Heredoc operators are not redirections.
                gsub(/<<-?[ \t]*[A-Za-z_][A-Za-z0-9_]*/, " ", line)
                # Output redirections: >f, > f, >>f, 2>f, &>f (2>&1 is a dup).
                rest = line
                while (match(rest, /[0-9&]?>>?[ \t]*[^ \t<>;&|()]+/)) {
                    tok = substr(rest, RSTART, RLENGTH)
                    sub(/^[0-9&]?>>?[ \t]*/, "", tok)
                    emit("redirect", tok)
                    rest = substr(rest, RSTART + RLENGTH)
                }
                gsub(/[0-9&]?>>?[ \t]*&[0-9-]+/, " ", line)
                gsub(/[0-9&]?>>?[ \t]*[^ \t<>;&|()]+/, " ", line)
                m = split(line, parts, /&&|\|\||[;|&]/)
                for (x = 1; x <= m; x++) segment(parts[x])
            }
        '
}

# in_bash_scope <abs-path> — the trees the Bash branch guards.
in_bash_scope() {
    case "$1" in
        "$claude_dir/rules" | "$claude_dir/rules/"* | \
            "$claude_dir/skills" | "$claude_dir/skills/"* | \
            "$claude_dir/CLAUDE.md") return 0 ;;
    esac
    return 1
}

if [ "$tool" = "Bash" ]; then
    cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null || echo "")
    # Fast bail: a command that never mentions .claude has nothing to guard.
    case "$cmd" in
        *.claude*) ;;
        *) exit 0 ;;
    esac
    command -v chezmoi >/dev/null 2>&1 || exit 0
    while IFS=$'\t' read -r verb dest; do
        [ -n "$dest" ] || continue
        abs=$(normalize "$dest")
        in_bash_scope "$abs" || continue
        check_path "$abs" "$verb"
    done < <(bash_destinations "$cmd")
    exit 0
fi

path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input" 2>/dev/null || echo "")
[ -z "$path" ] && exit 0
path=$(normalize "$path")

case "$path" in
    "$claude_dir"/*) ;;
    *) exit 0 ;;
esac

command -v chezmoi >/dev/null 2>&1 || exit 0

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

check_path "$path" write
exit 0
