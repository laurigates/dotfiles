# Agent and Tool Selection

## Use Plugin-Qualified Agent IDs

When invoking `Agent` or `Task`, use the fully-qualified `plugin:agent` form
shown in the system prompt's agent list (`agents-plugin:security-audit`, never
bare `security-audit`). The bare form is only correct for agents defined at the
user or project level (`~/.claude/agents/`, `.claude/agents/`); otherwise it
fails with `Agent type 'X' not found`. If the expected agent is missing from
the session's list, fall back to a different agent or direct tool use rather
than guessing a name.

## Always Use Opus for Subagents and Agent Teams

Every spawned subagent and every member of an agent team **must run on Opus**.
Opus 4.8 on *low* effort beats Sonnet 4.6 on *high* effort on both quality and
token efficiency, so a smaller model is never the right call — and because a
subagent's output feeds back into the main loop as a tool result, a weaker
delegate quietly degrades everything downstream. "Save tokens with Sonnet" is
a false economy.

- **Model**: always `opus`. Never pass `model: "sonnet"` / `"haiku"` to the
  `Agent` / `Task` tools, to `agent()`/`opts.model` in `Workflow` scripts, or
  to per-phase `model` overrides. When a teammate or workflow agent would
  otherwise inherit a non-Opus session model, set `model: "opus"` explicitly.
- **Effort**: free to dial down. `low` or `medium` is fine — and preferred —
  for most delegated tasks; reserve `high` for genuinely hard reasoning. The
  effort knob, not the model knob, is the lever for cost.
- **Remove Sonnet suggestions on sight** in any agent definition, workflow,
  skill, or rule.

### Sanctioned exception: cold-read gates run on Haiku

The `agent-patterns-plugin:cold-read-gate` pattern deliberately uses
`model: "haiku"` for its isolated fresh-reader critics. That agent is not a
delegate producing work — it is the **measurement instrument**: the test is
"can a **low-context** reader act on this text alone?", and a stronger model
(or one carrying session context) would answer an easier question. Do not
"fix" haiku cold readers to Opus.

What licenses it is a one-way inference — *if haiku can act on it, a busy
maintainer can* — over an output that is **self-report about the reader's own
comprehension**. Text-unclear and model-weak then prescribe the same cheap fix,
so weakness is the variable being set, not a confound.

Neither property survives once the reader emits **judgments, verdicts, or
evidence-bearing findings — audience-simulation personas included**. There no
one-way inference exists: a weak reader's enthusiasm bounds nothing about a
human's, and its mistakes arrive well-formed and indistinguishable from real
findings. Run those on Opus, or a non-Claude model via PAL. Enforce
"low-context" by **slicing the input** (stage a tier, cut the file), never by
weakening the model — impatience is a budget constraint, not a model one.
**Budget belongs to the harness; capability belongs to the model.**

> Observed (loractl#222): a haiku "drive-by" persona licensed by this carve-out
> asserted ADR *contents* from filenames it had only seen listed, returned 4/5
> YES on a 60-line read, and was discarded at a 67% evidence-drop rate. Not one
> failure was a *comprehension* failure — abstention, calibration and resisting
> a prior all sit above it, so the capability floor produced the noise rather
> than the measurement.

Any agent that edits, verifies facts, or returns analysis the main loop builds
on stays on Opus.
