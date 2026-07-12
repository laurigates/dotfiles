# Git Hazards — Verify the Content, Not the Exit Code

Seven traps sharing one law: **a green git command is not proof the result is
correct.** "Merge went well", "PR merged", and exit 0 are claims about
mechanics, not content. Each hazard below: the trap, the 5-second check, the
fix. (Consolidated 2026-07 from six separate incident rules; full narratives
are in git history.)

## 1. `--merged` misses squash-merged branches

A squash-merge collapses a branch into one fresh-SHA commit on `main`, so the
branch's own commits are never ancestors — `git branch --merged` (and any
ancestry check) reports it **unmerged**. "Files identical to main" also fails
once `main` drifts the same files.

- **Check**, in order of authority:
  - `gh pr list --state all --head <branch> --json state` → a MERGED PR is
    **authoritative**. Reach for this first; the git-side checks below are all
    one-way.
  - `git cherry main <branch>` → marks a commit `-` when a patch-equivalent
    commit is already upstream, `+` when it is not. Survives squash **and**
    cherry-pick, and does not care that `main` drifted.
  - `git merge-tree --write-tree main <branch>` equals `git rev-parse main^{tree}`
    → contained. **A match proves containment; a non-match proves nothing.**
- **Not immune to drift** (corrected 2026-07): once `main` moves on over the same
  files, merging an already-merged branch back would re-introduce its older
  versions, so the trees differ and merge-tree reports **not contained** for work
  that fully landed. Observed reporting three merged branches as unmerged. Same
  trap as "files identical to main". Use the PR state or `git cherry` to decide;
  keep merge-tree only as a positive-containment shortcut.
- **Fix**: use the encoded recipe rather than re-deriving: `just -g branch-audit`
  (in `private_dot_config/just/git.just`) prints MERGED vs REVIEW + a paste-ready delete.
- A non-match is "review", **not** proof of unmerged — don't force the count to zero.

## 2. Commits added after a squash-merge are orphaned

Anything committed to a branch **after** its squash-merge is in neither `main`
nor the squash commit. A fresh branch off `origin/main` silently lacks that
work; the first symptom is an ImportError far downstream.

- **Check** before follow-up work: `git grep <symbol> origin/main -- <path>` —
  don't trust "the PR merged".
- **Fix**: replay only the orphans: `git rebase --onto origin/main <squash-point> <branch>`,
  then verify `git log --oneline origin/main..HEAD` shows only the orphaned + new commits.

## 3. Merging a stacked base auto-CLOSES the child PR

When PR B is based on PR A's branch, merging A and deleting its branch
auto-closes B (GitHub does **not** retarget it), and a closed PR whose base
branch is gone **cannot be reopened**.

- **Fix — order matters**: retarget the child **first**, while the base PR is open:
  1. `gh pr edit <child> --base main`
  2. `gh pr merge <base> --squash --delete-branch`
  3. `git rebase --onto origin/main <old-base-tip> <child-branch>` (drops the
     already-squashed base commits) + `git push --force-with-lease`
  4. merge the child.
- **If already auto-closed**: the head branch survives — rebase as above,
  `gh pr create` fresh, comment "Superseded by #new" on the closed one.
- **Nothing tells you this happened.** The auto-close is silent: no failed
  check, no notification, and the PR list just looks one shorter. claude-plugins
  #2049 sat stranded for a day; a sweep then found 26 dead branches, two carrying
  work that had **never had a PR opened at all** (so no event ever fired for
  them either). A scheduled sweep is the only thing that finds this class —
  an event handler on `pull_request: closed` is too late by construction (the
  base ref is already deleted, so the reopen window is gone) and is blind to
  never-PR'd branches. `claude-plugins scripts/check-stranded-work.sh` is the
  encoded audit; it takes `--repo`, so one run sweeps the portfolio.
- **Telling an accident from a decision**: a closed-unmerged PR whose base ref
  **404s** was auto-closed; one whose base ref is still **alive** was closed by a
  human (duplicate/superseded). That single check is the discriminator — 11 of
  those 26 branches were deliberate closes and must not be resurrected.

## 4. Unpushed commits on local `main` ride into new branches

Branching off local `main` inherits whatever it is ahead of `origin/main` by;
the PR then bundles stray commits under an unrelated title (squash hides it —
visible only in the file list).

- **Rule**: cut PR branches from the remote, always:
  `git fetch origin && git switch -c <branch> origin/main`.
- **Check** when unsure: `git log --oneline origin/main..main` — empty means clean.

## 5. A clean textual merge can duplicate identical additions

When two branches each add the **same** helper/import/enum arm in non-adjacent
spots, `git merge` sees no overlapping hunk, reports success, and keeps **both
copies** — a duplicate-definition build break (or worse, silent shadowing in
lax languages).

- **Check**: build/test the merged tree before committing the merge; when
  siblings solved related problems, `grep -c '<symbol>' <file>` — expect 1.
- **Fix**: hand-resolve to a single combined definition; never trust
  "Automatic merge went well" as a verdict on content.

## 6. `git add` aborts atomically on a bad pathspec

`git add fileA nonexistent` stages **nothing** — not "fileA plus a warning".
Classic trip: `git mv old new`, edit `new`, then `git add new old` → the stale
`old` aborts the add, and the commit ships the rename with pre-edit content.

- **Rules**: one pathspec per `git add`, or only confirmed-present paths.
  After `git mv` + edit, `git add <newname>` alone.
- **Check**: `git status --short` before committing — the index column must
  show the change you intend.
- **Recovery**: the edit is still unstaged in the working tree; add and
  commit/amend — don't redo the work.

## 7. Stacked-chain merges: push by SHA, never `HEAD:` — and expect auto-close races

Working down a stacked-PR chain (retarget child → merge base → rebase child →
force-push → merge, per #3) has three traps of its own (observed 2026-07,
claude-plugins #1979→#1987):

- **`HEAD:` in a push refspec is a race in a shared checkout.** HEAD is
  process-global repo state; a coworker session can move it *between two of
  your Bash calls*. Observed: rebase left HEAD at the child's new tip; by the
  next call HEAD was `main`'s tip, so `git push --force-with-lease origin
  HEAD:<child-branch>` overwrote the branch with main. Resolve the tip to an
  **explicit SHA in the same command that creates it** and push
  `git push --force-with-lease origin <sha>:<branch>`.
- **An empty-diff force-push auto-closes the PR — and a closed PR whose *head*
  moved after closing cannot be reopened.** Sibling of #3's
  base-branch-deleted variant. GitHub saw the branch == main, closed the PR,
  and refused `gh pr reopen` because the head ref had moved since closing.
- **A single mergeability read after a force-push is a race.** GitHub
  recomputes `mergeable` asynchronously; `gh pr merge` right after a push
  fails with "not mergeable" on a perfectly clean PR. Poll
  `gh pr view <n> --json mergeable` until it leaves `UNKNOWN`.

- **Check** before every force-push: `git log --oneline origin/main..<sha>` —
  expect *exactly* the child's commits, nothing more, never empty.
- **Recovery** when auto-closed: the rebased commits survive in local objects
  (`git reflog`) — `git push --force-with-lease origin <sha>:<branch>`, open a
  fresh PR from the branch, comment "Superseded by #new" on the closed one.
