---
id: ADR-0024
status: Accepted
created: 2026-11-11
modified: 2026-11-11
deciders: "Lauri Gates"
domain: pr-merging
relates-to: [ADR-0009]
---

# ADR-0024: The PR Decides Its Merge Method

## Context

ADR-0009 depends on conventional commits reaching `main`, because
release-please reads them. Whether a PR should be squashed or rebased depends
on its commits: several independent conventional commits each carry a changelog
entry and should be kept, while a single commit, a branch with fixups or a bot
PR should land as one.

The zsh wrappers offered one command per method, `ghsq` for squash and `ghrb`
for rebase, so the method was whichever command was typed. Both later gained a
prompt when the typed method disagreed with the recommended one, which made
them `ghm` with a forced method. A forced method also left no record on the PR
of why it differed.

Derived from the 2026-10-26 commits "feat(zsh): add ghm, which merges each PR
with its recommended method" and 0f10554 "ci: post the merge-method check and
label on every PR", and from ed5102d (#552, 2026-11-02).

## Decision

The merge method is computed from the PR, shown on the PR, and applied by one
command.

- **Rule.** `git-plugin/scripts/pr-merge-method.py` in claude-plugins decides.
  Two or more independent conventional commits rebase. Everything else
  squashes, including single commits, merge-synced branches, fixups and bot
  PRs.
- **On the PR.** `merge-method.yml` calls the org reusable workflow, which
  posts a non-required `merge-method` check and keeps one `merge:rebase` or
  `merge:squash` label in step with it.
- **Override.** A `merge:*` label applied by a human wins. That is the only way
  to force a method, and it leaves the choice visible on the PR.
- **One command.** `ghm` merges each PR with its own method and asks
  `r`/`s`/`k` when there is neither a script result nor a label. `ghsq` and
  `ghrb` are removed. `ghrp`, for release PRs, keeps its explicit `--squash`.
- **Guard.** A git-plugin hook blocks a `gh pr merge` whose `--squash` or
  `--rebase` flag disagrees with the computed method.

## Consequences

### Positive

- Multi-commit PRs keep their conventional commits for release-please, and
  noisy branches still land as one commit.
- The method is visible on the PR before anyone merges it.
- A batch merge can mix methods, and each conflict is handed off with
  instructions that match its PR's method.

### Negative

- The rule lives in another repository, so changing it means a claude-plugins
  release.
- The picker reads the method from the label, so a PR whose check has not run
  yet shows `?` and needs an answer at merge time.
- Forcing a method takes a label edit where it used to take a different
  command.

## Options Considered

### Option 1: Compute per PR, label it, one merge command (chosen)

**Pros:** the method follows the PR's content; overrides are recorded.
**Cons:** depends on a script and a workflow outside this repository.

### Option 2: Keep one command per method

**Pros:** explicit; no external rule. **Cons:** the method depends on which
command is typed. **Rejected because:** both commands had already become `ghm`
behind a mismatch prompt.

### Option 3: Always squash

**Pros:** simplest; linear history. **Cons:** a PR with several independent
conventional commits loses all but one changelog entry. **Rejected because:**
release-please reads each commit that reaches `main`.

## Related ADRs

- [ADR-0009: Conventional Commits and Release-Please Automation](0009-conventional-commits-release-please.md) — the merge method is chosen to preserve the commits that ADR relies on.
- [ADR-0021: Call Org Reusable Workflows Instead of Local Copies](0021-org-reusable-workflows.md) — the merge-method check is one of its callers.
