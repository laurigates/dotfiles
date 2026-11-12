# Chezmoi Conventions — full detail

Reference companion to [`.claude/rules/chezmoi-conventions.md`](../.claude/rules/chezmoi-conventions.md),
which carries the invariants. This file holds the examples, tables, and
incident narratives behind three of its sections.

The rule is path-scoped to most of the chezmoi source tree, so it loads on
nearly every edit in this repo. The sections below were moved out of it
unchanged (#581) so that an ordinary edit loads the invariants only.

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
# → ~/.local/share/chezmoi/exact_dot_claude/exact_rules/security.md

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
repo-meta file so it stays repo-local. The pattern must be **root-anchored**
so it only catches the source-root copy, not managed nested targets of the
same basename — and the way to write that is a **bare, slash-free** pattern:

```
# .chezmoiignore — root-anchored, won't touch ~/.config/just/justfile etc.
justfile
```

### A leading `/` is NOT how you anchor — it's a hard error

The obvious-looking `/justfile` is **invalid**. chezmoi matches patterns
against the target path *relative* to the destination dir, so a leading
slash makes the path absolute — outside the destination — and chezmoi
aborts the whole run on it:

```
chezmoi: /path/to/source/.chezmoiignore:9: /justfile: invalid path
```

That error is **fatal and total**: `apply`, `ignored`, `managed` all refuse
to run, and chezmoi reports only the *first* offending line, so a file with
several absolute patterns looks like it has one problem. Older chezmoi
tolerated the form silently; ≥2.72 rejects it. This broke the repo's CI for
two weeks in 2026-08 — the `Build (Ubuntu)` job died at `chezmoi apply`
while every other check stayed green, because CI installed chezmoi unpinned
(`brew install chezmoi`) and a release changed the rule underneath it. CI now
takes chezmoi from the repo-root `.mise.toml` pin (#418).

The same applies to `.chezmoiremove`. There, a path genuinely outside `$HOME`
(e.g. `/tmp/some.log`) is not expressible at all — `.chezmoiremove` can only
name targets under the destination dir. Delete such an entry rather than
"fixing" the slash: `tmp/some.log` silently re-points it at `~/tmp/some.log`,
a different file.

Anchoring semantics, verified against chezmoi v2.72.0:

| Pattern | Matches | Use for |
|---|---|---|
| `justfile` | source-root `justfile` **only** — `.config/just/justfile` stays managed | root-anchored ignore ✅ |
| `/justfile` | nothing — **fatal parse error** | never ❌ |
| `**/justfile` | *every* `justfile` at any depth, including the managed global one | deliberate recursion only (e.g. `**/__pycache__/`) |

Directory patterns follow the same rule: `docs/` ignores only the root
`docs/`, leaving `~/.config/nvim/docs/` managed.

Verify it's no longer a target, then remove the already-leaked copy:

```
chezmoi ignored | grep -x justfile && rm -f ~/justfile
```

A `.chezmoiremove` line cannot do that `rm` for you: chezmoi never removes a
target that `.chezmoiignore` lists. `tests/test-chezmoi-root-meta.sh` (`mise run
test:chezmoi-root-meta`) fails when a new plain-named source-root file reaches
`chezmoi managed`; add it to `.chezmoiignore`, or to the test's allowlist if it
really belongs in `$HOME` (#442).

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
