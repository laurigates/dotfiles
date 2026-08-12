# Git Hazards — Verify the Content, Not the Exit Code

Six local-git traps, one law: **a green git command is not proof the result is
correct** — exit 0 is a claim about mechanics, not content. Each: the trap, the
5-second check, the fix. Sibling: `pr-merge-hazards.md` (GitHub PR/merge).

## 1. Commits added after a squash-merge are orphaned

Anything committed to a branch **after** its squash-merge is in neither `main`
nor the squash commit. A fresh branch off `origin/main` silently lacks that
work; the first symptom is an ImportError far downstream.

- **Check** before follow-up work: `git grep <symbol> origin/main -- <path>` —
  don't trust "the PR merged".
- **Fix**: replay only the orphans: `git rebase --onto origin/main <squash-point> <branch>`,
  then verify `git log --oneline origin/main..HEAD` shows only the orphaned + new commits.

## 2. Unpushed commits on local `main` ride into new branches

Branching off local `main` inherits whatever it is ahead of `origin/main` by;
the PR then bundles stray commits under an unrelated title (squash hides it —
visible only in the file list).

- **Rule**: cut PR branches from the remote, always:
  `git fetch origin && git switch -c <branch> origin/main`.
- **Check** when unsure: `git log --oneline origin/main..main` — empty means clean.

## 3. A clean textual merge can duplicate identical additions

When two branches each add the **same** helper/import/enum arm in non-adjacent
spots, `git merge` sees no overlapping hunk, reports success, and keeps **both
copies** — a duplicate-definition build break (or worse, silent shadowing in
lax languages).

- **Check**: build/test the merged tree before committing the merge; when
  siblings solved related problems, `grep -c '<symbol>' <file>` — expect 1.
- **Fix**: hand-resolve to a single combined definition; never trust
  "Automatic merge went well" as a verdict on content.

## 4. `git add` aborts atomically on a bad pathspec

`git add fileA nonexistent` stages **nothing** — not "fileA plus a warning".
Classic trip: `git mv old new`, edit `new`, then `git add new old` → the stale
`old` aborts the add, and the commit ships the rename with pre-edit content.

- **Rules**: one pathspec per `git add`, or only confirmed-present paths.
  After `git mv` + edit, `git add <newname>` alone.
- **Check**: `git status --short` before committing — the index column must
  show the change you intend.
- **Recovery**: the edit is still unstaged in the working tree; add and
  commit/amend — don't redo the work.

## 5. A "vanished" staged file in a shared checkout was probably committed by a coworker

Sibling of the HEAD race in `pr-merge-hazards.md` #3: the **index and HEAD are
process-global**, so a coworker session's commit lands between two of your Bash
calls with no warning. Observed 2026-07 (dotfiles): a file another session had
staged (`A `) disappeared from `git status`, then `ls` said it didn't exist,
then status flapped `A ` → `M ` across consecutive calls. The wrong theory
("pre-commit's stash dance ate it") was nearly acted on; the truth was the
coworker had committed the file to `main` mid-flight — every observation was a
stale read of state the coworker kept moving.

- **Check first, before any recovery**: `git log --oneline -3` — did HEAD
  move? — and `git log -1 -- <path>`; a fresh commit touching the path is the
  discriminator between "lost" and "landed".
- **Don't blind-restore.** Re-adding your own copy of a "lost" file can
  silently **downgrade** the coworker's version (observed: the restored copy
  lacked frontmatter the coworker had added before committing). Diff your
  candidate against `HEAD:<path>` and keep the committed version unless yours
  is genuinely newer.
- **Status flapping between consecutive calls is itself the tell** that a
  coworker is active — stop mutating shared state (index, HEAD, branch
  switches) until the flapping stops; re-read state fresh in the same command
  that acts on it (same instinct as push-by-SHA).

## 6. Work destroyed by `reset --hard` is often still in a pre-commit stash

Unstaged content has no reflog entry, so this looks unrecoverable — but
`pre-commit` stashes unstaged changes around every run, and those stash
**commits** go dangling and survive until `gc`.

- **Prevent**: `git status` before `reset --hard`/`checkout`/`restore`/`clean`;
  `git stash -u` anything present.
- **Recover**: `git fsck --lost-found`, then per dangling *commit* (not blob)
  `git show <c>:<path>`; rank by `git diff --numstat HEAD <c> -- <path>`
  against the diff shape you remember.
