---
id: ADR-0021
status: Accepted
created: 2026-11-11
modified: 2026-11-11
deciders: "Lauri Gates"
domain: ci-workflows
relates-to: [ADR-0009, ADR-0017]
---

# ADR-0021: Call Org Reusable Workflows Instead of Local Copies

## Context

This repository predates `laurigates/.github`, the repository that holds shared
reusable workflows. It therefore carried its own copies of the Renovate runner,
the Claude PR review and the CI auto-fix workflow. The copies drifted from the
shared versions and each needed its own maintenance. The local PR review
workflow generated an `--allowedTools` list from a preset that was additive and
so restricted nothing (#370).

Renovate also ran twice: a per-repository workflow here and an account-wide
GitHub App. Two runners acting on one repository abort each other's runs.

Derived from commits 1166447 (#369, 2026-08-19), d8d9001 (#370), f603d54 (#438,
2026-09-23), ea995f9 (#511), 9520ed2 (#514) and 0f10554 (2026-10-26).

## Decision

A workflow that the org repository owns is called from here as a thin caller,
not copied. Renovate has one owner, the account-wide App.

- Callers reference `laurigates/.github/.github/workflows/reusable-*.yml` at a
  commit SHA with a `# main` comment. Three are in use:
  `reusable-auto-fix.yml`, `reusable-opencode-review.yml` and
  `reusable-merge-method.yml` (`rg 'uses:.*laurigates/.github' .github/workflows`).
- There is no Renovate workflow in this repository.
  `tests/test-renovate-single-owner.sh` fails when one is added.
- Automatic PR review runs on a free OpenCode model through the reusable
  workflow, as a pilot. The disabled Claude review workflow was deleted;
  `@claude` mentions still work through `claude.yml`.
- Auto-fix runs only for failures started by a human or by Claude, because the
  action refuses other bot actors.
- Workflows that test this repository's own content (`smoke.yml` and the other
  local workflows) stay local.

## Consequences

### Positive

- 299 lines of workflow were replaced by 60 in #370 alone, and a fix to a
  shared workflow reaches every caller.
- One Renovate runner removes the aborted runs.
- Callers pinned to a SHA change only through a reviewed bump.

### Negative

- A reusable workflow's behaviour is defined in another repository, so reading
  a failure means reading two repositories.
- A SHA pin lags the shared workflow until Renovate bumps it.
- Removing the per-repository runner leaves no fallback if the account-wide
  App stops visiting this repository.

## Options Considered

### Option 1: Thin callers of org reusable workflows (chosen)

**Pros:** one implementation to maintain; local files show only the inputs
that differ. **Cons:** an extra repository in the dependency chain.

### Option 2: Keep local copies

**Pros:** self-contained; changes need no second repository. **Cons:** every
fix has to be repeated per repository. **Rejected because:** the copies had
already drifted, and one of them carried a tool restriction that did nothing.

### Option 3: Keep the per-repository Renovate runner alongside the App

**Pros:** a fallback runner. **Cons:** the two abort each other. **Rejected
because:** the abort was observed in the runner's log before #438.

## Related ADRs

- [ADR-0017: CI Platform Coverage](0017-ci-platform-coverage.md) — the smoke workflow it describes stays local under this ADR.
- [ADR-0009: Conventional Commits and Release-Please Automation](0009-conventional-commits-release-please.md) — the merge-method check depends on conventional commits.
- [ADR-0022: Exact CI Toolchain Pins Instead of a Lockfile](0022-exact-ci-toolchain-pins.md) — applies the same SHA pinning to third-party actions.
- [ADR-0024: The PR Decides Its Merge Method](0024-pr-decides-merge-method.md) — the merge-method reusable workflow implements it.
