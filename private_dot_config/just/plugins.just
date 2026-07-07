# Claude Plugins — canonical recipes (single source of truth).
#
# Imported by BOTH:
#   • the dotfiles repo justfile (so `just plugins-*` works in this repo), and
#   • the global ~/.config/just/justfile (so `just -g plugins-*` works from ANY directory).
#
# chezmoi applies this file to ~/.config/just/plugins.just; the global
# justfile (~/.config/just/justfile) imports it as a sibling. Edit here, then
# `chezmoi apply`.

# Claude model for headless `claude -p` recipes (single source of truth,
# referenced as {{claude_model}} in plugins-setup-repo / plugins-check-repo).
# Defined HERE — not in an importing justfile — because this file is imported
# by BOTH the dotfiles repo justfile and the global justfile; a definition in
# only one importer leaves {{claude_model}} undefined in the other, breaking
# every `just` invocation there (and silently downgrading the grouped `_just`
# completer to flat). Bump the version here to update everywhere.
claude_model := "claude-opus-4-8"

marketplace := "laurigates-claude-plugins"
marketplace_url := "https://raw.githubusercontent.com/laurigates/claude-plugins/refs/heads/main/.claude-plugin/marketplace.json"

# Fetch plugin names from marketplace
[private]
plugin-names:
    @curl -s "{{marketplace_url}}" | jq -r '.plugins[].name'

# List installed plugins and their status
[group: "plugins"]
plugins-list:
    @echo "{{BLUE}}Installed Claude plugins:{{NORMAL}}"
    @CLAUDECODE= claude plugin list

# List installed plugins as JSON
[group: "plugins"]
plugins-json:
    @CLAUDECODE= claude plugin list --json

# Install all plugins from marketplace
[group: "plugins"]
plugins-install:
    @echo "{{BLUE}}Installing all plugins from {{marketplace}}...{{NORMAL}}"
    @for p in $(curl -s "{{marketplace_url}}" | jq -r '.plugins[].name'); do \
        echo "  Installing $p..."; \
        CLAUDECODE= claude plugin install "${p}@{{marketplace}}" 2>&1 | tail -1; \
    done
    @echo "{{GREEN}}Done. Restart Claude Code to apply changes.{{NORMAL}}"

# Run `claude plugin <action>` over every installed plugin from this marketplace,
# narrowed by an optional jq {{filter}} fragment. Single source of truth for the
# bulk enable/disable/update/uninstall recipes below — they differ ONLY in the
# action verb and the enabled-state filter, so they share this body.
[private]
_plugins-foreach action filter="":
    @echo "{{BLUE}}Running plugin {{action}} for {{marketplace}}...{{NORMAL}}"
    @CLAUDECODE= claude plugin list --json \
        | jq -r '.[] | select(.id | endswith("@{{marketplace}}")) {{filter}} | .id' \
        | while read -r p; do \
            echo "  {{action}} $p..."; \
            CLAUDECODE= claude plugin {{action}} "$p" 2>&1 | tail -1; \
        done
    @echo "{{GREEN}}Done. Restart Claude Code to apply changes.{{NORMAL}}"

# Enable all installed (currently-disabled) plugins from marketplace
[group: "plugins"]
plugins-enable: (_plugins-foreach "enable" "| select(.enabled == false)")

# Disable all installed (currently-enabled) plugins from marketplace
[group: "plugins"]
plugins-disable: (_plugins-foreach "disable" "| select(.enabled == true)")

# Update all installed plugins from marketplace
[group: "plugins"]
plugins-update: (_plugins-foreach "update")

# Uninstall all plugins from marketplace
[group: "plugins"]
plugins-uninstall: (_plugins-foreach "uninstall")

# Reinstall all plugins (uninstall → install → enable)
[group: "plugins"]
plugins-reinstall: plugins-uninstall plugins-install plugins-enable

# Configure current repository to use laurigates/claude-plugins marketplace (writes .claude/settings.json and workflows)
[group: "plugins"]
plugins-setup-repo:
    @echo "{{BLUE}}Configuring Claude plugins for repository at $(pwd)...{{NORMAL}}"
    CLAUDECODE= claude -p "/configure-claude-plugins --fix" --model {{claude_model}} --permission-mode auto

# Report current repository's Claude plugin configuration without changes
[group: "plugins"]
plugins-check-repo:
    @echo "{{BLUE}}Checking Claude plugin configuration for repository at $(pwd)...{{NORMAL}}"
    CLAUDECODE= claude -p "/configure-claude-plugins --check-only" --model {{claude_model}}

# Audit committed project plugin pins for drift vs canonical (read-only)
[group: "plugins"]
plugins-audit:
    #!/usr/bin/env bash
    # Canonical = the @laurigates-claude-plugins keys in ~/.claude/settings.json.
    # Compares ONLY that marketplace's keys (official LSPs and other-marketplace
    # aliases vary in naming and are out of scope). Flags only "exhaustive" pins
    # — an ABSOLUTE floor of laurigates keys separates them (>= 41 in practice)
    # from deliberate narrow subsets (<= 21); the floor is canonical-growth-proof,
    # unlike a %-of-canonical threshold which reclassifies drifted-behind pins as
    # subsets. enabledPlugins uses whole-map replacement, so an exhaustive pin
    # omitting a new plugin silently disables it in web/remote — exactly this drift.
    set -uo pipefail
    canonical="$HOME/.claude/settings.json"
    mp="laurigates-claude-plugins"
    floor=30
    if [ ! -f "$canonical" ]; then echo "{{YELLOW}}No $canonical — apply the chezmoi overlay first.{{NORMAL}}"; exit 1; fi
    lauri_keys() { jq -r --arg m "$mp" '(.enabledPlugins // {}) | keys[] | select(endswith("@"+$m)) | sub("@"+$m+"$";"")' "$1" 2>/dev/null | sort -u; }
    canon_keys="$(lauri_keys "$canonical")"
    canon_n="$(printf '%s\n' "$canon_keys" | grep -c . || true)"
    if [ "$canon_n" -eq 0 ]; then echo "{{YELLOW}}Canonical has no @$mp plugins.{{NORMAL}}"; exit 1; fi
    echo "{{BLUE}}Canonical: $canon_n @$mp plugins (~/.claude/settings.json). Exhaustive floor: $floor keys.{{NORMAL}}"
    found=0; drifted=0
    while IFS= read -r f; do
      case "$f" in *"/worktrees/"*|*"/.git/"*) continue ;; esac
      jq -e '.enabledPlugins' "$f" >/dev/null 2>&1 || continue
      keys="$(lauri_keys "$f")"
      n="$(printf '%s\n' "$keys" | grep -c . || true)"
      [ "$n" -lt "$floor" ] && continue   # deliberate subset / different marketplace — not in scope
      found=$((found + 1))
      missing="$(comm -23 <(printf '%s\n' "$canon_keys") <(printf '%s\n' "$keys"))"
      extra="$(comm -13 <(printf '%s\n' "$canon_keys") <(printf '%s\n' "$keys"))"
      valdiff="$(jq -rn --arg m "$mp" --slurpfile a "$canonical" --slurpfile b "$f" '
        ($a[0].enabledPlugins // {}) as $A | ($b[0].enabledPlugins // {}) as $B
        | [ $A | to_entries[] | select(.key | endswith("@"+$m))
            | select(($B[.key] != null) and ($B[.key] != .value)) | (.key | sub("@"+$m+"$";"")) ] | .[]' 2>/dev/null)"
      if [ -z "$missing" ] && [ -z "$extra" ] && [ -z "$valdiff" ]; then continue; fi
      drifted=$((drifted + 1))
      echo ""
      echo "{{YELLOW}}DRIFT:{{NORMAL}} $f ($n @$mp plugins)"
      [ -n "$missing" ] && { echo "  missing (canonical, not pinned):"; printf '    - %s\n' $missing; }
      [ -n "$extra" ]   && { echo "  extra (pinned, not in canonical):"; printf '    + %s\n' $extra; }
      [ -n "$valdiff" ] && { echo "  state drift (enabled differs from canonical):"; printf '    ~ %s\n' $valdiff; }
    done < <(find "$HOME/repos" -type f -path "*/.claude/settings.json" 2>/dev/null)
    echo ""
    echo "{{GREEN}}Scanned $found exhaustive-pinned repo(s); $drifted drifted.{{NORMAL}}"
    [ "$drifted" -gt 0 ] && echo "Bring one to canonical: just plugins-sync-repo <repo-path>"

# Rewrite one repo's committed enabledPlugins from canonical (shows diff first)
[group: "plugins"]
plugins-sync-repo repo:
    #!/usr/bin/env bash
    # Canonical = ~/.claude/settings.json. Shows the enabledPlugins diff, then
    # writes in place (jq normalizes JSON formatting). Reversible — review with
    # `git -C <repo> diff`.
    set -uo pipefail
    canonical="$HOME/.claude/settings.json"
    target="{{repo}}"
    case "$target" in */.claude/settings.json) : ;; *) target="${target%/}/.claude/settings.json" ;; esac
    if [ ! -f "$canonical" ]; then echo "{{YELLOW}}No $canonical{{NORMAL}}"; exit 1; fi
    if [ ! -f "$target" ]; then echo "{{YELLOW}}No $target{{NORMAL}}"; exit 1; fi
    canon_ep="$(jq '.enabledPlugins // {}' "$canonical")"
    new="$(jq --argjson ep "$canon_ep" '.enabledPlugins = $ep' "$target")"
    if [ "$new" = "$(cat "$target")" ]; then echo "{{GREEN}}Already canonical: $target{{NORMAL}}"; exit 0; fi
    echo "{{BLUE}}enabledPlugins changes for $target:{{NORMAL}}"
    diff <(jq -S '.enabledPlugins // {}' "$target") <(printf '%s' "$canon_ep" | jq -S '.') || true
    printf '%s\n' "$new" > "$target"
    echo "{{GREEN}}Wrote $target — review with: git -C \"$(dirname "$(dirname "$target")")\" diff{{NORMAL}}"
