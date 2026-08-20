#!/usr/bin/env bash
# Regression test for always-loaded Claude global context (exact_dot_claude/).
#
# Everything under ~/.claude/rules/ WITHOUT `paths:` frontmatter — plus
# ~/.claude/CLAUDE.md — loads into EVERY session in EVERY project. This test
# pins the context-bloat regressions that prompted the 2026-07 cleanup
# (PR #300, which moved ~28 KB of repo-specific rules to .claude/rules/):
#
#   A. Total always-loaded budget — the sum of unconditional rule bytes +
#      CLAUDE.md must stay under TOTAL_BUDGET_BYTES. Grows past it → migrate
#      repo-specific rules to a project .claude/rules/, add `paths:`
#      frontmatter, split into a skill, or distill.
#   B. Per-file cap — no single unconditional rule over PER_FILE_CAP_BYTES.
#      (chezmoi-conventions.md hit 17 KB before it was moved out.)
#   C. Repo-specific content markers — global rules referencing dotfiles-repo
#      internals (.chezmoidata, dot_zshrc.tmpl, mise run lint, …) belong in
#      the repo-scoped .claude/rules/, not the global tree. Incidental
#      mentions are allowlisted per file; new hits fail until migrated or
#      consciously excepted.
#   D. Frontmatter validity — a rule opening with `---` must declare a
#      non-empty `paths:` list and close the frontmatter block; a typo here
#      silently makes the rule load unconditionally.
#
# Pure-text checks: bash + git + awk only, no network, no marketplace.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEZMOI_DIR="$(dirname "$SCRIPT_DIR")"
cd "$CHEZMOI_DIR" || exit 1

RULES_DIR="exact_dot_claude/rules"
GLOBAL_CLAUDE_MD="exact_dot_claude/CLAUDE.md"

# --- Budgets --------------------------------------------------------------
# Baseline history: 148,588 at introduction (2026-07); 98,956 after the
# same-month consolidation wave (git-hazards merge, path-scoping, skill
# pointers). Headroom is deliberate but small: hitting the budget should
# trigger a cleanup pass, not a bump. Ratchet DOWN when cleanups land;
# raising it needs a justification in the commit message.
#
# 2026-07-28 → 114,000. Justification: the surface had reached 109,998 of
# 110,000 (2 bytes free), so the budget had stopped being a cleanup trigger
# and become a hard stop on *any* new rule content. The additions that hit it
# were compressed ~50% first and both host files brought back under
# PER_FILE_CAP_BYTES. The cleanup pass is deferred, not skipped — the standing
# candidate is exact_dot_claude/rules/multi-model-delegation.md (~6.6 kB),
# which largely duplicates the agent-patterns-plugin:multi-model-delegation
# skill and is a CONSOLIDATE per meta-context-diet; it was being edited by a
# concurrent session at the time. Ratchet back toward 110,000 once it lands.
#
# 2026-08-09 → 120,000. Justified on a PREMISE THAT WAS FALSE, corrected here
# on 2026-08-19. The comment claimed "the 2026-07-28 cleanup DID land:
# multi-model-delegation went 6,607 → 493 bytes (a skill pointer), freeing
# 6.1 kB". It had not: the file was still 6,607 bytes when dotfiles #353 began,
# so those 6.1 kB were booked as freed while still sitting on the surface. The
# real reading at that bump was therefore ~6 kB worse than recorded, and the
# 110,000 ratchet-down target was written off as unreachable on the strength of
# a consolidation that had not happened. Lesson, and the reason this note stays:
# a budget bump must cite MEASURED bytes on disk, never a cleanup believed to
# have landed. The rest of that entry stands — the surface genuinely was at
# 113,990 of 114,000 (10 bytes free) when a 1,381-byte rule was refused, and at
# that margin the gate has no signal left: it cannot distinguish "this addition
# is not worth its bytes" from "nothing fits", and it forces whoever writes the
# next rule to adjudicate someone else's, mid-task, often against files other
# sessions have open. See laurigates/claude-plugins#2324 for the proposal to
# warn at ~95% and print headroom on the passing path.
#
# 2026-08-19 → 86,000 (RATCHET DOWN, -34,000). laurigates/dotfiles #353 promoted
# nine always-loaded rules into the claude-plugins marketplace, leaving pointer
# stubs at the same paths, and split tool-use-patterns.md. multi-model-delegation
# finally landed too (6,607 → 756). Measured on disk after the promotion:
#
#   unconditional_rule_bytes + CLAUDE.md = 80,463   (38 unconditional rules)
#   path_scoped_bytes                    = 45,435   (not counted; loads on match)
#
# That is 35,805 bytes below the 116,268 recorded at the last bump, so 120,000
# had stopped being a cleanup trigger — it left 39.5 kB of headroom, roughly
# half the surface itself. New ceiling 86,000 keeps 5,537 bytes (6.4%) free.
# Deliberately NOT squeezed to the historical ~2 kB margin: #2324's finding is
# that a razor-thin margin destroys the gate's signal and makes every new rule
# an adjudication of someone else's. 6.4% is enough for a normal addition and
# still small enough that a second one triggers a cleanup pass. Ratchet again
# when the next consolidation lands.
#
# Next cleanup candidates (largest unconditional, measured 2026-08-19, none yet
# triaged). Note prefer-diy-over-heavy-dependency.md (651 B) and
# pr-merge-hazards.md (2,163 B) have LEFT this list — both are now pointers:
#   tool-use-patterns.md ~7.7 kB · communication.md ~5.8 kB
#   offload-to-deterministic-substrate.md ~5.4 kB
#   diagnose-at-the-failure-point.md ~4.9 kB · git-hazards.md ~4.7 kB
TOTAL_BUDGET_BYTES=86000
# Largest unconditional rule at introduction: 8,758 bytes.
PER_FILE_CAP_BYTES=10000

# --- Repo-specific markers ------------------------------------------------
# Content matching these belongs in the repo-scoped .claude/rules/, not in
# the global tree that loads everywhere.
MARKERS='\.chezmoidata|dot_zshrc|mise run lint|exact_dot_claude/|\.chezmoiignore|run_onchange|private_dot_config/'
# Allowlisted incidental mentions (pointers/examples, not repo-specific
# content). Format: one rule filename per line. Adding to this list is a
# conscious decision — prefer migrating the rule instead.
MARKER_ALLOWLIST=(
    # pr-merge-hazards.md was allowlisted for "points at the global justfile
    # recipe source"; that `just -g branch-audit` line moved to
    # git-plugin:git-merge-hazards in dotfiles #353, so the stub trips no
    # marker and the entry was removed (verified: grep -E "$MARKERS" is empty).
    claude-plugins-freshness.md    # names the overlay file as source of truth
    path-scoped-rules.md           # chezmoi globs as frontmatter *examples*
    zsh-pattern-expansion-extended-glob.md  # names dot_zshrc.tmpl as one scope example
)

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
pass_count=0; fail_count=0
log_test() { echo -e "${BLUE}TEST:${NC} $*"; }
log_pass() { echo -e "${GREEN}✓ PASS:${NC} $*"; ((pass_count++)); }
log_fail() { echo -e "${RED}✗ FAIL:${NC} $*"; ((fail_count++)); }

# A file is path-scoped iff line 1 is exactly `---` (frontmatter opener).
is_path_scoped() { [[ "$(head -1 "$1")" == "---" ]]; }

# ----------------------------------------------------------------------------
# Check A: total always-loaded budget
# ----------------------------------------------------------------------------
check_total_budget() {
    log_test "Always-loaded global context stays under ${TOTAL_BUDGET_BYTES} bytes"
    local total=0 scoped=0 f sz
    for f in "$RULES_DIR"/*.md; do
        sz=$(wc -c < "$f")
        if is_path_scoped "$f"; then
            scoped=$((scoped + sz))
        else
            total=$((total + sz))
        fi
    done
    local claude_md_sz
    claude_md_sz=$(wc -c < "$GLOBAL_CLAUDE_MD")
    total=$((total + claude_md_sz))
    echo "  unconditional_rule_bytes+claude_md=${total} path_scoped_bytes=${scoped} budget=${TOTAL_BUDGET_BYTES}"
    if (( total <= TOTAL_BUDGET_BYTES )); then
        log_pass "Always-loaded total ${total} <= ${TOTAL_BUDGET_BYTES}"
    else
        log_fail "Always-loaded total ${total} exceeds budget ${TOTAL_BUDGET_BYTES}"
        echo "    Remedies: migrate repo-specific rules to a project .claude/rules/,"
        echo "    add 'paths:' frontmatter to narrow-trigger rules, split content"
        echo "    into an on-demand skill, or distill verbose rules."
        echo "    Largest unconditional rules:"
        for f in "$RULES_DIR"/*.md; do
            is_path_scoped "$f" || wc -c "$f"
        done | sort -rn | head -5 | sed 's/^/      /'
    fi
}

# ----------------------------------------------------------------------------
# Check B: per-file cap for unconditional rules
# ----------------------------------------------------------------------------
check_per_file_cap() {
    log_test "No unconditional global rule exceeds ${PER_FILE_CAP_BYTES} bytes"
    local bad=0 f sz
    for f in "$RULES_DIR"/*.md; do
        is_path_scoped "$f" && continue
        sz=$(( $(wc -c < "$f") ))
        if (( sz > PER_FILE_CAP_BYTES )); then
            log_fail "$(basename "$f") is ${sz} bytes (cap ${PER_FILE_CAP_BYTES}) — path-scope, split, migrate, or convert to a skill"
            bad=1
        fi
    done
    (( bad == 0 )) && log_pass "All unconditional rules under ${PER_FILE_CAP_BYTES} bytes"
}

# ----------------------------------------------------------------------------
# Check C: repo-specific content markers in global rules
# ----------------------------------------------------------------------------
check_repo_specific_markers() {
    log_test "Global rules free of dotfiles-repo-specific markers (allowlist excepted)"
    local bad=0 f base
    for f in "$RULES_DIR"/*.md; do
        base="$(basename "$f")"
        local allowed=""
        local a
        for a in "${MARKER_ALLOWLIST[@]}"; do
            [[ "$base" == "$a" ]] && allowed=1 && break
        done
        [[ -n "$allowed" ]] && continue
        if grep -nE "$MARKERS" "$f" >/dev/null 2>&1; then
            log_fail "$base references repo-specific paths — migrate to .claude/rules/ or allowlist consciously:"
            grep -nE "$MARKERS" "$f" | head -3 | sed 's/^/      /'
            bad=1
        fi
    done
    (( bad == 0 )) && log_pass "No unexpected repo-specific markers in global rules"
}

# ----------------------------------------------------------------------------
# Check D: frontmatter validity for path-scoped rules
# ----------------------------------------------------------------------------
check_frontmatter_validity() {
    log_test "Path-scoped rules have valid, non-empty 'paths:' frontmatter"
    local bad=0 f
    for f in "$RULES_DIR"/*.md; do
        is_path_scoped "$f" || continue
        # Frontmatter = lines between the opening --- and the next ---.
        # Require a paths: key and at least one "- " list entry inside it.
        if ! awk 'NR==1 {next} /^---$/ {exit} {print}' "$f" \
            | grep -q '^paths:'; then
            log_fail "$(basename "$f"): frontmatter lacks a 'paths:' key"
            bad=1
            continue
        fi
        if ! awk 'NR==1 {next} /^---$/ {exit} {print}' "$f" \
            | grep -qE '^[[:space:]]+-[[:space:]]+"'; then
            log_fail "$(basename "$f"): 'paths:' list is empty"
            bad=1
            continue
        fi
        # The closing --- must exist within the first 30 lines.
        if ! awk 'NR>1 && NR<=30 && /^---$/ {found=1} END {exit !found}' "$f"; then
            log_fail "$(basename "$f"): frontmatter never closes (missing second '---')"
            bad=1
        fi
    done
    (( bad == 0 )) && log_pass "All path-scoped frontmatter blocks are well-formed"
}

# ----------------------------------------------------------------------------
echo "=== Claude global context budget ==="
check_total_budget
check_per_file_cap
check_repo_specific_markers
check_frontmatter_validity

echo
echo "=== Summary ==="
echo "PASS=${pass_count} FAIL=${fail_count}"
if (( fail_count > 0 )); then
    echo "STATUS=FAIL"
    exit 1
fi
echo "STATUS=PASS"
exit 0
