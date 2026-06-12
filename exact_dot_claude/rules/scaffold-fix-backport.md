# Back-Port Instance Fixes Into Their Scaffold/Generator

When fixing something that was *generated* — a site scaffolded by a
justfile recipe, a repo from a cookiecutter template, a config from a
`new-*` skill — check whether the bug came from the generator, and if
so, fix the generator **in the same sweep**. A fix applied only to the
deployed instance leaves every future generation broken in the same
way, and the gap is invisible until the next person scaffolds.

## The failure mode

Canonical case (FVH `sites` monorepo, 2026-06): two PRs fixed the
deployed `example-static` site — `service.targetPort: 8080` for the
non-root nginx image, numeric `runAsUser` for Kyverno — but the
`just new-site` template that had produced those broken values was
never touched. Every subsequently scaffolded site would have shipped
with chart-default port-80 probes against an 8080 listener: pod never
Ready, stuck `Progressing`, no error anywhere. Found and back-ported
only weeks later during a readiness audit (sites#11).

The shape is always the same:

1. An instance misbehaves; someone fixes the instance. PR merges, done.
2. The generator still emits the pre-fix content.
3. The next generation reproduces the bug — often for someone without
   the context of fix #1.

## The rule

- **When fixing a generated artifact**, ask: "did the generator produce
  this bug?" If yes, patch the generator template in the same PR (or an
  immediately linked one) — not as a someday follow-up.
- **When reviewing a fix to a known-scaffolded file** (e.g.
  `deploy/values.yaml` in a monorepo with a `new-*` recipe, anything
  under a directory a cookiecutter emits), check the template for the
  same defect before approving.
- **When auditing a scaffold for readiness**, diff the template's output
  against the oldest working instance — accumulated instance-only fixes
  show up as the delta.

## Where generators hide

- justfile `new-*` recipes with heredoc templates
- `cookiecutter/` directories and copier templates
- Claude skills that scaffold (`*-scaffold`, `configure-*`)
- "Copy the example app" docs — the example *is* the generator; fixes to
  forks of it don't propagate back

## Verify

After back-porting, generate a throwaway instance and diff it against
the fixed real instance — the relevant blocks should match:

```
just new-site zz-smoke-test
diff <(yq ... sites/zz-smoke-test/deploy/values.yaml) <(yq ... sites/example-static/deploy/values.yaml)
```

Clean up the throwaway (including any registry/config files the recipe
mutated) before committing.

## Rationale

This is DRY applied to provenance: the template is the source of truth
for new instances, so a fix that skips it creates a silently diverging
copy. The cost asymmetry is stark — back-porting at fix time is one
extra edit with full context in hand; discovering it later costs a
broken deploy, a re-diagnosis from scratch, and usually a different
person's afternoon.
