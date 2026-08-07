---
paths:
  - "**/renovate.json"
  - "**/renovate.json5"
  - "**/.renovaterc*"
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/.github/workflows/*.yml"
  - "**/.github/workflows/*.yaml"
  - "**/skaffold.yaml"
  - "**/.pre-commit-config.yaml"
  - "**/nginx.conf"
---

# Verify a Config Change With the Tool's Own Dry Run, Not by Reading It

Reading a config and reasoning about what it *will* do substitutes your model
of the tool for the tool. Most config-driven tools will report their resolved
behaviour without acting — `renovate --platform=local --dry-run=full`,
`terraform plan`, `kubectl --dry-run=server`, `nginx -T`, `helm template`,
`pre-commit run --all-files`, a linter's `--print-config`.

> Run it **twice — before and after your change — and diff the outcome**, not
> the config.

That turns "I believe this rule now matches X" into "X moved from group A to
group B": checkable, and quotable in a PR.

## The three ways this goes wrong

- **A stale baseline invents differences.** The "before" run must come from the
  *current* tree with only the config reverted — check the old config out into
  the working tree rather than reusing a run captured earlier. A baseline taken
  before unrelated merges attributes their effects to your change. If a diff
  shows changes you cannot explain mechanically, suspect the baseline before
  believing the finding.
- **Proximity parsing over a big log fabricates hits.** Grepping a debug log
  for "the branch name near my package" will happily report a neighbouring
  entry as yours. Prefer whole-output equality (branch sets, plan resource
  counts, sorted dep lists) over windowed heuristics.
- **A validator's silence is not behavioural proof.** "Config validated
  successfully" says the schema parsed, not that grouping/matching changed the
  way you intended. Validate *and* dry-run.

> Evidence (2026-08, thelma): a renovate rule matched `^@radix-ui/`, which does
> not match the unscoped `radix-ui` meta-package — so it rode in a 38-package
> "all non-major" PR and smuggled a breaking minor. The fix was verified by
> running renovate's own dry run against the old and new config on one tree:
> `radix-ui` moved `renovate/all-minor-patch` → `renovate/radix-ui`, and a
> disabled `overrides` pin disappeared from the update list. A first attempt at
> the comparison was confounded — its baseline predated two merges — and had to
> be redone.

## Related

- `diagnose-at-the-failure-point.md` — the same law after the fact: measure,
  don't argue. This is the *before*-the-fact half.
- `offload-to-deterministic-substrate.md` — let the tool compute the answer
  rather than re-deriving it in the agent's head.
- `never-fabricate-test-identifiers.md` — the known-good control; a confounded
  baseline is that control, broken.
