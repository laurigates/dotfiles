---
name: pin-plugins
description: Pin every plugin from the laurigates/claude-plugins marketplace explicitly in the current project's .claude/settings.json enabledPlugins map (true/false), so the project fully overrides the user-global enable state. Suggests sensible defaults from repo context, fetches the canonical plugin list via `gh api` (no local clone needed), and shows a diff before writing. Use when the user says "pin plugins", "override global plugins for this project", or "explicitly set every plugin in settings.json".
---

# Pin Marketplace Plugins

Project-local `enabledPlugins` entries take precedence over the user-global
ones in `~/.claude/settings.json`. Setting *every* plugin from the
`laurigates/claude-plugins` marketplace to an explicit `true`/`false` in
`<repo>/.claude/settings.json` makes the project's plugin set deterministic
regardless of what the user toggles globally later.

## Workflow

1. **Confirm scope.** Operate on `<cwd>/.claude/settings.json`. Never touch
   `~/.claude/settings.json` from this skill — that's user-global state.

2. **Fetch the canonical plugin list via `gh api`.** No local marketplace
   clone, no `claude plugin marketplace update` call — those need filesystem
   access outside the repo. The marketplace JSON is a public file in the
   marketplace repo:

   ```bash
   gh api repos/laurigates/claude-plugins/contents/.claude-plugin/marketplace.json \
     --jq '.content' | base64 -d \
     | jq -r '.plugins[] | "\(.name)\t\(.category // "uncategorised")\t\(.description)"'
   ```

   The settings key format is `<plugin-name>@laurigates-claude-plugins`
   (note the hyphen — the marketplace's `name` field is
   `laurigates-claude-plugins`, not the slash-form repo path).

3. **Read the existing project settings.** If
   `<cwd>/.claude/settings.json` is missing, plan to create it with just
   `{"enabledPlugins": {…}}`. If it exists, preserve every other top-level
   key (`permissions`, `hooks`, `enabledMcpjsonServers`, …) — only the
   `enabledPlugins` map is in scope.

4. **Suggest a default per plugin from repo context.** Quick scan, then
   build a proposed map with one line of justification per `true`. Defaults:

   | Signal in repo | Suggest enabling |
   |---|---|
   | `pyproject.toml`, `requirements.txt`, `*.py` | `python-plugin` |
   | `Cargo.toml`, `*.rs` | `rust-plugin` (and `bevy-plugin` if Bevy is in deps) |
   | `go.mod`, `*.go` | `go-plugin` (if present in marketplace) |
   | `package.json`, `*.ts`, `*.tsx` | TypeScript/frontend plugins |
   | `*.tf`, `terraform/` | `terraform-plugin` |
   | `Dockerfile`, `compose.yaml` | `container-plugin` |
   | `Chart.yaml`, `kustomization.yaml`, `k8s/` | `kubernetes-plugin` / `helm-plugin` |
   | `flake.nix`, `default.nix` | `nix-plugin` |
   | `langchain` in deps | `langchain-plugin` |
   | `home-assistant`/`hass` configs | `home-assistant-plugin` |
   | `.github/workflows/` | `github-actions-plugin` |
   | macOS host (`uname -s` = Darwin) | `macos-plugin` |
   | Markdown-heavy `docs/` or `blog/` | `documentation-plugin`, `blog-plugin` |

   Always-useful baseline (enable unless the user says otherwise):
   `agents-plugin`, `agent-patterns-plugin`, `blueprint-plugin`,
   `code-quality-plugin`, `communication-plugin`, `configure-plugin`,
   `git-plugin`, `health-plugin`, `prose-plugin`, `taskwarrior-plugin`,
   `testing-plugin`, `tools-plugin`, `workflow-orchestration-plugin`.

   Anything else from the marketplace not matched: default `false`.
   Existing project values (already-set true/false) win over suggestions —
   only fill in *missing* entries from the suggestion logic.

5. **Show the diff before writing.** Group the proposal into:

   - **Already correct** (count only — don't list)
   - **Will add** (new key → `true`/`false`, with reason for `true`s)
   - **Will change** (existing key → flipped value, with reason)

   Render compact: a small markdown table or a `+`/`-` list. Highlight any
   currently-`true` entries the proposal would turn off — that's where users
   most often disagree.

6. **Ask for confirmation.** One question, accept "yes/go/apply" to proceed,
   or let the user veto specific plugins ("keep terraform-plugin off",
   "also enable api-plugin"). Re-render the diff if they amend.

7. **Write the file.** Merge the new `enabledPlugins` map into the existing
   JSON, preserving all other keys and the surrounding formatting. Prefer
   `jq` for the merge to avoid hand-rolling JSON:

   ```bash
   jq --argjson new "$NEW_MAP" \
      '.enabledPlugins = ($new | to_entries | sort_by(.key) | from_entries)' \
      .claude/settings.json > .claude/settings.json.tmp \
     && mv .claude/settings.json.tmp .claude/settings.json
   ```

   Sort keys alphabetically so future diffs stay clean.

8. **Report.** Print a one-line summary: `pinned N plugins (X enabled, Y
   disabled) in .claude/settings.json`. Mention if the file was created.

## Inputs you can accept

- `--dry-run` — do steps 1–5, skip the write.
- `--all-off` — propose every plugin as `false` (paranoid baseline; user
  flips on what they want).
- `--all-on` — propose every plugin as `true` (rare; only if the user
  explicitly wants the maximal set).
- A list of plugins to force-on/force-off, mixed with the auto-suggestion
  for everything else.

Default behaviour (no flags): auto-suggest from repo context, preserve
existing project values, ask before writing.

## What this skill does not do

- It does **not** modify `~/.claude/settings.json`. Global toggles stay as
  the user set them.
- It does **not** install plugins or add the marketplace. If the marketplace
  isn't already in `~/.claude/settings.json`'s `extraKnownMarketplaces`,
  surface that and stop — installing the marketplace is a user decision.
- It does **not** delete keys for plugins removed from the marketplace.
  Stale entries are harmless and the user may have notes about them; flag
  them in the report instead of deleting.
- It does **not** run `claude plugin marketplace update`. That command
  touches `~/.claude/` state and isn't needed — `gh api` reads the same
  source-of-truth JSON straight from GitHub.

## Why pin everything explicitly

The user-global `enabledPlugins` is shared across every project. A plugin
useful in one repo (e.g. `terraform-plugin` in an infra repo) becomes
noise in another (a Python service). Project-local explicit pins make the
plugin set self-documenting and reproducible per repo, and survive any
future change to the global defaults.
