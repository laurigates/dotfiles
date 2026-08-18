#!/usr/bin/env bash
# Regression test for shell lookup order in an interactive zsh.
#
# Two invariants, both easy to break by accident and both silent when broken:
#
#   PATH:  mise > brew > system
#          `mise activate` PREPENDS, so it establishes this order. Any later
#          `PATH="x:$PATH"` in .zshrc jumps ahead of mise and shadows a managed
#          tool. Nothing errors -- you just silently run a different binary than
#          the one the dotfiles pin. This has happened twice: gcloud's
#          path.zsh.inc (ships its own kubectl) and ~/.bun/bin (ten symlinks
#          left behind by the #360 npm->mise migration).
#
#   fpath: ~/.zfunc > zsh's own functions > brew site-functions
#          First match wins, so this decides which copy of a duplicated
#          completer loads. ~/.zfunc is generated FROM THE BINARY THAT RUNS, so
#          it goes first. zsh's own dir is deliberately ahead of brew because
#          brew's _git is git's bash-completion wrapper, which would displace
#          zsh's much richer native _git -- and dot_zfunc/__git_branch_names
#          hooks that native _git, so it goes inert if brew's copy wins.
#
# Both are properties of a LIVE SHELL, not of the source tree, so this reads a
# real `zsh -i`. On a machine without mise or brew (a CI runner) the affected
# checks SKIP loudly rather than passing vacuously.
#
# The suite ends with a self-check that feeds the ordering assertions a
# deliberately scrambled PATH and fails if they report it clean -- a green run
# with a broken assertion is worth nothing.

set -uo pipefail

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; NC=$'\033[0m'
pass_count=0; fail_count=0; skip_count=0

log_pass() { echo -e "  ${GREEN}✓${NC} $1"; pass_count=$((pass_count + 1)); }
log_fail() { echo -e "  ${RED}✗${NC} $1"; fail_count=$((fail_count + 1)); }
log_skip() { echo -e "  ${YELLOW}—${NC} SKIP: $1"; skip_count=$((skip_count + 1)); }

# Commands allowed to lose to a non-mise copy. Each entry needs a reason; an
# unexplained entry is a bug being hidden rather than an exception being made.
#   kubectl -- google-cloud-sdk's path.zsh.inc prepends after `mise activate`
#              and gcloud bundles its own kubectl. To drop this entry, move that
#              source above `eval "$(mise activate zsh)"` in dot_zshrc.tmpl.
#   jnv     -- installed via `cargo install`; ~/.cargo/bin is prepended in
#              zshenv, before mise. Remove the cargo copy to drop this entry.
SHADOW_ALLOWLIST=(kubectl jnv)

# PATH directories exempt from the tier ordering, for the same reason: each one
# prepends after `mise activate` and is tolerated rather than fixed. Listed by
# directory so a NEW out-of-order entry still fails.
#   google-cloud-sdk/bin      -- path.zsh.inc prepends; see dot_zshrc.tmpl
#   android-commandlinetools  -- platform-tools prepend; collides with nothing
TIER_ALLOWLIST_DIRS=(
    "*/google-cloud-sdk/bin"
    "*/android-commandlinetools/*"
)

tier_exempt() {
    local d="$1" pat
    for pat in "${TIER_ALLOWLIST_DIRS[@]}"; do
        # shellcheck disable=SC2053
        [[ "$d" == $pat ]] && return 0
    done
    return 1
}

if ! command -v zsh >/dev/null 2>&1; then
    echo "zsh not installed; nothing to check" >&2
    exit 0
fi

# One interactive shell, dumped once: re-running `zsh -i` per check is slow and
# lets the two halves disagree.
DUMP="$(zsh -i -c 'print -r -- "PATH_BEGIN"; print -l -- $path; print -r -- "FPATH_BEGIN"; print -l -- $fpath' 2>/dev/null)"

if [[ -z "$DUMP" ]]; then
    echo -e "${RED}✗ could not read PATH/fpath from an interactive zsh${NC}" >&2
    exit 1
fi

mapfile -t PATH_ENTRIES < <(printf '%s\n' "$DUMP" | sed -n '/^PATH_BEGIN$/,/^FPATH_BEGIN$/p' | sed '1d;$d')
mapfile -t FPATH_ENTRIES < <(printf '%s\n' "$DUMP" | sed -n '/^FPATH_BEGIN$/,$p' | sed '1d')

classify() {
    case "$1" in
        */.local/share/mise/*|*/mise/shims*) echo MISE ;;
        /opt/homebrew/*|/usr/local/Cellar/*|/home/linuxbrew/*) echo BREW ;;
        /usr/bin|/bin|/usr/sbin|/sbin|/usr/local/bin|/usr/local/sbin|/System/*) echo SYSTEM ;;
        *) echo OTHER ;;
    esac
}

# Returns 0 when every MISE entry precedes every BREW entry, and every BREW
# entry precedes every SYSTEM entry. OTHER/HOME entries are not ranked -- they
# are caught by the shadowing check instead, which is the symptom that matters.
check_path_tiers() {
    local -a entries=("$@")
    local i=0 last_mise=-1 first_brew=-1 last_brew=-1 first_system=-1 kind
    for e in "${entries[@]}"; do
        tier_exempt "$e" && { i=$((i + 1)); continue; }
        kind="$(classify "$e")"
        case "$kind" in
            MISE)   last_mise=$i ;;
            BREW)   [[ $first_brew -lt 0 ]] && first_brew=$i; last_brew=$i ;;
            SYSTEM) [[ $first_system -lt 0 ]] && first_system=$i ;;
        esac
        i=$((i + 1))
    done
    PATH_TIER_DETAIL=""
    local ok=0
    if [[ $last_mise -ge 0 && $first_brew -ge 0 && $last_mise -gt $first_brew ]]; then
        PATH_TIER_DETAIL="a mise entry (idx $last_mise) comes after a brew entry (idx $first_brew)"
        ok=1
    fi
    if [[ $last_brew -ge 0 && $first_system -ge 0 && $last_brew -gt $first_system ]]; then
        PATH_TIER_DETAIL="${PATH_TIER_DETAIL:+$PATH_TIER_DETAIL; }a brew entry (idx $last_brew) comes after a system entry (idx $first_system)"
        ok=1
    fi
    return $ok
}

echo "=============================================="
echo "Shell Lookup-Order Regression Suite"
echo "=============================================="
echo "PATH entries:  ${#PATH_ENTRIES[@]}"
echo "fpath entries: ${#FPATH_ENTRIES[@]}"
echo ""

# ---------------------------------------------------------------- PATH tiers
echo "PATH: mise > brew > system"
have_mise=0; have_brew=0
for e in "${PATH_ENTRIES[@]}"; do
    [[ "$(classify "$e")" == MISE ]] && have_mise=1
    [[ "$(classify "$e")" == BREW ]] && have_brew=1
done

# Print the exemptions before judging, so a tolerated violation is visible
# rather than silently subtracted from the result.
declare -A _exempt_seen=()
for e in "${PATH_ENTRIES[@]}"; do
    if tier_exempt "$e" && [[ -z "${_exempt_seen[$e]:-}" ]]; then
        _exempt_seen[$e]=1
        echo -e "  ${YELLOW}—${NC} tier-exempt (prepends after mise activate): $e"
    fi
done

if [[ $have_mise -eq 0 ]]; then
    log_skip "no mise entries on PATH (mise not activated here)"
elif [[ $have_brew -eq 0 ]]; then
    log_skip "no homebrew entries on PATH (not a brew machine)"
elif check_path_tiers "${PATH_ENTRIES[@]}"; then
    log_pass "tier order holds across ${#PATH_ENTRIES[@]} entries"
else
    log_fail "tier order violated: $PATH_TIER_DETAIL"
fi

# ----------------------------------------------------- shadowed mise commands
echo ""
echo "PATH: no mise-managed command shadowed by an earlier copy"
if [[ $have_mise -eq 0 ]]; then
    log_skip "no mise entries on PATH"
else
    declare -A first_owner=() seen_mise=()
    for d in "${PATH_ENTRIES[@]}"; do
        [[ -d "$d" ]] || continue
        kind="$(classify "$d")"
        while IFS= read -r f; do
            b="${f##*/}"   # not basename(1): that forks per file, ~60s -> ~2s
            [[ -n "${first_owner[$b]:-}" ]] || first_owner[$b]="$kind:$d"
            [[ "$kind" == MISE ]] && seen_mise[$b]=1
        # -L matters: mise install dirs are symlinks (`.../latest -> ./1.36.2`)
        # and find will not descend a symlinked starting point without it. The
        # first version of this test silently missed every such tool.
        done < <(find -L "$d" -maxdepth 1 -type f -perm -u+x -print 2>/dev/null)
    done

    shadowed=0
    for b in "${!seen_mise[@]}"; do
        owner="${first_owner[$b]}"
        [[ "${owner%%:*}" == MISE ]] && continue
        allowed=0
        for a in "${SHADOW_ALLOWLIST[@]}"; do [[ "$b" == "$a" ]] && allowed=1; done
        if [[ $allowed -eq 1 ]]; then
            echo -e "  ${YELLOW}—${NC} allowlisted: $b resolves to ${owner#*:}"
        else
            log_fail "$b is mise-managed but resolves to ${owner#*:}"
            shadowed=$((shadowed + 1))
        fi
    done
    [[ $shadowed -eq 0 ]] && log_pass "${#seen_mise[@]} mise-managed commands, none unexpectedly shadowed"
fi

# --------------------------------------------------------------- fpath order
echo ""
echo "fpath: ~/.zfunc > zsh's own > brew site-functions"
idx_zfunc=-1; idx_sys=-1; idx_brew=-1; i=0
for e in "${FPATH_ENTRIES[@]}"; do
    case "$e" in
        "$HOME"/.zfunc)                   [[ $idx_zfunc -lt 0 ]] && idx_zfunc=$i ;;
        /usr/share/zsh/*/functions)       [[ $idx_sys   -lt 0 ]] && idx_sys=$i ;;
        */share/zsh/site-functions)
            case "$e" in
                /opt/homebrew/*|/home/linuxbrew/*) [[ $idx_brew -lt 0 ]] && idx_brew=$i ;;
            esac ;;
    esac
    i=$((i + 1))
done

if [[ $idx_zfunc -lt 0 ]]; then
    # shellcheck disable=SC2088  # display string, not a path
    log_fail "~/.zfunc is not on fpath at all"
else
    # shellcheck disable=SC2088  # display string, not a path
    log_pass "~/.zfunc present (idx $idx_zfunc)"
fi

if [[ $idx_sys -lt 0 ]]; then
    log_skip "zsh's own functions dir not found on fpath"
elif [[ $idx_zfunc -ge 0 && $idx_zfunc -lt $idx_sys ]]; then
    # shellcheck disable=SC2088  # display string, not a path
    log_pass "~/.zfunc ($idx_zfunc) precedes zsh's own functions ($idx_sys)"
else
    log_fail "zsh's bundled completers ($idx_sys) shadow ~/.zfunc ($idx_zfunc)"
fi

if [[ $idx_brew -lt 0 ]]; then
    if [[ -n "${HOMEBREW_PREFIX:-}" && -d "${HOMEBREW_PREFIX}/share/zsh/site-functions" ]]; then
        log_fail "brew site-functions exists but is not on fpath"
    else
        log_skip "no brew site-functions dir on this machine"
    fi
elif [[ $idx_sys -ge 0 && $idx_brew -lt $idx_sys ]]; then
    log_fail "brew site-functions ($idx_brew) precedes zsh's own ($idx_sys); brew's _git would displace zsh's native one"
else
    log_pass "brew site-functions last (idx $idx_brew)"
fi

# ---------------------------------------------- the specific _git landmine
echo ""
echo "fpath: nothing shadows zsh's native _git"
if [[ -e "$HOME/.zfunc/_git" ]]; then
    # shellcheck disable=SC2088  # display string, not a path
    log_fail "~/.zfunc/_git exists — it is git's bash-completion wrapper and now outranks zsh's native _git, which dot_zfunc/__git_branch_names hooks"
else
    log_pass "no ~/.zfunc/_git"
fi

# ------------------------------------------------------------- self-check
# Prove the tier assertion can actually fail. Without this, a refactor that
# silently neuters check_path_tiers leaves a green suite asserting nothing.
echo ""
echo "self-check: assertions fire on known-bad input"
if check_path_tiers /opt/homebrew/bin "$HOME/.local/share/mise/installs/node/latest/bin" /usr/bin; then
    log_fail "scrambled PATH (brew before mise) was reported clean — the tier check is broken"
else
    log_pass "scrambled PATH correctly rejected ($PATH_TIER_DETAIL)"
fi
if check_path_tiers "$HOME/.local/share/mise/installs/node/latest/bin" /opt/homebrew/bin /usr/bin; then
    log_pass "correctly ordered PATH accepted"
else
    log_fail "correctly ordered PATH rejected — the tier check has a false positive"
fi

echo ""
echo "=============================================="
echo -e "${GREEN}Passed:${NC} $pass_count   ${RED}Failed:${NC} $fail_count   ${YELLOW}Skipped:${NC} $skip_count"
echo "=============================================="
if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}✓ Shell lookup order intact${NC}"
    [[ $skip_count -gt 0 ]] && echo -e "${YELLOW}  (some checks skipped — not a mise/brew machine)${NC}"
    exit 0
fi
echo -e "${RED}✗ Shell lookup-order regressions detected${NC}"
exit 1
