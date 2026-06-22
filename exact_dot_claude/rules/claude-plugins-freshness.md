# Keeping `laurigates/claude-plugins` Fresh + Plugin Enablement

**Scope**: managing the `laurigates-claude-plugins` marketplace and the
`enabledPlugins` map across the global chezmoi overlay and committed project
configs. The marketplace updates very often (automated upkeep + agent feedback
loops), so freshness and drift are recurring concerns.

## Two independent mechanisms — neither replaces the other

| Concern | Global / local upkeep | Web / remote / CI portability |
|---|---|---|
| **Plugin enablement** | overlay `enabledPlugins` in `exact_dot_claude/modify_settings.json` (the single source of truth) | committed `.claude/settings.json` `enabledPlugins` — the ONLY place plugins get enabled where `~/.claude` is unavailable |
| **Binary tools** (helm, terraform, gitleaks, just…) | installed locally via mise / Brewfile | `scripts/install_pkgs.sh` + a SessionStart hook (see `configure-plugin:configure-web-session`) |

Claude Code web/remote/CI has **no access** to the global `~/.claude` overlay,
so a committed `.claude/settings.json` is the only way to enable *plugins*
there, and `install_pkgs.sh` is the only way to get *binary tools*. Both are
needed for full web parity. There is no imperative substitute for plugin
enablement — committed settings stay canonical for that.

## `enabledPlugins` merge semantics: whole-map replacement

Verified against `code.claude.com/docs/en/settings.md` (the docs call out
per-key merging **only** for permission rules; everything else overrides):

> When `enabledPlugins` appears in both user-global and project settings, the
> **highest-precedence scope wins entirely** — the project map REPLACES the
> global map. A plugin enabled globally but absent from the project map is
> **disabled** in that project.

Consequence: a committed project pin that is meant to be exhaustive **must list
the full set**. An exhaustive pin that omits a newly-added marketplace plugin
silently disables it in web/remote. Deliberate *narrow* subsets are fine — a
new plugin defaulting off is the intended behavior for an intentionally narrow
repo. (Hooks, by contrast, are **unioned** across sources — see
`code.claude.com/docs/en/hooks.md`.)

## Freshness automation (global)

- `~/.claude/hooks/claude-plugins-refresh.sh` — a debounced, backgrounded
  SessionStart hook. Claude Code's plugin auto-update is startup-only with no
  time interval, so long-lived sessions go stale; this refreshes the
  marketplace at most once per `CLAUDE_PLUGINS_REFRESH_INTERVAL_HOURS` (4h
  default) without blocking startup. Set
  `CLAUDE_PLUGINS_REFRESH_SELF_UPDATE=1` to also run `claude update`.
  `--force` bypasses the debounce. Log: `$TMPDIR/claude-plugins-refresh.log`.
- `~/.claude/hooks/claude-plugins-audit.sh` — prints a nudge for marketplace
  plugins not yet decided in the overlay `enabledPlugins` (so a new plugin gets
  an explicit true/false rather than silently defaulting off), stale pins no
  longer in the marketplace, and recommended opt-in env flags missing from
  `settings.env`. Runnable standalone; invoked by the refresh hook when due.
  Its `RECOMMENDED_ENV_FLAGS` list must stay in sync with the overlay `env`
  block, and a flag is added only after verifying its exact name in the docs.
- The overlay pins `extraKnownMarketplaces.laurigates-claude-plugins.autoUpdate
  = true` so the freshness intent is durable, not just runtime state.

## Reconciling committed project pins (drift)

- `just plugins-audit` — read-only; flags repos whose committed *exhaustive*
  pin (≥ 90% of canonical keys) has drifted from the canonical global set
  (missing / extra / state-diff). Narrow subsets are ignored.
- `just plugins-sync-repo <repo>` — rewrites one repo's committed
  `enabledPlugins` from canonical, showing the diff first. Reversible via git.

After editing the overlay, sync with `chezmoi apply -v ~/.claude` and confirm
`chezmoi diff ~/.claude` is empty (the overlay is idempotent).
