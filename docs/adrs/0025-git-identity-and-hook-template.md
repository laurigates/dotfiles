---
id: ADR-0025
status: Accepted
created: 2026-11-11
modified: 2026-11-11
deciders: "Lauri Gates"
domain: git-config
relates-to: [ADR-0015]
---

# ADR-0025: Git Identity by Location and Hooks from a Template Directory

## Context

Two pieces of per-repository git setup depended on remembering to do them after
every clone.

- **Identity.** The global git identity is the work one. Personal repositories
  inherited it unless `git config user.email` was run in each.
- **Hooks.** A repository's pre-commit hooks run only after
  `pre-commit install`. A fresh clone skipped them silently, including the
  gitleaks hook from ADR-0015.

The global git config cannot be a chezmoi template. `gh auth` writes credential
helper blocks into it at run time, and a template is authoritative for the
whole file, so it would overwrite or delete them.

Derived from commits 9e73e47 (#291, 2026-06-30), 4c54ae4 (#299, 2026-07-03) and
0de4b16 (#437, 2026-09-23).

## Decision

Both are configured once, globally, by scripts that add to the git config
without owning the file.

- **Identity by location.** `includeIf "gitdir:…"` rules select the personal
  identity for repositories under the personal locations, this dotfiles
  checkout among them. Every other location keeps the default work identity.
  The personal identity lives in a managed include file,
  `private_dot_config/git/personal.inc`. `run_onchange_after_10-git-identity.sh`
  adds the `includeIf` rules with `git config --global`.
- **Hooks from a template directory.** The initial-setup script runs
  `pre-commit init-templatedir` and sets `init.templateDir`, so every later
  `git clone` and `git init` copies the `pre-commit` and `commit-msg` hooks into
  `.git/hooks`. The template hooks do nothing in a repository that has no
  `.pre-commit-config.yaml`.
- **Test.** `tests/test-git-identity.sh` runs the identity script under a
  scratch `HOME` and checks which file it writes and which identity each
  location resolves. It runs as a pre-commit hook and therefore in CI.

`git config --global` writes `~/.gitconfig` unless that file is absent and
`$XDG_CONFIG_HOME/git/config` exists, so the rules land in `~/.gitconfig` on a
fresh machine.

## Consequences

### Positive

- A new clone gets the right author and working hooks with no manual step.
- The additive writes leave the credential helpers that `gh auth` manages in
  place.
- The identity rules are covered by a test that runs in CI.

### Negative

- Identity depends on where a repository is cloned. A personal repository
  cloned outside the listed locations commits under the work identity.
- The template directory applies only to clones made after it was set.
  Existing clones still need `pre-commit install`.
- The script adds rules and does not remove ones dropped from it later.

## Options Considered

### Option 1: `includeIf` rules and a template directory, written by additive scripts (chosen)

**Pros:** automatic for new clones; leaves the rest of the git config alone.
**Cons:** location-based; scripted state can outlive its source.

### Option 2: Manage the git config as a chezmoi template

**Pros:** fully declarative. **Cons:** the template would own the whole file.
**Rejected because:** it would overwrite the credential helper blocks that
`gh auth` writes.

### Option 3: Per-repository `git config` and `pre-commit install`

**Pros:** explicit per repository. **Cons:** depends on remembering both after
every clone. **Rejected because:** forgetting either one produces no error.

## Related ADRs

- [ADR-0015: Gitleaks for Secret Detection](0015-gitleaks-secret-detection.md) — the template directory is what makes its pre-commit hook run in fresh clones.
