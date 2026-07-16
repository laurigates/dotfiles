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

# Audit committed project plugin pins for drift vs canonical over the whole ~/repos tree (read-only)
[group: "plugins"]
plugins-audit: (_plugins-audit-roots (env_var('HOME') / "repos"))

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

# ── Domain-scoped bulk install/check/re-eval across repos ─────────────────────
# Orchestration layer over the per-repo judgment skills (configure-claude-plugins,
# health-check --scope=stack, configure:repo). Enumerate a domain scope → fzf
# --multi checkbox picker → sequential per-repo action → deterministic alias
# post-pass. AI-free orchestration; per-repo judgment still runs `claude -p`.

# Enumerate guarded repo paths for a domain scope (fvh|laurigates|all)
[private]
_plugins-repos scope:
    #!/usr/bin/env bash
    set -uo pipefail
    case "{{scope}}" in
      fvh)        dirs=("$HOME/repos/ForumViriumHelsinki") ;;
      laurigates) dirs=("$HOME/repos/laurigates") ;;
      all)        dirs=("$HOME/repos/ForumViriumHelsinki" "$HOME/repos/laurigates") ;;
      *) echo "{{YELLOW}}Unknown scope: {{scope}} (use fvh|laurigates|all){{NORMAL}}" >&2; exit 2 ;;
    esac
    # Guard on `.git` (dir OR worktree file), NOT `git rev-parse` — ~/repos is
    # itself a git repo, so rev-parse falsely passes non-repos (archive/, tmp/, …).
    for d in "${dirs[@]}"; do
      [ -d "$d" ] || continue
      for e in "$d"/*/; do e="${e%/}"
        if [ -e "$e/.git" ]; then printf '%s\n' "$e"
        elif [ -f "$e/.claude/settings.json" ]; then
          printf '{{YELLOW}}FLAG{{NORMAL}} non-repo with .claude config, skipped: %s\n' "$e" >&2
        fi
      done
    done

# Annotate one repo's plugin-config state as `path<TAB>summary` (fzf row + preview + check report)
[private]
_plugins-annotate repo:
    #!/usr/bin/env bash
    set -uo pipefail
    repo="{{repo}}"; repo="${repo%/}"
    s="$repo/.claude/settings.json"
    if [ ! -f "$s" ]; then printf '%s\tsettings=MISSING\n' "$repo"; exit 0; fi
    # Alias allowlist for laurigates/claude-plugins (EXCLUDES claude-plugins-official,
    # a different marketplace). Alias = the segment after the last @ in each key.
    allow_re='^(laurigates-claude-plugins|claude-plugins|lgates-claude-plugins|laurigates-plugins)$'
    mapfile -t all_aliases < <(jq -r '(.enabledPlugins // {}) | keys[] | split("@") | .[-1]' "$s" 2>/dev/null)
    total=${#all_aliases[@]}
    lauri_n=0; declare -A seen
    for a in "${all_aliases[@]}"; do
      if [[ "$a" =~ $allow_re ]]; then lauri_n=$((lauri_n + 1)); seen["$a"]=1; fi
    done
    if [ "$lauri_n" -eq 0 ]; then status="none"
    else
      drift=0; for a in "${!seen[@]}"; do [ "$a" != "laurigates-claude-plugins" ] && drift=1; done
      if [ "$drift" -eq 1 ]; then status="{{YELLOW}}DRIFT{{NORMAL}}"; else status="ok"; fi
    fi
    mp_keys="$(jq -r '.extraKnownMarketplaces // {} | to_entries | map(select(.value.source.repo == "laurigates/claude-plugins")) | .[].key' "$s" 2>/dev/null)"
    wf=(); for f in claude.yml claude-review.yml claude-code-review.yml; do
      [ -f "$repo/.github/workflows/$f" ] && wf+=("$f")
    done
    track="tracked"
    git -C "$repo" check-ignore -q .claude/settings.json 2>/dev/null && track="gitignored"
    ann="enabled=${total} lauri=${lauri_n}"
    [ "${#seen[@]}" -gt 0 ] && ann="$ann aliases=$(printf '%s\n' "${!seen[@]}" | sort | paste -sd, -)"
    ann="$ann $status"
    [ -n "$mp_keys" ] && ann="$ann mp=$(printf '%s' "$mp_keys" | paste -sd, -)"
    [ "${#wf[@]}" -gt 0 ] && ann="$ann wf=$(IFS=,; echo "${wf[*]}")"
    ann="$ann $track"
    printf '%s\t%s\n' "$repo" "$ann"

# Normalize every laurigates alias to laurigates-claude-plugins (idempotent; edits local files even if gitignored)
[group: "plugins"]
plugins-normalize-alias repo:
    #!/usr/bin/env bash
    # Deterministic post-pass after any skill write (the skill may write the
    # `claude-plugins` alias; this reconciles it). Two parts: settings.json (jq,
    # keyed on source.repo — robust to whatever alias the skill wrote) and
    # workflows (perl). Shows a diff; re-run is a no-op ("already canonical").
    set -uo pipefail
    repo="{{repo}}"; repo="${repo%/}"
    canon="laurigates-claude-plugins"
    changed=0
    # --- settings.json -----------------------------------------------------------
    s="$repo/.claude/settings.json"
    if [ -f "$s" ]; then
      new="$(jq --arg canon "$canon" '
        ["laurigates-claude-plugins","claude-plugins","lgates-claude-plugins","laurigates-plugins"] as $allow
        | (.extraKnownMarketplaces // {}) as $m
        | (if ($m | length) > 0 then
            .extraKnownMarketplaces = ($m | to_entries
              | map(if (.value.source.repo == "laurigates/claude-plugins") then .key = $canon else . end)
              | from_entries)
          else . end)
        | .enabledPlugins = ((.enabledPlugins // {}) | to_entries
            | map((.key | split("@")) as $p
              | if (($p | length) > 1) and ($allow | index($p[-1]))
                then .key = (($p[:-1] | join("@")) + "@" + $canon) else . end)
            | from_entries)
      ' "$s" 2>/dev/null)"
      if [ -n "$new" ] && [ "$(printf '%s' "$new" | jq -S .)" != "$(jq -S . "$s")" ]; then
        echo "{{BLUE}}settings.json alias changes for $repo:{{NORMAL}}"
        diff <(jq -S '{extraKnownMarketplaces, enabledPlugins}' "$s") <(printf '%s' "$new" | jq -S '{extraKnownMarketplaces, enabledPlugins}') || true
        printf '%s\n' "$new" > "$s"
        changed=1
        if git -C "$repo" check-ignore -q .claude/settings.json 2>/dev/null; then
          echo "{{YELLOW}}note:{{NORMAL}} settings.json is gitignored — local-only, nothing to stage."
        fi
      fi
    fi
    # --- workflows ---------------------------------------------------------------
    # The (?![-\w]) lookahead is load-bearing: it protects @claude-plugins-official
    # and never rewrites the already-canonical @laurigates-claude-plugins.
    for f in claude.yml claude-review.yml claude-code-review.yml; do
      wfp="$repo/.github/workflows/$f"
      [ -f "$wfp" ] || continue
      new="$(perl -0pe 's/@(?:claude-plugins|lgates-claude-plugins|laurigates-plugins)(?![-\w])/@laurigates-claude-plugins/g' "$wfp")"
      if [ "$new" != "$(cat "$wfp")" ]; then
        echo "{{BLUE}}workflow $f alias changes for $repo:{{NORMAL}}"
        diff <(cat "$wfp") <(printf '%s' "$new") || true
        printf '%s' "$new" > "$wfp"
        changed=1
      fi
    done
    if [ "$changed" -eq 0 ]; then echo "{{GREEN}}Already canonical: $repo{{NORMAL}}"; fi

# Bulk plugin check/setup/re-eval across a domain scope via an fzf checkbox picker (never commits)
[group: "plugins"]
plugins-bulk scope action="check":
    #!/usr/bin/env bash
    # actions: check (local jq annotation, read-only) | setup (/configure-claude-plugins
    # --fix) | reeval (/health:check --scope=stack --fix) | full (/configure:repo --fix).
    # Sequential (sibling claude subprocesses are rate-limited & per-repo expensive);
    # every claude call gets </dev/null so the picker loop never eats its stdin.
    # NOTE: reeval's fix flow uses per-category AskUserQuestion; under `-p` there is
    # no operator, so it may no-op — best run interactively. setup (--fix) is reliably
    # non-interactive.
    set -uo pipefail
    case "{{action}}" in check|setup|reeval|full) : ;; *) echo "{{YELLOW}}Unknown action: {{action}} (use check|setup|reeval|full){{NORMAL}}" >&2; exit 2 ;; esac
    mapfile -t repos < <(just -g _plugins-repos {{scope}})
    if [ "${#repos[@]}" -eq 0 ]; then echo "{{YELLOW}}No repos for scope {{scope}}.{{NORMAL}}"; exit 0; fi
    list=""
    for r in "${repos[@]}"; do list="$list$(just -g _plugins-annotate "$r" || true)"$'\n'; done
    selected="$(printf '%s' "$list" | fzf --multi --ansi --delimiter='\t' --with-nth=1.. \
      --preview 'just -g _plugins-annotate {1}' --preview-window=up,3,wrap \
      --header 'TAB=mark  ENTER=run  ESC=abort — action={{action}} scope={{scope}}')" || exit 0
    [ -z "$selected" ] && { echo "Nothing selected."; exit 0; }
    mapfile -t picked <<< "$selected"
    ok=0; failed=0
    for line in "${picked[@]}"; do
      [ -z "$line" ] && continue
      repo="${line%%$'\t'*}"
      echo ""; echo "{{BLUE}}=== {{action}} :: $repo ==={{NORMAL}}"
      rc=0
      case "{{action}}" in
        check)  just -g _plugins-annotate "$repo" ;;
        setup)  CLAUDECODE= claude -p "/configure-claude-plugins --fix" --model {{claude_model}} --permission-mode auto </dev/null || rc=$? ;;
        reeval) CLAUDECODE= claude -p "/health:check --scope=stack --fix" --model {{claude_model}} --permission-mode auto </dev/null || rc=$? ;;
        full)   CLAUDECODE= claude -p "/configure:repo --fix" --model {{claude_model}} --permission-mode auto </dev/null || rc=$? ;;
      esac
      if [ "$rc" -eq 0 ]; then echo "{{GREEN}}ok{{NORMAL}}"; ok=$((ok + 1)); else echo "{{YELLOW}}FAILED (rc=$rc){{NORMAL}}"; failed=$((failed + 1)); fi
      case "{{action}}" in
        setup|reeval|full)
          just -g plugins-normalize-alias "$repo"
          echo "Review: git -C \"$repo\" diff"
          ;;
      esac
    done
    echo ""; echo "{{GREEN}}$ok ok, $failed failed.{{NORMAL}}"

# Shared drift-audit body over one-or-more root dirs (used by plugins-audit + plugins-audit-scope)
[private]
_plugins-audit-roots +roots:
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
    done < <(find {{roots}} -type f -path "*/.claude/settings.json" 2>/dev/null)
    echo ""
    echo "{{GREEN}}Scanned $found exhaustive-pinned repo(s); $drifted drifted.{{NORMAL}}"
    [ "$drifted" -gt 0 ] && echo "Bring one to canonical: just plugins-sync-repo <repo-path>"

# Audit committed project plugin pins for drift vs canonical over one domain scope (read-only)
[group: "plugins"]
plugins-audit-scope scope:
    #!/usr/bin/env bash
    set -uo pipefail
    case "{{scope}}" in
      fvh)        roots=("$HOME/repos/ForumViriumHelsinki") ;;
      laurigates) roots=("$HOME/repos/laurigates") ;;
      all)        roots=("$HOME/repos/ForumViriumHelsinki" "$HOME/repos/laurigates") ;;
      *) echo "{{YELLOW}}Unknown scope: {{scope}} (use fvh|laurigates|all){{NORMAL}}" >&2; exit 2 ;;
    esac
    just -g _plugins-audit-roots "${roots[@]}"
