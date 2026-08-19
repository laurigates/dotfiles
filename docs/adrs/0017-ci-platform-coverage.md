# ADR-0017: CI Platform Coverage — Test macOS and Ubuntu

**Date**: 2026-08-19
**Status**: Accepted
**Confidence**: High (measured against GitHub billing data and run timings)

## Context

This repository configures a macOS development environment: Homebrew, zsh with
a large `.zshrc`, macOS-specific launchd agents, and completions generated from
locally installed binaries. Ubuntu support exists mainly so the environment can
be bootstrapped on Linux hosts and inside containers.

CI has been Ubuntu-only since 2025-09-15. Commit `a264a61` ("ci: simplify smoke
test workflow", #78) removed `lint-macos` and `build-macos` in the same change
that replaced individual linters with pre-commit and switched shell testing from
zsh to fish, giving as its reason:

> Remove macOS jobs to reduce CI complexity and runtime

Two beliefs accumulated afterwards and were repeated when the decision was
revisited: that macOS runners are expensive, and that they are slow. Both were
checked in 2026-08 and neither holds for this repository.

**Cost.** GitHub bills standard runners at zero for public repositories, macOS
included. `laurigates/dotfiles` is public. Measured rather than inferred, via a
sibling public repo that does run macOS jobs:

```
$ gh api repos/laurigates/kicad-mcp/actions/runs/30608467472/timing --jq .billable
MACOS:  jobs=3  total_ms=0
UBUNTU: jobs=7  total_ms=0
```

The widely cited 10× macOS multiplier applies to private repositories and paid
minutes. It does not apply here. (GitHub's own billing documentation is
ambiguous about whether `macos-latest` counts as a "larger runner", which is
where the belief came from; the billing API is unambiguous.)

**Runtime.** In that same run, macOS jobs queued 2–3 s against Ubuntu's 2–4 s,
and ran 25–33 s against Ubuntu's 22–27 s for the equivalent job — roughly 20%
slower, not an order of magnitude. For comparison, this repository's current
`smoke.yml` runs Linters in 92 s and Build (Ubuntu) in 46 s. The macOS job that
was removed was modest: `brew install chezmoi neovim groff autoconf`,
`chezmoi apply`, and a zsh assertion — not a full `brew bundle install`.

**What Ubuntu-only actually covers.** `Build (Ubuntu)` runs `chezmoi apply`
under Homebrew-on-Linux. That exercises template rendering and catches chezmoi
source-tree errors, but it does not exercise zsh startup on the target platform,
Homebrew formula availability on macOS, completion generation from macOS
binaries, or anything launchd. A regression in those is invisible to CI by
construction. The gap is not hypothetical: PR #367 added zsh completion
behaviour that no Ubuntu job can execute.

The counter-argument is real and was weighed: the MacBook is the daily driver,
so macOS breakage surfaces within hours anyway. That makes macOS CI a
convenience rather than a necessity — but it is a convenience that catches
regressions *before* they land on the machine the author depends on, rather
than after.

## Decision

Test both platforms in CI. `smoke.yml` gains a macOS job alongside the Ubuntu
one, restoring roughly what `a264a61` removed:

- `runs-on: macos-latest`, triggered per pull request like the Ubuntu job
- Homebrew setup with a `Brewfile`-keyed cache
- `brew install` of the bootstrap dependencies only, not `brew bundle install`
- `chezmoi apply -v`
- zsh startup assertions

**Trade-offs considered:**

- *Stay Ubuntu-only, rely on daily driving* — cheapest, and defensible while the
  only reason to change was a belief about cost. Rejected once that belief was
  measured false: the platform the repository exists to configure was the one
  platform never tested.
- *Scheduled macOS run rather than per-PR* — keeps PR feedback at its current
  ~90 s and still catches macOS-only breakage. Rejected because a regression
  found the next morning has usually already been applied to the daily driver,
  which is exactly the failure the job exists to prevent. Worth reconsidering if
  the macOS job's wall clock grows past a few minutes.
- *Full `brew bundle install` on macOS* — maximal coverage, but installs the
  entire Brewfile including casks on every run. Rejected as disproportionate;
  the bootstrap subset catches the failures that matter (formula availability,
  `chezmoi apply`, shell startup).

### Scope limit: live-state tests stay out of CI

`tests/test-gh-completion.sh` is deliberately **not** wired into the macOS job.
It drives a pty against whatever pull requests happen to be open, so its
candidate set is live remote state — green or skipped depending on the day. It
remains a local `mise run test:gh-completion` check. CI runs the tests whose
inputs are in the repository.

## Consequences

**Positive:**

- The target platform is under test. Homebrew formula availability, zsh startup,
  and `chezmoi apply` on macOS all fail visibly in a PR instead of on the daily
  driver.
- No billing impact — the repository is public and standard runners are free.
- The Ubuntu job keeps its distinct value: it is the guard against
  macOS-specific assumptions leaking into paths meant to be cross-platform.

**Negative:**

- PR wall clock grows from ~90 s to an estimated 2–4 min, dominated by
  `brew install` on a cold runner. The `Brewfile`-keyed cache invalidates on
  every Brewfile edit, so Brewfile PRs pay the full cost.
- A second platform is a second source of flakiness. The 2025-09 removal cited
  complexity, and that concern is not disproved by this ADR — only the cost and
  runtime claims were. If the macOS job proves flaky, prefer moving it to a
  schedule over deleting it, so the coverage question stays visible.

**Revisit if:**

- The macOS job's wall clock exceeds ~5 min, or it becomes a recurring source of
  false reds — move to a scheduled run rather than removing it.
- GitHub changes public-repo billing for macOS runners. The check is
  `gh api repos/<owner>/<repo>/actions/runs/<id>/timing --jq .billable`, not the
  documentation.
- The repository stops targeting macOS as its primary platform.

## References

- `a264a61` — the 2025-09-15 commit that removed the macOS jobs
- `.github/workflows/smoke.yml` — the workflow this ADR governs
- ADR-0010 (Tiered Test Execution) — the local test tiers this complements
