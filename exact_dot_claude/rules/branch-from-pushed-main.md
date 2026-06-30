# Push/Stash Stray `main` Commits Before Branching — Else They Ride Into the PR

When you cut a feature branch off local `main`, **any commits sitting unpushed
on `main` come with it**. The branch starts at `main`'s tip, so a later
`gh pr create --base main` diffs your branch against *origin*'s `main` — which
doesn't have those stray commits — and the PR bundles them in alongside your
intended change. On a squash-merge repo the squash then collapses *both* the
stray commits and your real work into one commit on `origin/main`, landing the
strays under an unrelated PR title. The PR shows more files than you changed,
and the provenance is wrong.

The failure is invisible at branch-create time: `git switch -c feat origin/main`
*would* be clean, but `git switch -c feat` (off the local tip) silently inherits
whatever local `main` is ahead by.

## The trap (real: dotfiles PR #288, 2026-06)

Local `main` carried one **unpushed** commit (`a2f93f5`, an unrelated rule).
A feature branch cut from `main` therefore contained `a2f93f5` + the real
justfile change. The PR's squash (`1bcbe83`) bundled **three files** — the
stray rule plus the two intended files — under the justfile PR's title.
Harmless here (the rule needed to land anyway), but the diff and the commit
message disagreed about what the PR was. The SessionStart hook had even warned
"unpushed commits"; the miss was not checking `git log origin/main..main`
before branching.

## The rule

Before `git switch -c <branch>` for new PR work, confirm local `main` isn't
ahead of its remote — and if it is, deal with the strays first:

```sh
git log --oneline origin/main..main      # empty == clean to branch from
```

- **Empty** → branch normally.
- **Non-empty** → either push the strays first (`git push origin main`, if they
  belong on `main`), or branch explicitly from the remote so they don't ride
  along: `git switch -c <branch> origin/main`. Uncommitted working-tree edits
  are not a problem (they don't get committed by branching) — only *committed*
  unpushed commits do.

The robust habit is to **always branch from `origin/main`** for fresh PR work:
`git fetch origin && git switch -c <branch> origin/main`. That makes the PR diff
exactly your commits regardless of local `main`'s state.

## When it bites

- Long-lived local `main` that accumulates the occasional direct commit before
  it's pushed (docs tweaks, rule additions).
- Squash-merge repos especially — the squash hides the bundling inside one
  commit, so it's only visible in the file list, not the history.

## Relationship to sibling rules

- `squash-merge-orphans-post-merge-commits.md` — the *mirror* case: commits
  added to a branch *after* its squash-merge are orphaned, not bundled.
- `branch-merge-detection.md` — `git log origin/main..main` is the same
  ancestry-aware check used there to reason about what a branch actually carries.
- `git-add-atomic-pathspec.md`, `stacked-pr-merge-order.md` — kin: the diff /
  merge result is not what a green command implies; verify the *content* landed.

## Rationale

"My branch has my change" and "my branch has *only* my change" are different
claims whenever local `main` is ahead of origin. One `git log origin/main..main`
(or just branching from `origin/main`) before cutting the branch converts a
mislabeled PR — caught later in the file list, or after merge — into a
five-second pre-flight check.
