#!/usr/bin/env bash
# Regression test: repo-meta files at the source root must not be applied to $HOME.
#
# What is being protected
# ------------------------
# A source-root entry with no chezmoi attribute prefix (renovate.json5, justfile,
# docker-test.sh, nixos/, ...) maps to a target of the same name directly under
# $HOME unless .chezmoiignore lists it. Files that exist only for working in this
# repo therefore leak into $HOME one at a time, and nothing notices: renovate.json5
# was copied to ~/renovate.json5 (#442) and the repo's own justfile to ~/justfile,
# where `just -g` loaded it and broke. Every one needed a hand-written
# .chezmoiignore line after the fact.
#
# How
# ---
# Take the top-level entries from `git ls-files` (chezmoi ignores dot-prefixed
# source names, and prefixed ones such as dot_/private_/run_ are real targets by
# design), then fail on any whose name `chezmoi managed` lists directly under the
# destination. Only top-level targets are compared; nested ones are covered by
# their own prefixes.
#
# A plain-named entry that IS meant for $HOME goes in INTENDED_ROOT_TARGETS below,
# with a one-line reason. An entry that leaks gets a bare, slash-free line in
# .chezmoiignore ("docs/" for a directory). Never a leading "/": chezmoi >= 2.72
# treats it as a fatal parse error.
#
# A scratch source tree with one deliberate leak (the canary) must be reported;
# that proves the run can see a leak, so a clean result is not vacuous.
#
# Isolation: config, cache and persistent state are scratch files, and the
# destination is an empty scratch dir. chezmoi only reads, so neither the real
# $HOME nor the real chezmoi state is touched.
#
# Usage: tests/test-chezmoi-root-meta.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'

# Plain-named source-root entries that really are targets in $HOME: "name|reason".
INTENDED_ROOT_TARGETS=(
    "Library|macOS LaunchAgents, applied to ~/Library/LaunchAgents"
    "aliases.zsh|sourced by ~/.zshrc (dot_zshrc.tmpl)"
    "scripts|\$HOME/scripts/*.sh run by maint.just and the reclaim LaunchAgent"
)

# Attribute prefixes that mark a source name as a real target (chezmoi source state).
ATTR_PREFIX_RE='^(dot_|private_|exact_|executable_|run_|modify_|create_|symlink_|readonly_|empty_|encrypted_|remove_|literal_|external_)'

for tool in chezmoi git; do
    command -v "$tool" >/dev/null 2>&1 || { echo "${RED}FAIL${NC}: $tool not installed"; exit 1; }
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home"
: > "$tmp/chezmoi.toml"

# root_names SRC: tracked top-level names that carry no prefix and no leading dot.
root_names() {
    git -C "$1" ls-files -z | tr '\0' '\n' | awk -F/ '{ print $1 }' | sort -u |
        while IFS= read -r name; do
            case "$name" in .*) continue ;; esac
            [[ "$name" =~ $ATTR_PREFIX_RE ]] && continue
            printf '%s\n' "$name"
        done
}

# leaks SRC: the root_names of SRC that `chezmoi managed` lists directly under the
# destination (.tmpl is stripped from the target name).
leaks() {
    local src="$1" managed name
    # --exclude=scripts,externals: run_ scripts and downloads are not file targets.
    managed=$(chezmoi managed \
        --source="$src" \
        --destination="$tmp/home" \
        --config="$tmp/chezmoi.toml" \
        --cache="$tmp/cache" \
        --persistent-state="$tmp/chezmoistate.boltdb" \
        --exclude=scripts,externals 2>"$tmp/stderr") || {
        echo "chezmoi managed exited non-zero for $src:" >&2
        cat "$tmp/stderr" >&2
        return 2
    }
    managed=$(grep -v / <<<"$managed")
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        grep -qxF -- "${name%.tmpl}" <<<"$managed" && printf '%s\n' "$name"
    done < <(root_names "$src")
    return 0
}

# Control: a scratch source tree with one unignored plain-named file.
canary_src="$tmp/canary-src"
git init -q "$canary_src" || { echo "${RED}FAIL${NC}: git init failed"; exit 1; }
printf 'meta\n' > "$canary_src/root-meta-canary.txt"
printf 'meta\n' > "$canary_src/root-meta-ignored.txt"
printf 'target\n' > "$canary_src/dot_root-meta-real"
printf 'root-meta-ignored.txt\n' > "$canary_src/.chezmoiignore"
git -C "$canary_src" add -A

canary_out=$(leaks "$canary_src") || { echo "${RED}FAIL${NC}: control run failed"; exit 1; }
if [ "$canary_out" != "root-meta-canary.txt" ]; then
    echo "${RED}FAIL${NC}: control: expected exactly root-meta-canary.txt to be reported, so this"
    echo "      run cannot be trusted to detect a leak. Reported:"
    printf '%s\n' "${canary_out:-(nothing)}" | sed 's/^/        /'
    exit 1
fi

if ! git -C "$REPO_DIR" ls-files --error-unmatch .chezmoiignore >/dev/null 2>&1; then
    echo "${RED}FAIL${NC}: $REPO_DIR is not a git checkout with a tracked .chezmoiignore"
    exit 1
fi

candidates=$(root_names "$REPO_DIR")
leaked=$(leaks "$REPO_DIR") || exit 1

# The allowlist must not outlive the entries it names, or it quietly stops
# guarding the next file added under the same name.
stale=""
for item in "${INTENDED_ROOT_TARGETS[@]}"; do
    name="${item%%|*}"
    grep -qxF -- "$name" <<<"$candidates" || stale="$stale$name"$'\n'
done
if [ -n "$stale" ]; then
    echo "${RED}FAIL${NC}: INTENDED_ROOT_TARGETS names entries that are not tracked, unprefixed"
    echo "      source-root names any more. Remove them from tests/$(basename "${BASH_SOURCE[0]}"):"
    printf '%s' "$stale" | sed 's/^/        /'
    exit 1
fi

unexpected=""
while IFS= read -r name; do
    [ -n "$name" ] || continue
    allowed=0
    for item in "${INTENDED_ROOT_TARGETS[@]}"; do
        [ "${item%%|*}" = "$name" ] && allowed=1
    done
    [ "$allowed" -eq 1 ] || unexpected="$unexpected$name"$'\n'
done <<<"$leaked"

if [ -n "$unexpected" ]; then
    echo "${RED}FAIL${NC}: chezmoi apply would write these source-root files to \$HOME."
    echo "      Repo-only files: add a bare, slash-free line to .chezmoiignore (never a leading /)."
    echo "      Meant for \$HOME: add to INTENDED_ROOT_TARGETS in tests/$(basename "${BASH_SOURCE[0]}") with a reason."
    printf '%s' "$unexpected" | sed 's/^/        /'
    exit 1
fi

n_candidates=$(grep -c . <<<"$candidates")
echo "${GREEN}PASS${NC}: none of $n_candidates plain-named source-root entries is applied to \$HOME" \
    "except ${#INTENDED_ROOT_TARGETS[@]} intended targets (canary leak detected)"
