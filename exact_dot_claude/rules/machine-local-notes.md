# Machine-Local Notes Hold Environment Facts, Not Findings

A `CLAUDE.local.md` is git-ignored, so nothing reviews it — no diff, no PR, no
CI — while it loads on every turn. It rots two ways: session findings get
written there instead of in the ADR/roadmap/issue, and environment facts go
stale with nothing to catch them.

The keep test, one question per claim: **does this describe the machine, or the
project?** Host, paths, toolkit versions, staged assets, and local gotchas that
change how you invoke things — keep. Measurements, root-cause narratives,
blocker status, decisions — those belong in the versioned docs; the local file
gets at most a pointer. Numbers split the same way: a 24 GB card is environment,
a run's peak VRAM is a result.

Promoted to a skill: invoke `agent-patterns-plugin:meta-local-notes` before
trimming a machine-local notes file — it carries the live-probe checklist
(including the perf-commit check that catches a still-plausible claim the
project already fixed), the holds/drifted/superseded verdict table, and the
correct-don't-delete rule.
