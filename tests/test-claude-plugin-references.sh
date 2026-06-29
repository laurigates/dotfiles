#!/usr/bin/env bash
# Regression test for Claude plugin / marketplace references across the repo.
#
# Pins three classes of broken-reference bug that have bitten this repo:
#   A. Marketplace alias drift   — refs using an alias != the canonical one
#                                  (e.g. `lgates-claude-plugins` instead of
#                                  `laurigates-claude-plugins`), which makes
#                                  `claude /plugin install foo@<alias>` fail.
#   B. Nonexistent plugin refs    — `plugin@alias` naming a plugin that is not
#                                  in the marketplace (e.g. `dotfiles-plugin`,
#                                  or a stale pin like `upstream-pr-plugin`).
#   C. Unresolvable slash command — a `claude -p "/cmd …"` headless invocation
#                                  whose command does not resolve to a real
#                                  skill/command (e.g. `/configure:claude-plugins`
#                                  — wrong namespace — vs `/configure-claude-plugins`).
#
# Checks A is pure-text and always runs. Checks B and C resolve against the
# installed marketplace; when it is absent (e.g. a minimal CI runner) they are
# SKIPPED loudly rather than passing silently.
#
# Override the marketplace location with CLAUDE_PLUGINS_MARKETPLACE_DIR.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEZMOI_DIR="$(dirname "$SCRIPT_DIR")"
cd "$CHEZMOI_DIR" || exit 1

MARKETPLACE_DIR="${CLAUDE_PLUGINS_MARKETPLACE_DIR:-$HOME/.claude/plugins/marketplaces/laurigates-claude-plugins}"

# Canonical alias: read from the marketplace manifest when present, else the
# repo-identity default. The repo is laurigates/claude-plugins -> alias name.
CANONICAL_ALIAS="laurigates-claude-plugins"
if [[ -f "$MARKETPLACE_DIR/.claude-plugin/marketplace.json" ]] && command -v jq >/dev/null 2>&1; then
    name="$(jq -r '.name // empty' "$MARKETPLACE_DIR/.claude-plugin/marketplace.json" 2>/dev/null || true)"
    [[ -n "$name" ]] && CANONICAL_ALIAS="$name"
fi

# Built-in slash commands that resolve without a marketplace plugin. Keep
# minimal; extend only when a recipe legitimately invokes a new built-in.
BUILTIN_COMMANDS=(init review security-review code-review simplify verify run loop schedule fewer-permission-prompts claude-api help)

# Paths excluded from text scans: this test (self-references the bad values)
# and the ADR docs (historical record of the deprecated /namespace:command form).
EXCLUDE_PATHSPEC=(':!tests/' ':!docs/adrs/')

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
pass_count=0; fail_count=0; skip_count=0
log_test() { echo -e "${BLUE}TEST:${NC} $*"; }
log_pass() { echo -e "${GREEN}✓ PASS:${NC} $*"; ((pass_count++)); }
log_fail() { echo -e "${RED}✗ FAIL:${NC} $*"; ((fail_count++)); }
log_skip() { echo -e "${YELLOW}● SKIP:${NC} $*"; ((skip_count++)); }

# ----------------------------------------------------------------------------
# Check A: marketplace alias consistency (no marketplace required)
# ----------------------------------------------------------------------------
check_alias_consistency() {
    log_test "Marketplace alias references all use '$CANONICAL_ALIAS'"
    # Match <token>-claude-plugins alias forms. The owner/repo path form
    # `laurigates/claude-plugins` has a slash before `claude` so never matches
    # the required `<token>-claude-plugins` shape.
    # Match `<token>-claude-plugins` in an *alias* position: preceded by `@`,
    # `-`, backtick, space, etc. — but NOT `/`. That excludes the slash-command
    # skill name `/configure-claude-plugins` while keeping `@lgates-claude-plugins`,
    # the cache-key literal, and step-summary echoes. The leading boundary char
    # is captured by -o and stripped with sed.
    local bad
    bad="$(git grep -hoIE '(^|[^a-z0-9_/])[a-z][a-z0-9_]*-claude-plugins' -- . "${EXCLUDE_PATHSPEC[@]}" 2>/dev/null \
        | sed -E 's/^[^a-z]//' | sort -u | grep -vxF "$CANONICAL_ALIAS" || true)"
    if [[ -z "$bad" ]]; then
        log_pass "No non-canonical marketplace aliases found"
        return
    fi
    log_fail "Non-canonical marketplace alias(es) found (expected '$CANONICAL_ALIAS'):"
    local alias
    while IFS= read -r alias; do
        [[ -z "$alias" ]] && continue
        echo "    alias: $alias"
        git grep -nIE "\b${alias}\b" -- . "${EXCLUDE_PATHSPEC[@]}" | sed 's/^/      /'
    done <<< "$bad"
}

# ----------------------------------------------------------------------------
# Check B: every plugin@alias reference names a plugin in the marketplace
# ----------------------------------------------------------------------------
check_plugin_existence() {
    log_test "All 'plugin@alias' references name a plugin in the marketplace"
    if [[ ! -d "$MARKETPLACE_DIR" ]]; then
        log_skip "Marketplace not found at $MARKETPLACE_DIR — cannot verify plugin existence"
        return
    fi
    # Collect referenced plugin names from `name-plugin@alias` tokens.
    local refs
    refs="$(git grep -hoIE '[a-z][a-z0-9-]*-plugin@[a-z0-9_-]+' -- . "${EXCLUDE_PATHSPEC[@]}" 2>/dev/null \
        | sed 's/@.*//' | sort -u || true)"
    if [[ -z "$refs" ]]; then
        log_pass "No plugin@alias references to verify"
        return
    fi
    local missing="" plugin
    while IFS= read -r plugin; do
        [[ -z "$plugin" ]] && continue
        if [[ ! -d "$MARKETPLACE_DIR/$plugin" ]]; then
            missing+="$plugin"$'\n'
        fi
    done <<< "$refs"
    if [[ -z "$missing" ]]; then
        log_pass "All referenced plugins exist in the marketplace"
        return
    fi
    log_fail "Reference(s) to plugin(s) absent from the marketplace:"
    while IFS= read -r plugin; do
        [[ -z "$plugin" ]] && continue
        echo "    plugin: $plugin"
        git grep -nIE "\b${plugin}@" -- . "${EXCLUDE_PATHSPEC[@]}" | sed 's/^/      /'
    done <<< "$missing"
}

# ----------------------------------------------------------------------------
# Check C: every `claude -p "/cmd …"` slash command resolves
# ----------------------------------------------------------------------------
build_command_index() {
    # Bare skill/command names across all plugins, one per line.
    local d f
    for d in "$MARKETPLACE_DIR"/*/skills/*/; do
        [[ -d "$d" ]] && basename "$d"
    done
    for f in "$MARKETPLACE_DIR"/*/commands/*.md; do
        [[ -e "$f" ]] && basename "$f" .md
    done
    printf '%s\n' "${BUILTIN_COMMANDS[@]}"
}

resolve_command() {
    # $1 = command token (may be `name` or `plugin:name`)
    local cmd="$1"
    if [[ "$cmd" == *:* ]]; then
        local plugin="${cmd%%:*}" name="${cmd#*:}"
        [[ -d "$MARKETPLACE_DIR/$plugin/skills/$name" ]] && return 0
        [[ -f "$MARKETPLACE_DIR/$plugin/commands/$name.md" ]] && return 0
        return 1
    fi
    grep -qxF "$cmd" <<< "$COMMAND_INDEX"
}

check_command_resolution() {
    log_test "All 'claude -p \"/cmd\"' invocations resolve to a real command"
    if [[ ! -d "$MARKETPLACE_DIR" ]]; then
        log_skip "Marketplace not found at $MARKETPLACE_DIR — cannot resolve slash commands"
        return
    fi
    COMMAND_INDEX="$(build_command_index | sort -u)"
    # Find claude headless invocations and pull the leading "/token" command.
    # Matches: claude … -p … "/configure-claude-plugins --fix"
    local hits
    hits="$(git grep -nIE 'claude[^"]*-p[^"]*"/[a-z0-9:_-]+' -- . "${EXCLUDE_PATHSPEC[@]}" 2>/dev/null || true)"
    if [[ -z "$hits" ]]; then
        log_pass "No 'claude -p' slash-command invocations found"
        return
    fi
    local any_bad=0 line cmd
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        cmd="$(grep -oE '"/[a-z0-9:_-]+' <<< "$line" | head -1 | sed 's|"/||')"
        [[ -z "$cmd" ]] && continue
        if resolve_command "$cmd"; then
            log_pass "/$cmd resolves ($line)"
        else
            log_fail "/$cmd does NOT resolve — $line"
            any_bad=1
        fi
    done <<< "$hits"
    [[ $any_bad -eq 0 ]] || true
}

echo "========================================"
echo "Claude Plugin Reference Regression Suite"
echo "========================================"
echo "Marketplace: $MARKETPLACE_DIR"
echo "Canonical alias: $CANONICAL_ALIAS"
echo ""

check_alias_consistency
echo ""
check_plugin_existence
echo ""
check_command_resolution

echo ""
echo "========================================"
echo -e "${GREEN}Passed:${NC} $pass_count   ${RED}Failed:${NC} $fail_count   ${YELLOW}Skipped:${NC} $skip_count"
echo "========================================"
if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}✓ All plugin-reference checks passed${NC}"
    [[ $skip_count -gt 0 ]] && echo -e "${YELLOW}  (some checks skipped — install the marketplace to run them)${NC}"
    exit 0
else
    echo -e "${RED}✗ Plugin-reference regressions detected${NC}"
    exit 1
fi
