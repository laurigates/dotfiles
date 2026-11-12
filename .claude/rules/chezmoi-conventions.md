---
created: 2026-07-19
modified: 2026-11-11
reviewed: 2026-08-31
paths:
  - "dot_*"
  - "private_dot_*/**"
  - "exact_dot_*/**"
  - ".chezmoidata/**"
  - ".chezmoidata.toml"
  - ".chezmoiignore"
  - ".chezmoiremove"
  - ".chezmoiroot"
  - "run_once_*"
  - "run_onchange_*"
  - "**/*.tmpl"
  - "justfile"
  - "aliases.zsh"
---
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
- After modifying `exact_dot_claude/exact_rules/`, run `chezmoi apply ~/.claude` (`--force` skips the overwrite prompt for targets edited outside chezmoi)
- Use `chezmoi diff` to preview changes before applying

> **Apply-time hazards live in a separate, unscoped rule.** `exact_` deletion,
> `re-add` skipping templates, runtime drift, and the silent under-apply all
> fire when you *run* a chezmoi command rather than edit a file, so a `paths:`
> glob cannot reach them. See `.claude/rules/chezmoi-apply-hazards.md` (always
> loaded) and [`docs/chezmoi-apply-hazards.md`](../../docs/chezmoi-apply-hazards.md).

## Finding the Source File — Ask Chezmoi, Don't Translate

- Given a **target** path, run `chezmoi source-path <target>` to get its
  **source**. Do not hand-translate the `dot_` / `private_` / `exact_` /
  `.tmpl` / `encrypted_` prefixes: with stacked prefixes a wrong guess points
  at a path that does not exist.
- Edit workflow: `chezmoi source-path <target>` → `Read` that path → `Edit`
  it → `chezmoi apply`.
- `source-path` exits non-zero when the target is not managed. Check the exit
  code before reading the result.
- `chezmoi cat <target>` shows the rendered content. The raw source shows
  template syntax.

Examples and the command table (`target-path`, `managed`, `unmanaged`,
`ignored`, `cat`, `--source-path`): [`docs/chezmoi-conventions.md`](../../docs/chezmoi-conventions.md).

## Source-Root Files and `.chezmoiignore` Anchoring

- A source-root file with no `dot_`/`private_`/etc. prefix (`justfile`,
  `Makefile`, `Taskfile.yml`) applies to `$HOME` under the same name. List
  repo-meta files in `.chezmoiignore`.
- Anchor a pattern to the root by writing it bare and slash-free (`justfile`,
  `docs/`). `**/justfile` matches at every depth, including the managed
  `~/.config/just/justfile`.
- Never write a leading `/` in `.chezmoiignore` or `.chezmoiremove`. It is a
  fatal parse error (chezmoi ≥2.72) that stops `apply`, `ignored` and
  `managed`, and chezmoi reports only the first offending line.
- `.chezmoiremove` can only name targets under the destination dir. Delete an
  entry for a path outside `$HOME`: stripping its slash re-points it at a
  different file under `~`.
- `.chezmoiremove` never removes a target that `.chezmoiignore` lists. After
  `chezmoi ignored` confirms the pattern, remove the leaked copy by hand.
- `tests/test-chezmoi-root-meta.sh` (`mise run test:chezmoi-root-meta`) fails
  when a new plain-named source-root file reaches `chezmoi managed`. Add the
  file to `.chezmoiignore`, or to the test's allowlist if it belongs in `$HOME`.

The anchoring table, the 2026-08 CI incident and the cleanup command: [`docs/chezmoi-conventions.md`](../../docs/chezmoi-conventions.md).

## `just -g` Reads `~/.config/just/justfile`, NOT `~/.user.justfile`

- `just -g` takes the first match of `$XDG_CONFIG_HOME/just/justfile`,
  `~/.config/just/justfile`, `~/justfile`, `~/.justfile`. It never reads
  `~/.user.justfile`.
- The global justfile's source is `private_dot_config/just/justfile`. Per-area
  recipe files sit beside it and are imported by both the global justfile and
  the repo's own `justfile`.
- A stray `~/justfile` is loaded only when `~/.config/just/justfile` is
  missing. Check what is read with `cd /tmp && just -g --list`.

The search-path detail: [`docs/chezmoi-conventions.md`](../../docs/chezmoi-conventions.md).

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
