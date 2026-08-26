#!/usr/bin/env bash
# Re-inject lspServers into installed plugin manifests (SessionStart).
#
# WHY: the official *-lsp plugins declare their server ONLY in the marketplace's
# marketplace.json, but Claude Code's LSP manager reads lspServers from the
# INSTALLED plugin's own .claude-plugin/plugin.json. That file ships with just
# name/description/version/author, so every LSP plugin arrives inert:
#   [LSP SERVER MANAGER] getAllLspServers returned 0 server(s)
# A `/plugin update` rewrites the cache and drops the fix again, hence this heal.
#
# Upstream marketplace.json stays the source of truth — nothing is hand-copied
# here, so a changed command or a new server propagates on its own.
set -uo pipefail

plugins_dir="${HOME}/.claude/plugins"
installed="${plugins_dir}/installed_plugins.json"
[ -r "$installed" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

healed=()
while IFS=$'\t' read -r key install_path; do
  [ -n "$install_path" ] || continue
  name="${key%@*}"; marketplace="${key##*@}"
  manifest="${install_path}/.claude-plugin/plugin.json"
  market="${plugins_dir}/marketplaces/${marketplace}/.claude-plugin/marketplace.json"
  [ -r "$manifest" ] && [ -r "$market" ] || continue
  jq -e 'has("lspServers")' "$manifest" >/dev/null 2>&1 && continue

  servers="$(jq -c --arg n "$name" \
    '.plugins[]? | select(.name == $n) | .lspServers // empty' "$market" 2>/dev/null)"
  [ -n "$servers" ] || continue

  tmp="$(mktemp)" || continue
  if jq --argjson s "$servers" '. + {lspServers: $s}' "$manifest" >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
    cat "$tmp" >"$manifest" && healed+=("$name")
  fi
  rm -f "$tmp"
done < <(jq -r '.plugins | to_entries[] | "\(.key)\t\(.value[0].installPath // "")"' "$installed" 2>/dev/null)

[ ${#healed[@]} -gt 0 ] && printf 'lsp-manifest-heal: restored lspServers for %s (plugin update had dropped it)\n' "${healed[*]}"
exit 0
