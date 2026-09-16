# A Workflow's Cost Is Its Agent Count — Confirm the Scale Before Fanning Out

Enforced automatically by `hooks-plugin:workflow-scale-guard.sh` (PreToolUse on
`Workflow`, `ask` when the estimated agent count exceeds
`CLAUDE_HOOKS_WORKFLOW_MAX_AGENTS`, default 10). The two shipped mechanisms do
**not** cover this: `workflowSizeGuideline` is advisory system-prompt text that
ends "not a hard limit", and `skipWorkflowUsageWarning` is a **one-time**
acceptance — once set, auto mode never prompts before a workflow again, at any
scale.

Two facts the gate exists to encode, both worth knowing before authoring a
script rather than after:

- **Cost scales with how many agents are created, not with context size.**
  Every fresh agent builds its own prompt cache at 1.25x input price and a
  short-lived one never reads it back. 2026-09-15: 55.2M cache *writes* cost
  $345 while 252.5M cache *reads* cost $126 — trimming prompts optimises the
  cheaper half.
- **The multiplier is agents *per item*, not fan-out presence.** One reviewer
  per changed file is fine. `pipeline(units, edit, review, repair, re-review)`
  is 4x an unknown N; that shape across five runs produced 496 subagents
  against a guideline of 10, and $528 in an afternoon.

- **Group by theme, not by item, when the work is per-file.** The same 43-file
  documentation sweep ran twice on 2026-09-16: one editor plus one reviewer per
  file (138 agents, 13.8M subagent tokens, 49 of them killed by the usage limit
  before reviewing anything), then seven editors each owning a themed group of
  5–11 files (7 agents, 1.93M tokens, zero failures). Same findings, same refs,
  same gates — an eighth of the cost. Per-item fan-out buys isolation you rarely
  need, and the reviewer half is cheaper as one deterministic gate (pre-commit,
  a scripted link check, reading the diff) than as N agents.

**A long run has to survive the usage limit, because resume will not.** When the
limit lands mid-run the session id changes, and `resumeFromRunId` then looks for
the journal under the *new* session directory and reports nothing to resume —
observed 2026-09-16 on two runs whose journals sat intact under the old id. Design
for re-driving rather than resuming: have agents write output to disk as they go,
keep each phase independently runnable, and record what completed so a
replacement run can skip it. The 66 edits that survived that limit did so because
they were already on disk; only the review phase had to be re-driven.

State the expected agent count when proposing a workflow, and cap the fan-out
where the list is produced (`.slice(0, N)` — the guard reads an explicit cap as
the bound). A run large enough to trip the gate is Lauri's call, not Claude's:
never raise the limit to clear your own prompt.
