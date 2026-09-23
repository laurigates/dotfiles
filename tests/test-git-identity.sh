#!/usr/bin/env bash
# Regression test for the per-location git identity (Refs #290).
#
# run_onchange_after_10-git-identity.sh sets the default (work) identity and
# four includeIf.gitdir rules with `git config --global`; the rules pull in
# private_dot_config/git/personal.inc (applied to ~/.config/git/personal.inc)
# for repos in personal locations.
#
# `git config --global` writes ~/.gitconfig unless that file is absent AND
# $XDG_CONFIG_HOME/git/config (default ~/.config/git/config) already exists.
# git reads the XDG file first, so ~/.gitconfig wins for any key both define.
# personal.inc:1 used to say the includeIf rules live in ~/.config/git/config.
#
# The script runs once against a scratch HOME in a clean environment (env -i:
# no XDG_CONFIG_HOME, no GIT_CONFIG_GLOBAL, no GIT_DIR/GIT_INDEX_FILE from a
# calling git hook; GIT_CONFIG_NOSYSTEM=1), with personal.inc copied into
# place first, as chezmoi applies files before run_after scripts. Assertions:
#
#   1. every key the script writes lands in $HOME/.gitconfig
#   2. no $HOME/.config/git/config is created
#   3. comments in the identity files that name a global config file name the
#      file git actually wrote
#   4. a repo in each personal location resolves the personal email
#   5. repos under $HOME/work/ and a non-personal $HOME/repos/<org>/ resolve
#      the default email
#
# The expected emails are read from the files under test (personal.inc, and
# the ~/.gitconfig the script writes), not repeated here.

# Every quoted ~ below is literal text (messages, the form comments use).
# shellcheck disable=SC2088

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEZMOI_DIR="$(dirname "$SCRIPT_DIR")"
IDENTITY_SCRIPT="$CHEZMOI_DIR/run_onchange_after_10-git-identity.sh"
PERSONAL_INC="$CHEZMOI_DIR/private_dot_config/git/personal.inc"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass_count=0
fail_count=0

log_test() {
    echo -e "${YELLOW}TEST:${NC} $*"
}

log_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $*"
    # Assignment, not ((x++)): under `set -e` the post-increment returns
    # exit 1 when the pre-value is 0.
    pass_count=$((pass_count + 1))
}

log_fail() {
    echo -e "${RED}✗ FAIL:${NC} $*"
    fail_count=$((fail_count + 1))
}

# Indent each line of $1 under a FAIL message.
log_detail() {
    local line
    while IFS= read -r line; do
        printf '    %s\n' "$line"
    done <<<"$1"
}

# Resolve symlinks (macOS: /var -> /private/var) so the ~ in the gitdir
# patterns expands to the same path git computes for each repo's .git dir.
SCRATCH="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$SCRATCH"' EXIT
FAKE_HOME="$SCRATCH/home"
GLOBAL_FILE="$FAKE_HOME/.gitconfig"
XDG_FILE="$FAKE_HOME/.config/git/config"

# Run a command as if on a fresh machine whose HOME is FAKE_HOME. The ceiling
# stops repo discovery from climbing out of the scratch dir.
in_home() {
    env -i PATH="$PATH" HOME="$FAKE_HOME" GIT_CONFIG_NOSYSTEM=1 \
        GIT_CEILING_DIRECTORIES="$SCRATCH" "$@"
}

# Read config outside any repo, with no scope flag: that is how git resolves
# values at runtime, from ~/.config/git/config and then ~/.gitconfig.
# `git config --global` is not used for reads: git (checked 2.43 to 2.55)
# reads only ~/.gitconfig under --global once that file exists, hiding the
# XDG file.
home_config() {
    in_home git -C "$FAKE_HOME" config "$@"
}

# Print the user.email a new repo at $1 resolves to.
email_at() {
    in_home git init -q -b main "$1"
    in_home git -C "$1" config --get user.email || true
}

setup() {
    mkdir -p "$FAKE_HOME/.config/git"
    cp "$PERSONAL_INC" "$FAKE_HOME/.config/git/personal.inc"
    if ! in_home bash "$IDENTITY_SCRIPT"; then
        log_fail "$IDENTITY_SCRIPT exited non-zero under a scratch HOME"
        exit 1
    fi

    PERSONAL_EMAIL="$(in_home git config --file "$PERSONAL_INC" --get user.email || true)"
    local origin_line
    origin_line="$(home_config --show-origin --get user.email || true)"
    DEFAULT_EMAIL="${origin_line#*$'\t'}"
    DEFAULT_ORIGIN="${origin_line%%$'\t'*}"
    DEFAULT_ORIGIN="${DEFAULT_ORIGIN#file:}"
}

# Guard: the routing checks are vacuous unless both identities exist and differ.
test_identities_distinct() {
    log_test "Default and personal identities are both set and differ"
    if [[ -z "$PERSONAL_EMAIL" ]]; then
        log_fail "No user.email in $PERSONAL_INC"
    elif [[ -z "$DEFAULT_EMAIL" ]]; then
        log_fail "Identity script set no global user.email"
    elif [[ "$PERSONAL_EMAIL" == "$DEFAULT_EMAIL" ]]; then
        log_fail "Default and personal user.email are the same ($DEFAULT_EMAIL)"
    else
        log_pass "default=$DEFAULT_EMAIL personal=$PERSONAL_EMAIL"
    fi
}

test_writes_home_gitconfig() {
    log_test "Every key the identity script writes lands in ~/.gitconfig"
    local entries elsewhere
    entries="$(home_config --show-origin --list || true)"
    elsewhere="$(grep -vF "file:$GLOBAL_FILE"$'\t' <<<"$entries" || true)"
    if [[ -z "$entries" ]]; then
        log_fail "No config entries after running the script"
    elif ! grep -qE $'\tincludeif\\.gitdir:' <<<"$entries"; then
        log_fail "No includeIf.gitdir entries in any global config file"
    elif [[ -n "$elsewhere" ]]; then
        log_fail "Entries written outside ~/.gitconfig:"
        log_detail "${elsewhere//"$FAKE_HOME"/"~"}"
    else
        log_pass "$(printf '%s\n' "$entries" | wc -l | tr -d ' ') entries, all in ~/.gitconfig"
    fi
}

test_no_xdg_config() {
    log_test "No ~/.config/git/config is created"
    if [[ -e "$XDG_FILE" ]]; then
        log_fail "~/.config/git/config exists; git reads it before ~/.gitconfig"
    else
        log_pass "~/.config/git/config absent"
    fi
}

test_comments_name_written_file() {
    log_test "Comments naming the global config file match the file git wrote"
    # The origin as a ~/ path, the form the comments use.
    local written="~${DEFAULT_ORIGIN#"$FAKE_HOME"}"
    local mentions stale
    mentions="$(grep -HnoE '~/(\.gitconfig|\.config/git/config)' "$PERSONAL_INC" "$IDENTITY_SCRIPT" || true)"
    stale="$(printf '%s\n' "$mentions" | awk -F: -v want="$written" 'NF && $NF != want' | sed "s|^$CHEZMOI_DIR/||")"
    if [[ -n "$stale" ]]; then
        log_fail "Comment names a file other than $written:"
        log_detail "$stale"
    else
        log_pass "$(printf '%s' "$mentions" | grep -c . || true) mention(s), all $written"
    fi
}

test_personal_locations() {
    log_test "Repos in personal locations resolve the personal identity"
    # Umbrella repo (exact .git match), a repo under ~/repos/laurigates/, this
    # chezmoi source repo, and the Obsidian vault.
    local repo got ok=1
    for repo in \
        "$FAKE_HOME/repos" \
        "$FAKE_HOME/repos/laurigates/probe" \
        "$FAKE_HOME/.local/share/chezmoi" \
        "$FAKE_HOME/Documents/LakuVault"; do
        got="$(email_at "$repo")"
        if [[ -z "$PERSONAL_EMAIL" || "$got" != "$PERSONAL_EMAIL" ]]; then
            log_fail "~${repo#"$FAKE_HOME"} resolves '$got', want personal '$PERSONAL_EMAIL'"
            ok=0
        fi
    done
    [[ $ok -eq 1 ]] && log_pass "4 personal locations resolve $PERSONAL_EMAIL"
    return 0
}

test_default_locations() {
    log_test "Repos outside personal locations resolve the default identity"
    # ~/repos/<org>/ must not match: the umbrella rule is the exact
    # ~/repos/.git dir, not a ~/repos/ prefix.
    local repo got ok=1
    for repo in \
        "$FAKE_HOME/work/probe" \
        "$FAKE_HOME/repos/other-org/probe"; do
        got="$(email_at "$repo")"
        if [[ -z "$DEFAULT_EMAIL" || "$got" != "$DEFAULT_EMAIL" || "$got" == "$PERSONAL_EMAIL" ]]; then
            log_fail "~${repo#"$FAKE_HOME"} resolves '$got', want default '$DEFAULT_EMAIL'"
            ok=0
        fi
    done
    [[ $ok -eq 1 ]] && log_pass "2 default locations resolve $DEFAULT_EMAIL"
    return 0
}

echo "========================================"
echo "Git Identity (includeIf) Test Suite"
echo "========================================"
echo ""

setup
test_identities_distinct
test_writes_home_gitconfig
test_no_xdg_config
test_comments_name_written_file
test_personal_locations
test_default_locations

echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo -e "${GREEN}Passed:${NC} $pass_count"
echo -e "${RED}Failed:${NC} $fail_count"
echo ""

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    exit 1
fi
