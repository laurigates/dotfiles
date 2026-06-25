# Squash-Merge Orphans Commits Added After the Merge

A squash-merge collapses a branch's commits into **one new commit on `main`
with a fresh SHA**. The branch's own commits keep their original SHAs and are
never ancestors of `main`. So any commit you add to that branch *after* the
squash-merge is **orphaned**: its content is in neither `main` nor the squashed
commit. The branch still exists and still looks like it has unmerged work — but
a new branch cut from `origin/main` silently lacks those post-merge commits.

The failure is invisible at branch-create time. You `git switch -c follow-up
origin/main`, write code that depends on a symbol or file you "know" is there
(because you wrote it), and only a test import or a `git grep` reveals `main`
never received it.

## The trap (real: research PR #7 → PR #13, 2026-06)

```
# PR #7 squash-merged an EARLY state of feat/reddit-discovery-curation.
# Two more commits were then added to that same branch:
#   3dd9733  feat: keep reddit content out of the classifier  (adds _is_reddit_sourced)
#   bfc1427  docs: note reddit secrets are gitops-managed
# Neither reached main — the squash predated them.

git switch -c follow-up origin/main        # branch lacks _is_reddit_sourced
# new tests do:  from tag import _is_reddit_sourced   → ImportError on main
git grep _is_reddit_sourced origin/main -- scripts/tag.py   # → nothing. Confirmed orphaned.
```

`gh pr view <branch>` reported PR #7 **merged**, which read as "the branch's
work is in `main`" — but only the *squashed prefix* was. The post-merge commits
were stranded on the (now-redundant-looking) feature branch.

## The rule

**Before branching off `origin/main` for follow-up work, verify `main` actually
contains the code your new work depends on** — don't trust "the PR merged."
Cheap checks, in order:

```sh
git fetch origin
git grep <symbol> origin/main -- <path>          # is the symbol/function there?
git show origin/main:<path> | grep <thing>       # is this file's content there?
git log --oneline origin/main | head             # did the squash land what you think?
```

If the dependency is missing, the work lives in orphaned commits on the old
branch. **Recover by replaying only those commits** onto `origin/main` with
`--onto`, dropping the already-squashed prefix:

```sh
# <squashed-base> = the last commit whose content IS already in main (the squash point)
git rebase --onto origin/main <squashed-base> <your-branch>
git log --oneline origin/main..HEAD              # verify: ONLY the orphaned + new commits
```

This replays the post-merge commits (and your new ones) cleanly. Conflicts here
are expected if `main` advanced past the squash with fixes touching the same
files — resolve by keeping both (the merged fix AND the orphaned change).

## When it bites

- A PR squash-merged while you (or a teammate) kept committing to its branch.
- Resuming a "merged" feature days later and branching fresh off `main`.
- Any follow-up whose tests/imports reference symbols added late on a
  squash-merged branch — the import error is the first signal, far downstream
  of the real cause.

## Relationship to sibling rules

- `stacked-pr-merge-order.md` — the *other* squash hazard: a **stacked child
  PR** auto-closes when its base branch is deleted. Shares the `git rebase
  --onto` recovery mechanic; different trigger (a stack vs. post-merge commits
  on one branch).
- The instinct is the same as `verify-upstream-before-patching.md`: confirm the
  authoritative state (`origin/main`) before acting, rather than trusting a
  proxy signal ("the PR says merged").

## Rationale

"PR merged" and "my branch's full history is in `main`" are different claims
under squash-merge, and the gap is exactly the commits added after the merge.
One `git grep origin/main` before branching converts a silent missing-dependency
hunt (import error → re-diagnosis → `--onto` rebase under time pressure) into a
five-second check.
