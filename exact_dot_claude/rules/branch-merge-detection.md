# Detecting a Merged Branch: `--merged` Misses Squash-Merges

`git branch --merged` (and "is this branch an ancestor of main") only
recognizes branches whose commits are **reachable from `main`** — i.e.
merge-commit or fast-forward merges. A **squash-merge** collapses the
branch into a single new commit on `main` with a fresh SHA, so the
branch's own commits are never ancestors. The branch therefore reads as
**unmerged** even though its work fully landed. On any repo that
squash-merges (the release-please / conventional-commit default), the
ancestry check under-reports merged branches badly — in one cleanup
session it flagged **4 of 28** actually-merged branches as deletable.

Two further traps compound it:

- **"Files identical to main" also fails.** Checking whether the branch's
  changed files match `main` breaks when `main` *drifts* those files after
  the squash (a later PR edits the same file). The branch's work is in
  `main`, but the file no longer matches, so it looks unmerged.
- A merged branch with commits added **after** the squash is genuinely
  partially-unmerged — see `squash-merge-orphans-post-merge-commits.md`.

## The reliable signals

Use either of these instead — both survive squash-merge *and* post-merge
file drift:

1. **`merge-tree` no-op** — merging the branch into the base changes
   nothing, proving its content is already present:
   ```sh
   base_tree=$(git rev-parse main^{tree})
   merged=$(git merge-tree --write-tree main "$branch")   # git ≥ 2.38
   [ "$merged" = "$base_tree" ] && echo "MERGED (contained in main)"
   ```
   A clean result whose tree equals `main`'s tree means the branch
   contributes nothing not already in `main`. (Exit non-zero / a different
   tree means *not provably contained* — which is **not** proof of
   "unmerged"; it can also be a squash where `main` later edited the same
   lines. Treat it as "review", not "delete".)

2. **A MERGED PR for the branch head** — GitHub is authoritative; the
   squash landed the work at merge time regardless of later drift:
   ```sh
   gh pr list --state all --head "$branch" --json state --jq '.[0].state'
   ```

Decision: `merge-tree` no-op **OR** merged PR ⇒ safe to delete; neither ⇒
keep and review (genuine unmerged work or a superseded snapshot).

## Don't hand-roll this — use the recipe

This logic is encoded once in the `branch-audit` justfile recipe
(`private_dot_config/just/git.just`), runnable from any repo:

```sh
just -g branch-audit          # table of MERGED vs REVIEW + a paste-ready `git branch -D`
```

Reach for the recipe rather than re-deriving the check; only drop to the
raw `git merge-tree` / `gh pr list` commands above when auditing a single
branch inline or on a host without the recipe applied.

## When this bites

- Pruning local branches on a squash-merge repo — `git branch --merged`
  and `deadbranch`-style ancestry tools under-report by a wide margin.
- Deciding whether a stale feature branch still carries unmerged work
  before deleting it.

## Rationale

"The PR merged" and "the branch is an ancestor of `main`" are different
claims under squash-merge, and the gap is every squash-merged branch.
A `merge-tree` no-op answers the question the ancestry check was meant to
— *is this branch's content already in `main`?* — deterministically, in
one command, immune to the squash and to later drift.
