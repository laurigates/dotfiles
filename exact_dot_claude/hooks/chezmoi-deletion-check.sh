# shellcheck shell=bash
# Sourced library — decides which pending `chezmoi status` deletions are safe.
#
# Used by hooks/chezmoi-exact-guard.sh (PreToolUse on `chezmoi apply`) and by
# the source repo's .claude/scripts/post-sync.sh (unattended apply after a
# pull). Both used to stop on every D line; this lets one kind through.
#
# A D line is RETIRED-CLEAN, and safe to apply, when all of these hold:
#   - the status is exactly " D": column 1 blank (the target is unchanged since
#     chezmoi last wrote it), column 2 D (apply would delete it);
#   - `chezmoi state get --bucket=entryState --key=<target>` returns a record
#     of type "file", i.e. chezmoi itself wrote this path;
#   - the record's contentsSHA256 equals the sha256 of the current target.
# That is a file whose source was deleted and that nobody has edited since.
# A never-managed stray has no entryState record, and "MD" means the target
# was edited after chezmoi wrote it; both stay blocked. Every failure (state
# read error, missing jq or sha tool, unreadable file) counts as blocking.
#
# Bash 3.2 compatible: no associative arrays, no mapfile.

# _chezmoi_sha256 <file> — print the hex sha256 of a file, or fail.
_chezmoi_sha256() {
    local out
    if command -v sha256sum >/dev/null 2>&1; then
        out=$(sha256sum <"$1") || return 1
    elif command -v shasum >/dev/null 2>&1; then
        out=$(shasum -a 256 <"$1") || return 1
    else
        return 1
    fi
    printf '%s\n' "${out%% *}"
}

# chezmoi_retired_clean <absolute-target-path> — exit 0 iff chezmoi wrote this
# file and its content is still exactly what chezmoi wrote.
chezmoi_retired_clean() {
    local target="$1" rec type want have
    [ -f "$target" ] && [ ! -L "$target" ] || return 1
    command -v jq >/dev/null 2>&1 || return 1
    rec=$(chezmoi state get --bucket=entryState --key="$target" 2>/dev/null) || return 1
    [ -n "$rec" ] || return 1
    type=$(jq -r '.type // empty' <<<"$rec" 2>/dev/null) || return 1
    [ "$type" = "file" ] || return 1
    want=$(jq -r '.contentsSHA256 // empty' <<<"$rec" 2>/dev/null) || return 1
    [ -n "$want" ] || return 1
    have=$(_chezmoi_sha256 "$target") || return 1
    [ "$have" = "$want" ]
}

# chezmoi_blocking_deletions [home] — read `chezmoi status` output on stdin and
# print "<XY> <path>" for every line with a D in either column that is NOT
# retired-clean. Paths stay as chezmoi printed them (relative to home).
chezmoi_blocking_deletions() {
    local home="${1:-$HOME}" line xy rel
    while IFS= read -r line || [ -n "$line" ]; do
        xy="${line:0:2}"
        case "$xy" in
            *D*) ;;
            *) continue ;;
        esac
        rel="${line:3}"
        if [ "$xy" = " D" ] && chezmoi_retired_clean "$home/$rel"; then
            continue
        fi
        printf '%s %s\n' "$xy" "$rel"
    done
}
