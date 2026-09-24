# Diagnose at the Failure Point — Sentinel Values and the Resource Reading

Promoted to a skill: invoke `code-quality-plugin:debugging-methodology` when an
error names a zero/default entity or reports resource exhaustion — it carries
the sentinel-value and resource-reading sections, the per-symptom table, and
the cubecl canonical break.

- **An error naming a zero/default identifier** (`page 0`, `id 0`, `index -1`,
  a null UUID): verify its identifier came from a real success before
  theorizing on the entity.
- **Any exhaustion symptom** (OOM, `ENOSPC`, `EMFILE`, pool full): read the
  actual resource at the failing call site, not from an earlier sample.
- **An inherited root cause** (a handoff issue, an upstream tracker, a
  maintainer's diagnosis) is an input to verify, not a conclusion. When a
  theory and a measurement disagree, re-diagnose.
