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
TOTAL_BUDGET_BYTES=110000
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
    git-hazards.md                 # points at the global justfile recipe source
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
