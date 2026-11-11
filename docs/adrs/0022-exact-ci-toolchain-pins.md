---
id: ADR-0022
status: Accepted
created: 2026-11-11
modified: 2026-11-11
deciders: "Lauri Gates"
domain: ci-toolchain
relates-to: [ADR-0002, ADR-0017, ADR-0021]
---

# ADR-0022: Exact CI Toolchain Pins Instead of a Lockfile

## Context

ADR-0002 listed a committed `mise.lock` as a benefit of adopting mise. The
lockfile was never adopted: none has been committed, and a lockfile for the
global mise config would live in `~/.config/mise/`, outside this repository.
ADR-0002 carries a 2026-10 note saying so.

Without a lock, CI took chezmoi, mise and two third-party actions from whatever
upstream published at run time. `Homebrew/actions/setup-homebrew@main` and
`benchmark-action/github-action-benchmark@v1` were branch references, so a CI
run could change behaviour with no commit in this repository.

Derived from commits d6d19c8 (#449, 2026-09-23), 04c7ccc (#446, 2026-10-17) and
the 2026-10-17 commit "fix(ci): pin the tools CI still resolved at run time".

## Decision

The CI toolchain is pinned to exact versions in tracked files, and a test fails
when a pin is missing. No `mise.lock` is committed.

- The repository-root `.mise.toml` pins chezmoi and shellcheck. CI installs them
  with `jdx/mise-action`, and mise itself is pinned by a `version:` input. The
  Docker smoke image installs the same mise release and reads the same file.
- The global mise config includes the root `.mise.toml`, so every machine runs
  the chezmoi version that CI tested.
- Actions that were referenced by branch are pinned to a release commit SHA
  with a `# <version>` comment.
- `tests/test-ci-pins.sh` runs as a pre-commit hook and in the smoke Linters
  job. It fails on a `mise-action` step with no `version:`, on `setup-python` or
  `setup-bun` with no version input, and on an unpinned tool.
- Renovate proposes each bump. chezmoi bumps arrive as their own PR with
  automerge off. A custom regex manager reads the Homebrew/actions pin, because
  its `YYYY.MM.DD.N` tags have four components and the built-in manager reads
  three.

Tools outside the CI path still float in the global mise config. The 2026-10
note in ADR-0002 lists what is pinned and what is not.

## Consequences

### Positive

- A CI run is reproducible from the commit it ran on.
- A version change is a reviewed PR with its own CI run.
- Local machines and CI agree on the chezmoi version.

### Negative

- Pins are spread over `.mise.toml`, workflow files and the Dockerfile, where a
  lockfile would be one file. The test is what keeps them in step.
- Every upstream release produces a Renovate PR.
- The custom Renovate manager is specific to one dependency's tag format.

## Options Considered

### Option 1: Exact pins in tracked files, enforced by a test (chosen)

**Pros:** works for tools mise does not manage (actions, the Docker image);
the failure names the unpinned step. **Cons:** several files to keep
consistent.

### Option 2: Commit a `mise.lock`

**Pros:** one file; mise's own mechanism. **Cons:** it covers only what mise
installs, and the global config's lock would sit outside the repository.
**Rejected because:** the branch-referenced actions and the mise version itself
would stay unpinned.

### Option 3: Leave CI floating

**Pros:** always the newest tools; no bump PRs. **Cons:** CI can break or
change with no commit here. **Rejected because:** a failure could not be
traced to a change in this repository.

## Related ADRs

- [ADR-0002: Unified Tool Version Management with Mise](0002-unified-tool-version-management-mise.md) — this ADR replaces the lockfile that ADR-0002 expected.
- [ADR-0017: CI Platform Coverage](0017-ci-platform-coverage.md) — the pinned toolchain runs in the jobs it defines.
- [ADR-0021: Call Org Reusable Workflows Instead of Local Copies](0021-org-reusable-workflows.md) — reusable workflow callers are pinned to SHAs in the same way.
