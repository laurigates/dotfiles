# Stacked PR Merge Order

When PR B is based on PR A's branch (a *stack*), the merge order and the
base-branch deletion interact in a way that silently destroys PR B. Merge
the base, delete its branch, and GitHub **auto-closes** the stacked child —
it does **not** retarget it to `main`. Worse, a closed PR whose base branch
no longer exists **cannot be reopened** (`reopenPullRequest` fails, and
`updatePullRequest` refuses to change the base of a closed PR). The child's
work isn't lost (the head branch survives), but the PR, its review thread,
and its comments are stranded.

## The trap

```
PR A: feature-a   → base main
PR B: feature-b   → base feature-a      (stacked on A)

# squash-merge A, delete feature-a branch
gh pr merge A --squash --delete-branch
#   → GitHub auto-CLOSES PR B (does not retarget to main)
#   → gh pr edit B --base main      → "Cannot change the base branch of a closed pull request"
#   → gh pr reopen B                → "Could not open the pull request" (base branch gone)
```

This bit a real two-PR docs stack (FVH infrastructure #2031 → #2032, 2026-06):
#2032 auto-closed on #2031's merge and had to be reopened as a fresh PR
#2033.

## The rule

**Retarget the child PR to `main` *before* merging and deleting the base
PR's branch.** A child whose base is already `main` survives the base
branch's deletion untouched.

Clean sequence for a two-PR stack (squash-merge, the common org default):

```
# 1. Retarget the child to main FIRST (while the base PR is still open)
gh pr edit <child> --base main

# 2. Merge the base PR and delete its branch
gh pr merge <base> --squash --delete-branch

# 3. Rebase the child's head onto the new main, dropping the now-merged
#    base commits (squash put them on main as one commit, so the child's
#    copies are redundant). --onto <old-base-tip> replays only the child's
#    own commits:
git fetch origin
git rebase --onto origin/main <old-base-branch-tip-sha> <child-branch>
git push --force-with-lease origin <child-branch>

# 4. Merge the child
gh pr merge <child> --squash --delete-branch
```

Step 3 matters specifically for **squash** merges: squashing the base
collapses its commits into one new commit on `main` with a different SHA, so
the child still carries the originals in its history. Rebasing `--onto
origin/main <old-base-tip>` replays *only* the child's own commits and drops
the duplicates cleanly. (With a **rebase**-merge of the base instead, the
base commits keep their patch-ids and a plain `git rebase origin/main` on the
child auto-skips them — but squash is the more common default, so assume the
`--onto` form.)

## If the child already got auto-closed

The head branch still exists, so recover by re-creating the PR rather than
fighting the closed one:

```
git fetch origin
git rebase --onto origin/main <old-base-tip> <child-branch>   # drop merged base commits
git push --force-with-lease origin <child-branch>
gh pr create --base main --head <child-branch> ...            # fresh PR
gh pr comment <closed-child> --body "Superseded by #<new> (auto-closed when the stacked base branch was deleted)."
```

## When this bites

- Any two-or-more-deep PR stack where the base merges first — the default
  flow.
- Especially with **squash** or **rebase** merges plus branch
  auto-deletion (`delete_branch_on_merge` on the repo, or
  `--delete-branch`), which is the norm on release-please / conventional-commit
  repos.

## Rationale

The failure is invisible at merge time — `gh pr merge` reports success, and
the stacked PR's closure is a side effect you only notice when you go to
merge it. One pre-merge `gh pr edit <child> --base main` removes the whole
class of problem; everything after is a normal rebase.
