# `git add` Aborts Atomically on a Bad Pathspec

`git add fileA nonexistent` does **not** add `fileA` and warn about the
missing path. It **fails the whole command** with
`fatal: pathspec 'nonexistent' did not match any files` and **stages
nothing** — `fileA`'s changes are silently left unstaged. The non-zero
exit is the only signal; if you don't check it (or it scrolls past), the
next `git commit` captures whatever was *already* staged and omits the
edit you thought you'd just added.

## How it bites

The classic trip: a `git mv old new` stages the **rename of the old
content**, then you Edit `new`, then `git add new old` — the stale `old`
pathspec aborts the add, so the Edit never stages, and the commit ships
the rename with the **pre-edit content**. The failure is invisible until
something downstream (a branch switch refusing "local changes", a PR diff
that's missing the change) surfaces it.

Observed 2026-06 in the dotfiles repo: a `dot_taskrc` → `.tmpl` conversion
committed the rename only; the templating body was lost because
`git add dot_taskrc.tmpl dot_taskrc` aborted on the already-renamed
`dot_taskrc`.

## Rules

- **Add one pathspec per call**, or only paths you've confirmed exist.
  Never tack a "just in case" path onto a `git add` — one bad entry voids
  the whole command.
- **After `git mv` + Edit, `git add <newname>` alone.** The rename is
  already staged; you only need to stage the content edit. Don't re-list
  the old name.
- **Check `git status --short` before `git commit`.** The index column
  (first char) must show the change you intend. An `R`/`M` split where you
  expected a single staged edit means the content add didn't land —
  re-stage before committing.
- **Trust the exit code.** `fatal: pathspec … did not match` means
  *nothing* staged on that call, not "staged the rest." Re-run with the
  correct paths; don't assume partial success.

## Recovery if it already committed

The edit is still in the working tree (it was never staged, so the commit
couldn't include it). `git add <file>` then a follow-up commit — or amend
if the commit is unpushed and yours. Don't re-do the work; the diff is
sitting unstaged.
