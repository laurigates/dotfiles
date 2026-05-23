# Chezmoi Conventions

Derived from git history patterns (1404 commits, 2018–2026).

## File Naming Prefixes

| Prefix | Meaning | Example |
|--------|---------|---------|
| `dot_` | Creates `.filename` target | `dot_zshrc.tmpl` → `~/.zshrc` |
| `private_` | Mode 0600 (owner-only) | `private_dot_config/` |
| `exact_` | Remove orphaned files in directory | `exact_dot_claude/` |
| `.tmpl` suffix | Chezmoi template with Go text/template syntax | `dot_zshrc.tmpl` |

## Template Conventions

- Use `{{ .chezmoi.os }}` for platform branching, not runtime detection
- Use `.chezmoidata.toml` and `.chezmoidata/` for structured template data
- Keep templates readable: extract complex logic to helper templates or scripts
- Template variables for lists (packages, completions, MCP servers) go in `.chezmoidata/`

## Directory Semantics

- `exact_dot_claude/` — chezmoi source for the user-global `~/.claude/`; orphaned files auto-removed on `chezmoi apply`
- `private_dot_config/` — secret-adjacent configs; mode 0600
- A repo-root `.claude/` *inside* the chezmoi source dir is fine — it's the project-scoped Claude Code config for working in the dotfiles repo (`settings.json`, pinned plugins, hooks, project skills). The chezmoi source repo narrows its `.gitignore` so this is trackable while per-machine runtime state (`sessions/`, `projects/`, `todos/`, `.credentials*`) stays ignored. Do NOT confuse it with `exact_dot_claude/` — that one is the source for `~/.claude/`, not for the chezmoi source repo's `.claude/`.

## Source vs Target

- **Always edit** source files at `~/.local/share/chezmoi/`
- **Never edit** target files directly (e.g., `~/.zshrc`)
- After modifying `exact_dot_claude/rules/`, run `chezmoi apply --force ~/.claude`
- Use `chezmoi diff` to preview changes before applying

## Runtime Drift (Claude Code's `settings.json`)

Some target files are mutated by the application at runtime, not just by `chezmoi apply`. Claude Code writes to `~/.claude/settings.json` when the user toggles plugins, dismisses surveys, changes editor mode, enables features, or modifies anything via `/config` or `/plugin`. The chezmoi source has no idea those mutations happened.

The footgun: after editing the source and running `chezmoi apply`, runtime drift gets clobbered. The user loses plugin enable/disable choices, dismissed survey state, etc.

**Workflow when editing chezmoi-managed `settings.json`:**

1. `chezmoi diff ~/.claude/settings.json` — preview what apply *would* change.
2. If the diff shows entries beyond your intended edit (e.g. `gopls-lsp` flipped, `inputNeededNotifEnabled` added, `feedbackSurveyState` updated), those are runtime mutations. Do not blow them away.
3. **Sync source from target by direct editing** — copy the runtime mutations into the chezmoi source until `chezmoi diff` shows only your intended change. Alternative: `chezmoi re-add ~/.claude/settings.json` (overwrites source with target, then re-do your edit).
4. `chezmoi apply --force ~/.claude/settings.json` — `--force` skips the TTY prompt that fires when chezmoi detects the target changed since it last wrote it. Safe *only* after the diff is verified clean.

In headless environments (Claude Code agent sessions, CI), the TTY prompt errors out with `could not open a new TTY` — `--force` is the path past that, but only after the diff confirms no drift will be lost.

| Symptom | Cause | Fix |
|---|---|---|
| `chezmoi diff` shows entries you didn't edit | Claude Code mutated the target | Sync source first |
| `chezmoi apply` errors `could not open a new TTY` | Target changed since chezmoi last wrote it | Verify diff, then `--force` |
| Plugin enable/disable choices revert after apply | Source was applied over runtime mutations | Re-toggle, then `chezmoi re-add` to capture |

Applies equally to any other tool that writes to its own chezmoi-managed config: `~/.config/gh/config.yml`, `~/.config/mise/config.toml` when mise mutates it, etc. Check `chezmoi diff` before applying.

## Script Conventions

- `run_onchange_*` scripts execute when their template hash changes
- `run_once_*` scripts execute only on first apply
- Scripts should be idempotent — safe to re-run

## Deprecation Patterns

From commit history: promptly replace deprecated tools and APIs:
- `docker-compose` → `docker compose` (CLI v2)
- `vim.loop` → `vim.uv` (Neovim API)
- `detect-secrets` → `gitleaks` (secret scanning)
- `curl|sh` → setup actions (CI security)
