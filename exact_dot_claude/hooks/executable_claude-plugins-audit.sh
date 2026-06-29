#!/usr/bin/env bash
# claude-plugins-audit.sh — surface UNDECIDED plugins and MISSING opt-in env flags.
#
# Compares the live laurigates/claude-plugins marketplace plugin set against the
# enabledPlugins map in ~/.claude/settings.json (the RENDERED source of truth,
# pinned by the chezmoi overlay exact_dot_claude/modify_settings.json), plus a
# curated list of recommended opt-in env flags against the live env block.
# Prints a short nudge so a new plugin or a freshly-recommended flag gets a
# true/false decision instead of silently defaulting off.
#
# ALWAYS exits 0 — it is advisory and must never break a session when invoked
# from the SessionStart refresh hook.
#
#   Standalone:  bash ~/.claude/hooks/claude-plugins-audit.sh
#   Called by:   claude-plugins-refresh.sh (when the debounce window elapses)
set -uo pipefail

SETTINGS="${HOME}/.claude/settings.json"
MARKETPLACE="laurigates-claude-plugins"
MARKETPLACE_JSON_URL="https://raw.githubusercontent.com/laurigates/claude-plugins/refs/heads/main/.claude-plugin/marketplace.json"

# Curated recommended opt-in env flags. KEEP IN SYNC with the overlay env block
# in exact_dot_claude/modify_settings.json. Add a new flag here ONLY after
# verifying its exact name against current Claude Code docs (code.claude.com/docs)
# — an unverified flag name produces noisy false "missing" nudges every session.
RECOMMENDED_ENV_FLAGS=(
  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
  CLAUDE_CODE_DISABLE_AUTO_MEMORY
  ENABLE_TOOL_SEARCH
  CLAUDE_HOOKS_ENABLE_BASH_ANTIPATTERNS_TEACH
  CLAUDE_HOOKS_ENABLE_CALENDAR_ESTIMATES
)

command -v jq >/dev/null 2>&1 || exit 0
[ -f "$SETTINGS" ] || exit 0

# --- marketplace plugin set ---------------------------------------------------
# Prefer authenticated `gh api` (no rate limit, works offline-of-raw-CDN); fall
# back to the raw marketplace.json. Both resolve the same canonical list.
marketplace_names() {
  local out=""
  if command -v gh >/dev/null 2>&1; then
    out="$(gh api repos/laurigates/claude-plugins/contents/.claude-plugin/marketplace.json \
            --jq '.content' 2>/dev/null | base64 -d 2>/dev/null \
            | jq -r '.plugins[].name' 2>/dev/null | sort -u)"
  fi
  if [ -z "$out" ]; then
    out="$(curl -fsSL --max-time 8 "$MARKETPLACE_JSON_URL" 2>/dev/null \
            | jq -r '.plugins[].name' 2>/dev/null | sort -u)"
  fi
  printf '%s\n' "$out"
}

mkt="$(marketplace_names)"
# No network / no list -> nothing actionable; stay silent.
[ -z "$mkt" ] && exit 0

# Plugin keys already DECIDED in the overlay (present with true OR false), for
# this marketplace, with the "@marketplace" suffix stripped.
decided="$(jq -r --arg m "$MARKETPLACE" '
  (.enabledPlugins // {}) | keys[]
  | select(endswith("@" + $m)) | sub("@" + $m + "$"; "")' "$SETTINGS" 2>/dev/null | sort -u)"

undecided_list="$(comm -23 <(printf '%s\n' "$mkt") <(printf '%s\n' "$decided"))"
stale_list="$(comm -13 <(printf '%s\n' "$mkt") <(printf '%s\n' "$decided"))"

# --- recommended env flags ----------------------------------------------------
missing_flags=()
for f in "${RECOMMENDED_ENV_FLAGS[@]}"; do
  v="$(jq -r --arg k "$f" '.env[$k] // empty' "$SETTINGS" 2>/dev/null)"
  [ -z "$v" ] && missing_flags+=("$f")
done

# --- nudge --------------------------------------------------------------------
have_news=0
[ -n "$undecided_list" ] && have_news=1
[ -n "$stale_list" ] && have_news=1
[ "${#missing_flags[@]}" -gt 0 ] && have_news=1
[ "$have_news" -eq 0 ] && exit 0

echo "── claude-plugins audit ─────────────────────────────────────"
if [ -n "$undecided_list" ]; then
  echo "New plugin(s) not yet decided in the overlay enabledPlugins (defaulting OFF):"
  printf '%s\n' "$undecided_list" | sed 's/^/  • /'
  echo "  → decide each true/false in exact_dot_claude/modify_settings.json,"
  echo "    or run /configure-claude-plugins --exhaustive."
fi
if [ -n "$stale_list" ]; then
  echo "Pinned plugin(s) no longer in the marketplace (safe to drop from overlay):"
  printf '%s\n' "$stale_list" | sed 's/^/  • /'
fi
if [ "${#missing_flags[@]}" -gt 0 ]; then
  echo "Recommended opt-in env flag(s) absent from settings.env:"
  printf '  • %s\n' "${missing_flags[@]}"
fi
echo "─────────────────────────────────────────────────────────────"
exit 0
