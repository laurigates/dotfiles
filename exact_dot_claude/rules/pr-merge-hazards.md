# PR & Merge Hazards — Exit 0 Is a Claim About Mechanics

Promoted to a skill: invoke `git-plugin:git-merge-hazards` before merging a PR
or a chain of PRs, auditing whether a branch really landed, or merging over red
CI. Sibling: `git-hazards.md` (local git).

Two gates stay inline: both are read *while* the decision is being made, so
there is no earlier moment at which to invoke a skill. They are reproduced
verbatim from the skill body — edit both copies together.

## Is this branch merged? — checks in order of authority

- `gh pr list --state all --head <branch> --json state` → a MERGED PR is
  **authoritative**. Reach for this first; the git-side checks below are all
  one-way.
- `git cherry main <branch>` → marks a commit `-` when a patch-equivalent
  commit is already upstream, `+` when it is not. Survives squash **and**
  cherry-pick, and does not care that `main` drifted.
- `git merge-tree --write-tree main <branch>` equals `git rev-parse main^{tree}`
  → contained. **A match proves containment; a non-match proves nothing.**
- A non-match is "review", **not** proof of unmerged — don't force the count to zero.

## A red PR may still be mergeable — `UNSTABLE` is not `BLOCKED`

`mergeStateStatus` separates **required** failing checks (`BLOCKED` — merge
refused) from merely-present ones (`UNSTABLE` — plain `gh pr merge` works), so
`--admin` on an `UNSTABLE` PR takes a privilege you didn't need. Read it first.

Merging over red needs **two** checks: `--json files` (config/docs can't break
a compile) **and** the same check already failing on `main`. Either alone is a
guess — and a stale-green `main` lies, so check `createdAt` (2026-07: a "green"
run was 21 days old; main hadn't compiled for three weeks).
