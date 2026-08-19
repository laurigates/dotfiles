#!/usr/bin/env bash
# Regression test for `gh pr <sub> <TAB>` completing PR numbers.
#
# What is being protected
# -----------------------
# gh registers no completion for the [<number> | <url> | <branch>] positional
# of `gh pr view` and friends: `gh __complete pr view ""` returns zero
# candidates with directive 0 (ShellCompDirectiveDefault), which tells the
# shell to fall back to FILE completion. dot_zshrc.tmpl installs
# _gh_pr_numbers to fill that gap and delegate everything else to the real
# _gh. Both halves are silent when broken -- a wrong `words` index makes the
# hook simply never fire, and you are back to a directory listing without any
# error to notice.
#
# Why the run is shaped this way
# ------------------------------
# Completion is a property of a LIVE SHELL, so the end-to-end checks drive a
# real interactive zsh over a pty (zsh/zpty) and read back what TAB inserted.
# The CONTROL run does the same thing with the hook NOT loaded and requires
# the file-completion fallback to appear -- a green run whose control also
# looked "fixed" would prove nothing about the hook.
#
# The candidate set comes from a repo with OPEN PRs, chosen at runtime. A
# sweep over a repo with zero open PRs is green by construction and asserts
# nothing, so that case SKIPS loudly instead of passing vacuously.

set -uo pipefail

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; NC=$'\033[0m'
pass_count=0; fail_count=0; skip_count=0

log_pass() { echo -e "  ${GREEN}✓${NC} $1"; pass_count=$((pass_count + 1)); }
log_fail() { echo -e "  ${RED}✗${NC} $1"; fail_count=$((fail_count + 1)); }
log_skip() { echo -e "  ${YELLOW}—${NC} SKIP: $1"; skip_count=$((skip_count + 1)); }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------------------
# Extract the shipped functions from the rendered zshrc.
#
# Rendering through `chezmoi cat` rather than reading dot_zshrc.tmpl means the
# test exercises the text that actually reaches ~/.zshrc. Retyping the logic
# into the harness would test the copy, not the shipped code.
# ---------------------------------------------------------------------------
echo "Extracting completion functions from the rendered ~/.zshrc"
if ! chezmoi cat ~/.zshrc > "$WORK/zshrc" 2>"$WORK/render.err"; then
    log_fail "chezmoi cat ~/.zshrc failed: $(head -1 "$WORK/render.err")"
    echo "1 failure"; exit 1
fi
sed -n '/^typeset -ga _GH_PR_NUM_SUBS=(/,/^compdef _gh_pr_numbers gh$/p' \
    "$WORK/zshrc" > "$WORK/comp.zsh"
if [ ! -s "$WORK/comp.zsh" ]; then
    log_fail "could not extract _gh_pr_numbers block from the rendered zshrc"
    echo "1 failure"; exit 1
fi
log_pass "extracted $(grep -c '' "$WORK/comp.zsh") lines of completion code"

# ---------------------------------------------------------------------------
# Unit: position detection
#
# _gh_pr_at_number_arg is pure zsh over $words/$CURRENT, so it can be driven
# directly without a completion context.
# ---------------------------------------------------------------------------
echo
echo "Position detection (_gh_pr_at_number_arg)"
cat > "$WORK/unit.zsh" <<'ZSH'
compdef() { : }          # stub: no completion system in this shell
source "$1"
fails=0
check() {
  local want=$1 desc=$2 got; shift 2
  local -a words; words=("$@")
  local CURRENT=$(( ${#words} + 1 ))
  words+=('')
  if _gh_pr_at_number_arg; then got=yes; else got=no; fi
  if [[ $got == $want ]]; then print "PASS $desc"
  else print "FAIL want=$want got=$got $desc"; (( fails++ )); fi
}
check yes 'gh pr view'                      gh pr view
check yes 'gh pr update-branch'             gh pr update-branch
check yes 'gh pr view --web (flag first)'   gh pr view --web
check yes 'gh -R o/r pr view (-R eats arg)' gh -R o/r pr view
check yes 'gh pr view --repo=o/r (=form)'   gh pr view --repo=o/r
check no  'gh pr view 123 (arg supplied)'   gh pr view 123
check no  'gh pr list (not a number sub)'   gh pr list
check no  'gh pr (no subcommand yet)'       gh pr
check no  'gh issue view (not pr)'          gh issue view
check no  'gh pr create'                    gh pr create
check no  'gh -R o/r pr list'               gh -R o/r pr list
exit $(( fails > 0 ))
ZSH
while IFS= read -r line; do
    case "$line" in
        PASS\ *) log_pass "${line#PASS }" ;;
        FAIL\ *) log_fail "${line#FAIL }" ;;
    esac
done < <(zsh "$WORK/unit.zsh" "$WORK/comp.zsh" 2>&1)

# ---------------------------------------------------------------------------
# Pick a control repo that actually has open PRs.
# ---------------------------------------------------------------------------
echo
echo "Selecting a control repo with open PRs"
CONTROL_REPO=""
CONTROL_PREFIX=""
if ! command -v gh >/dev/null 2>&1; then
    log_skip "gh not installed — end-to-end checks need it"
elif ! gh auth status >/dev/null 2>&1; then
    log_skip "gh not authenticated — end-to-end checks need API access"
else
    for candidate in "$REPO_ROOT" "$HOME"/repos/*/*/; do
        [ -d "$candidate/.git" ] || continue
        nums="$(cd "$candidate" && gh pr list --limit 20 --json number \
                --jq '[.[].number] | join(" ")' 2>/dev/null)" || continue
        [ -n "$nums" ] || continue
        # Longest common prefix of the numbers: what TAB inserts when several
        # candidates share a leading run of digits (zsh completes the prefix).
        prefix=""
        first="${nums%% *}"
        for (( i = 1; i <= ${#first}; i++ )); do
            cand="${first:0:i}"; ok=1
            for n in $nums; do case "$n" in "$cand"*) ;; *) ok=0; break;; esac; done
            if [ "$ok" = 1 ]; then prefix="$cand"; else break; fi
        done
        [ -n "$prefix" ] || continue
        CONTROL_REPO="$candidate"; CONTROL_PREFIX="$prefix"
        break
    done
    if [ -z "$CONTROL_REPO" ]; then
        log_skip "no reachable repo with open PRs — an empty sweep asserts nothing"
    else
        log_pass "control repo $(basename "${CONTROL_REPO%/}") — TAB should insert '$CONTROL_PREFIX'"
    fi
fi

# ---------------------------------------------------------------------------
# End-to-end over a pty, plus the no-hook control.
# ---------------------------------------------------------------------------
run_pty() {  # run_pty <load-hook:0|1> <input-line>  -> prints what the shell showed
    local load="$1" line="$2"
    cat > "$WORK/rc.zsh" <<RC
PS1='%% '
fpath=(~/.zfunc \$fpath)
autoload -Uz compinit
compinit -u -d "$WORK/zcompdump"
zstyle ':completion:*' menu no
setopt NO_BEEP
RC
    [ "$load" = 1 ] && echo "source '$WORK/comp.zsh'" >> "$WORK/rc.zsh"
    cat > "$WORK/pty.zsh" <<'ZSH'
setopt EXTENDED_GLOB
zmodload zsh/zpty
cd $3
zpty -b z zsh -f -i
zpty -w z "source $1"
sleep 4
integer i
for (( i=0; i<20; i++ )); do zpty -rt z junk 2>/dev/null; sleep 0.1; done
zpty -w -n z "$2"$'\t'
local out='' chunk
for (( i=0; i<40; i++ )); do
  if zpty -rt z chunk 2>/dev/null; then out+=$chunk; fi
  sleep 0.25
done
zpty -d z 2>/dev/null
print -r -- "${${out//$'\e'\[[0-9;?]#[a-zA-Z]/}//$'\r'/}"
ZSH
    zsh "$WORK/pty.zsh" "$WORK/rc.zsh" "$line" "$CONTROL_REPO" 2>/dev/null
}

if [ -n "$CONTROL_REPO" ]; then
    echo
    echo "End-to-end completion (pty, in $(basename "${CONTROL_REPO%/}"))"

    # CONTROL: without the hook the same TAB must fall back to file completion.
    # If this stops showing files, the assertions below have lost their meaning.
    out="$(run_pty 0 'gh pr view ')"
    if grep -qE '(\.md|\.toml|\.json|\.lock|/)' <<<"$out"; then
        log_pass "CONTROL: without the hook, TAB falls back to file completion"
    else
        log_fail "CONTROL: expected a file listing without the hook; got: $(tr '\n' ' ' <<<"$out" | cut -c1-120)"
    fi

    for sub in view update-branch; do
        out="$(run_pty 1 "gh pr $sub ")"
        if grep -q "gh pr $sub $CONTROL_PREFIX" <<<"$out"; then
            log_pass "gh pr $sub <TAB> inserts PR number(s) ('$CONTROL_PREFIX')"
        else
            log_fail "gh pr $sub <TAB> did not insert '$CONTROL_PREFIX'; got: $(tr '\n' ' ' <<<"$out" | cut -c1-120)"
        fi
    done

    # Delegation: the hook must not swallow gh's own subcommand/flag completion.
    out="$(run_pty 1 'gh pr vie')"
    if grep -q 'gh pr view' <<<"$out"; then
        log_pass "gh pr vie<TAB> still completes to 'view' (delegates to _gh)"
    else
        log_fail "subcommand completion broke; got: $(tr '\n' ' ' <<<"$out" | cut -c1-120)"
    fi

    out="$(run_pty 1 'gh pr view --w')"
    if grep -q 'gh pr view --web' <<<"$out"; then
        log_pass "gh pr view --w<TAB> still completes to '--web' (delegates to _gh)"
    else
        log_fail "flag completion broke; got: $(tr '\n' ' ' <<<"$out" | cut -c1-120)"
    fi
fi

echo
echo "Passed: $pass_count  Failed: $fail_count  Skipped: $skip_count"
[ "$fail_count" -eq 0 ]
