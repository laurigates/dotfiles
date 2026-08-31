---
created: 2026-08-31
modified: 2026-08-31
reviewed: 2026-08-31
---
# Chezmoi Apply Hazards — Check Before You Apply

**Unscoped on purpose.** Every hazard here fires when you *run a chezmoi
command*, not when you edit a file. A `paths:` glob only loads a rule when a
matching file is edited, so scoping this one would silently disarm it on
exactly the turns it exists for — an apply that deletes data can touch no
source file at all. Its edit-time sibling, `chezmoi-conventions.md`, is
scoped; this one cannot be.

Full narratives, evidence, and tables: [`docs/chezmoi-apply-hazards.md`](../../docs/chezmoi-apply-hazards.md).

## The four hazards

| Hazard | What goes wrong | The tell |
|---|---|---|
| **`exact_` dirs delete unmanaged files** | Apply removes every target entry in neither the source nor `.chezmoiignore`. With `--force` the removal is **silent** | ` D` lines in `chezmoi status` — a path-scoped `chezmoi diff <target>` does **not** show them |
| **`re-add` silently skips templates** | Exits 0 having done nothing; your target edits stay uncaptured and the next apply destroys them | `chezmoi diff <target>` still dirty after a "successful" re-add |
| **Runtime drift** | The app rewrites its own config (Claude Code's `settings.json`); apply clobbers the user's plugin/survey/editor state | `chezmoi diff` shows entries you never edited |
| **Non-`--force` apply under-applies** | Syncs the clean files, **silently skips drifted ones**, exits 0 — so "apply ran, exit 0" is not proof the tree synced | `chezmoi status <tree>` still shows `M` after the apply |

## The pre-flight, in order

```sh
chezmoi status <tree>     # WHICH files are out of sync (M/D) — catches the silent under-apply
chezmoi diff <tree>       # WHAT --force would overwrite; the `-` lines are what you'd destroy
```

Only when the diff confirms nothing is worth keeping: `chezmoi apply --force <tree>`.
Then re-check `chezmoi status <tree>` is clean to confirm the whole tree synced.

## The invariants

- **Never apply over an unexplained ` D`.** Either the removal is intended, or
  the file must first be registered — `chezmoi add <target>` to manage it, or a
  `.chezmoiignore` entry (with a comment naming its owner) to leave it
  unmanaged. A new top-level entry in an `exact_` dir that is neither is one
  apply away from deletion.
- **`--force` only suppresses the prompt; it adds no safety.** The skip was
  chezmoi *protecting* target-side edits — forcing past it discards them. Diff
  first, force last; never as the first reaction to a partial apply.
- **To capture target edits into a templated source, never rely on `re-add`.**
  Hand-port via `chezmoi source-path <target>`, or three-way merge with
  `chezmoi merge <target>`. Verify with `chezmoi diff <target>` afterwards.
- **`exact_` semantics apply per directory level.** Only the dir carrying the
  prefix purges; its non-`exact_` subdirs tolerate unmanaged files — and never
  purge either, so a source file deleted from `exact_dot_claude/rules/` leaves
  the target **orphaned and still loading**, with no ` D` to flag it. After
  removing a rule from source, delete the target yourself:
  `chezmoi source-path ~/.claude/rules/<f> || rm ~/.claude/rules/<f>`.
- **An invalid `.chezmoiignore` pattern aborts the entire run.** A leading `/`
  (`/justfile`) is a fatal parse error that breaks `apply`, `ignored`, and
  `managed` alike, and chezmoi reports only the first offending line. Anchor
  with a bare, slash-free pattern instead — see `chezmoi-conventions.md`.
- **For a file the app rewrites constantly, stop reconciling and manage it with
  a `modify_` script** — chezmoi pipes the current target in on stdin and takes
  the script's stdout as the new target, so a `jq` deep-merge pins only the keys
  you manage and lets everything else pass through.

## In headless sessions

The TTY prompt that fires when a target changed since chezmoi last wrote it
errors out with `could not open a new TTY`. `--force` is the path past it —
but only after `chezmoi diff` confirms no drift will be lost.
