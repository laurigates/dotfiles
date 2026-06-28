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

## exact_ Dirs DELETE Unmanaged Files — Check `chezmoi status` Before Apply

An `exact_` source dir (notably `exact_dot_claude/` → `~/.claude/`) makes
apply **remove every target entry** that is in neither the source nor a
`.chezmoiignore`. With `--force` (required in headless sessions) the removal
is **silent** — no prompt, no warning. This deleted a freshly created
`~/.claude/friction-reports/` (10 files, ~150 KB) on 2026-06-10; it was
recovered only because the contents happened to survive in session
transcripts and context.

Two traps stack here:

1. **Path-scoped `chezmoi diff <target>` does NOT show pending deletions of
   unmanaged files** (verified: a canary file in `~/.claude` produced empty
   `chezmoi diff ~/.claude` output). The "diff before apply" habit alone
   cannot catch this. Only `chezmoi status` (` D <path>` lines) or the
   *unrestricted* `chezmoi diff` (`deleted file mode` hunks) reveal them.
2. **`--force` only suppresses the prompt; it adds no safety.** The check
   has to happen before the apply, not be delegated to the prompt.

**The rule:**

- **Before any `chezmoi apply` that touches an exact_ tree**, run
  `chezmoi status <target-tree>` and treat every ` D` line as a stop
  signal: either it's an intended removal, or the file must first be
  registered (below). Never apply over an unexplained ` D`.
- **Creating or moving files INTO a chezmoi-managed target tree requires
  registering them in the same change** — `chezmoi add <target>` if it
  should be managed, or a `.chezmoiignore` entry (with a comment saying
  who owns it) if intentionally unmanaged. A new top-level entry in an
  exact_ dir that is neither is one apply away from deletion.
- `.chezmoiignore` placement: the file inside the exact_ source dir
  (`exact_dot_claude/.chezmoiignore`) with patterns relative to that
  target (`friction-reports/`, `skills/notebooklm/`).
- exact_ semantics apply **per directory level**: only the dir carrying the
  `exact_` prefix purges unmanaged entries; its non-`exact_` subdirs (e.g.
  `rules/`, `skills/` under `exact_dot_claude/`) tolerate unmanaged files.
  That asymmetry is why damage can look partial — and why "it survived last
  time" proves nothing about a sibling path.

## Finding the Source File — Ask Chezmoi, Don't Translate

When you know a **target** path and need to read or edit its **source**, do
not hand-translate the `dot_` / `private_` / `exact_` / `.tmpl` /
`encrypted_` prefixes — let chezmoi compute it. Stacked prefixes
(`private_dot_config/private_fish/...`) make manual translation error-prone,
and a wrong guess silently points at a path that doesn't exist.

```
chezmoi source-path ~/.zshrc
# → ~/.local/share/chezmoi/dot_zshrc.tmpl

chezmoi source-path ~/.claude/rules/security.md
# → ~/.local/share/chezmoi/exact_dot_claude/rules/security.md

chezmoi source-path ~/.config/mise/config.toml
# → ~/.local/share/chezmoi/private_dot_config/mise/config.toml.tmpl
```

The canonical edit workflow becomes: **`chezmoi source-path <target>` →
`Read` that path → `Edit` it → `chezmoi apply`**. This is the same in any
chezmoi-managed repo, so it works regardless of the project's specific
naming layout.

| Need | Command | Notes |
|---|---|---|
| Source path for a target | `chezmoi source-path <target>` | Exits non-zero if the target is **not managed** — check the exit code before reading the result |
| Target path for a source file | `chezmoi target-path <source>` | Inverse direction; useful when browsing the source tree |
| Is this home-dir file managed at all? | `chezmoi unmanaged <path>` / `chezmoi managed <path>` | When `source-path` errors, confirm whether the file is unmanaged vs. ignored (`chezmoi ignored`) |
| Preview rendered target content | `chezmoi cat <target>` | Renders `.tmpl` and decrypts `encrypted_` in memory — reading the raw source shows template syntax, not the result |

`--source-path` is also a global flag: `chezmoi diff --source-path
<source-file>` lets commands take source paths directly when you already
have one.

## `re-add` Skips Templates — It Does NOT Merge Target Edits Back

`chezmoi re-add` is a purely mechanical "copy target bytes → source bytes"
operation, **not** a merge. Its behavior depends entirely on the source's
form, and the template case is the trap:

| Source form | `chezmoi re-add` behavior |
|---|---|
| Plain managed file | **Overwrites** source with the target's current contents (no merge, no diff prompt — last write wins) |
| `.tmpl` template | **Silently skipped** — source left untouched, target edits NOT captured. Docs: *"chezmoi will not overwrite templates."* |
| `encrypted_` file | Re-adds preserving encryption; `--re-encrypt` to refresh |

The danger is the **template case looking like success**: you edit a target
(`~/.zshrc` ← `dot_zshrc.tmpl`), see drift in `chezmoi diff`, run
`chezmoi re-add`, and it exits 0 having done **nothing** — your target edits
are still uncaptured, and you may then `chezmoi apply` and lose them. re-add
refuses to clobber the template because the rendered target can't be reversed
into Go template syntax (it can't know which literal lines were once
`{{ .chezmoi.os }}`).

**The rule:** to pull target edits back into a templated source, do NOT rely
on `re-add`. Either:

1. **Hand-port** — `chezmoi source-path <target>`, open the `.tmpl`, apply the
   edits manually (deciding literal vs. template expression), then
   `chezmoi apply`.
2. **Three-way merge** — `chezmoi merge <target>` launches the configured
   merge tool with the rendered source, the target, and the source. This is
   the closest chezmoi gets to "smart merging" for templates.

After any `re-add` against a tree that might contain templates, verify with
`chezmoi diff <target>` that the drift is actually gone — a still-dirty diff
means re-add skipped a template and the edits remain uncaptured.

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

### Durable fix: manage the file with a `modify_` script

The reconcile dance above is a per-apply chore. For a file the app rewrites *constantly* (Claude Code's `settings.json` is the worst offender — interactive toggles, schema changes across versions, auto-formatting), stop fighting it: convert the static source to a chezmoi **`modify_` script**. chezmoi pipes the *current* target to the script on stdin; the script's stdout becomes the new target. A `jq` deep-merge pins only the keys you manage and lets everything else pass through:

```bash
# exact_dot_claude/modify_settings.json  (must be executable)
current="$(cat)"; [ -z "$current" ] && current='{}'
read -r -d '' overlay <<'OVERLAY' || true
{ "permissions": { "defaultMode": "auto" }, "teammateMode": "auto" }
OVERLAY
jq -n --argjson cur "$current" --argjson ov "$overlay" '$cur * $ov'
```

- Keys named in the overlay are **pinned**; keys you omit (`effortLevel`, `feedbackSurveyState`, any new key a future version adds) **pass through untouched** — drift stops being a problem.
- `jq`'s `*` **replaces arrays**, so `permissions.allow`/`deny` become authoritative: an interactive grant is reverted on the next apply unless promoted into the overlay (good hygiene — keeps project-specific noise out).
- The source is named `modify_<target>` (`modify_settings.json` → `~/.claude/settings.json`), must be **executable**, and — because it ends in `.json` but is a script — must be **excluded from the `check-json` pre-commit hook**: `exclude: '(^|/)modify_.*\.json$'`.
- Verify idempotency: `chezmoi diff` is empty after `chezmoi apply`.

See the `chezmoi-expert` skill REFERENCE for the general `modify_` mechanics. For the permission-key specifics of a Claude Code settings overlay, see `claude-code-auto-mode.md`.

## A Non-`dot_` File at the Source Root Silently Applies to `$HOME`

Every file in the chezmoi source dir maps to a target unless ignored. A
source-root file with **no `dot_`/`private_`/etc. prefix** — e.g. the
dotfiles repo's own `justfile`, `Makefile`, or `Taskfile.yml` kept for
working *in the repo* — maps to a literal target of the same name in
`$HOME` (`justfile` → `~/justfile`). chezmoi applies it, and the copy is
usually broken: a repo justfile's **relative** `import`/`include` paths
(`import 'private_dot_config/just/plugins.just'`) don't resolve from
`$HOME`. The failure is invisible until something reads the leaked file.

The fix is the same as the existing `README.md` / `Dockerfile` /
`docker-compose.yml` entries already in `.chezmoiignore`: ignore the
repo-meta file so it stays repo-local. **Root-anchor** the pattern so it
only catches the source-root copy, not managed nested targets of the same
basename:

```
# .chezmoiignore — root-anchored, won't touch ~/.config/just/justfile etc.
/justfile
```

Verify it's no longer a target, then remove the already-leaked copy:

```
chezmoi ignored | grep -x justfile && rm -f ~/justfile
```

(Discovered 2026-06: the dotfiles repo's own `justfile` had been applying
to `~/justfile`, which then shadowed the intended global justfile — see
below.)

## `just -g` Reads `~/.config/just/justfile`, NOT `~/.user.justfile`

The global justfile (`just -g` / `just --global-justfile`, recipes
invokable from **any** directory) is resolved from a **fixed search
path**, first match wins:

```
$XDG_CONFIG_HOME/just/justfile  →  ~/.config/just/justfile  →  ~/justfile  →  ~/.justfile
```

`~/.user.justfile` is **not** on that path — a global justfile placed
there is never read. So the chezmoi source for the global justfile must
target `~/.config/just/justfile` (source `private_dot_config/just/justfile`,
which can `import 'plugins.just'` / `import 'claude.just'` as same-dir
siblings). Per-area recipe files live beside it
(`~/.config/just/{plugins,claude}.just`) and are imported by both the
global justfile and the dotfiles repo's own justfile, so `just <recipe>`
(in-repo) and `just -g <recipe>` (anywhere) resolve the same recipes.

Note `~/justfile` is earlier in the path than `~/.justfile` but *later*
than `~/.config/just/justfile`. A stray `~/justfile` (e.g. the source-root
leak above) therefore shadows nothing if the `~/.config/just/justfile`
exists — but if it's the *only* candidate, `just -g` loads it and breaks.
Confirm what `just -g` actually reads:

```
cd /tmp && just -g --list      # lists the global recipes, or errors if the wrong file is found
```

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
