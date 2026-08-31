# Chezmoi Apply Hazards — full detail

Reference companion to [`.claude/rules/chezmoi-apply-hazards.md`](../.claude/rules/chezmoi-apply-hazards.md),
which carries the invariants and the pre-flight commands. This file holds the
narratives, evidence, and tables behind them.

These hazards fire when you **run a chezmoi command**, not when you edit a
file, which is why the rule that names them is deliberately unscoped: a
`paths:` glob only loads a rule when a matching file is edited, and an apply
that destroys data may touch no source file at all.

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
- **The flip side: non-`exact_` subdirs never PURGE either.** Deleting or
  moving a source file out of `exact_dot_claude/rules/` leaves the old
  target **orphaned in `~/.claude/rules/`** — still loading into every
  session — with no `D` line in `chezmoi status` to flag it (bit twice in
  the 2026-07 context diet). After removing a rule from source, delete the
  target yourself and verify it's truly unmanaged first:
  `chezmoi source-path ~/.claude/rules/<f> || rm ~/.claude/rules/<f>`.
  The inverse leak also happens — a rule created directly in the target is
  never captured to source and silently loads forever; sweep with
  `for f in ~/.claude/rules/*.md; do chezmoi source-path "$f" >/dev/null 2>&1 || echo "UNMANAGED: $f"; done`.


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


## A Non-`--force` Apply Silently UNDER-Applies Drifted Targets

`chezmoi apply <tree>` is **not** all-or-nothing. When some target files in
the tree have **local edits made since chezmoi last wrote them** (target-side
drift — a hand-edit, or another tool that rewrote the target), a non-`--force`
apply syncs the *clean* files and **silently skips the drifted ones**, then
**exits 0**. So "apply ran, exit 0" is **not** proof the whole tree synced —
it can leave part of the tree unsynced with no error.

Observed 2026-06 applying `~/.claude/docs/blueprint-development` (7 edited
files): a plain `chezmoi apply -v <tree>` synced 3, exited 0 (looked done),
and left 4 still `M` in `chezmoi status` because the targets had drifted.

### The trap is reaching for `--force` reflexively

The obvious "fix" — re-run with `--force` — is exactly the move that
**clobbers the target-side edits**. `--force` skips the safety prompt and
overwrites the drifted targets with the source, destroying whatever direct
edits (yours or another tool's) caused the skip in the first place. The skip
was chezmoi *protecting* those edits; forcing past it discards them.

### The rule: diff before you force

`chezmoi status <tree>` tells you **which** files are out of sync (the `M`/`D`
flags). It does **not** tell you what would be lost. Before any `--force`:

1. **`chezmoi diff <tree>`** — see *what* the apply would overwrite. The `-`
   lines are the target-side edits that `--force` would destroy.
2. **Judge the drift.** If those edits are unwanted (stale runtime state you
   don't care about), `--force` is safe. If they're wanted, **capture them
   back to source first** — `just capture-drift` (preview) → `just
   capture-drift-apply`, or `chezmoi re-add` / hand-port per the Runtime Drift
   workflow above (templates need `chezmoi merge`, not `re-add`).
3. **Only then** `chezmoi apply --force <tree>`, and re-check `chezmoi status
   <tree>` is clean (and `chezmoi diff <tree>` empty) to confirm the whole
   tree actually synced.

| Signal | Tells you | Use it to |
|---|---|---|
| `chezmoi status <tree>` after apply | *which* files didn't sync (`M`/`D`) | detect the silent under-apply |
| `chezmoi diff <tree>` | *what* `--force` would overwrite | decide whether the drift is disposable before forcing |

Prefer `chezmoi diff` over a reflexive `--force` precisely so that direct
edits to target files aren't clobbered. `--force` is the last step after the
diff confirms there's nothing worth keeping — never the first reaction to a
partial apply.
