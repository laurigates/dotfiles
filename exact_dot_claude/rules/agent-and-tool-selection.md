# Agent and Tool Selection

## Use Plugin-Qualified Agent IDs

When invoking `Agent` or `Task`, use the fully-qualified `plugin:agent` form
shown in the system prompt's agent list (`agents-plugin:security-audit`, never
bare `security-audit`). The bare form is only correct for agents defined at the
user or project level (`~/.claude/agents/`, `.claude/agents/`); otherwise it
fails with `Agent type 'X' not found`. If the expected agent is missing from
the session's list, fall back to a different agent or direct tool use rather
than guessing a name.

## Opus Is the Floor for Subagents and Agent Teams

Every spawned subagent and every member of an agent team runs on Opus or
better — a delegate's output feeds back into the main loop as a tool result,
so a weaker model quietly degrades everything downstream. Opus 4.8 at *low*
effort beat Sonnet 4.6 at *high* effort on both quality and token efficiency
(aliases now resolve to Opus 5 / Sonnet 5 — re-verify per pair); "save
tokens with Sonnet" is a false economy.

- **Model**: `opus` is the floor, never `"sonnet"`/`"haiku"`, for any
  delegate that edits, verifies facts, or returns analysis the main loop
  builds on. `fable` is sanctioned for the hardest delegated work
  (long-horizon, multi-file, adversarial verification); `inherit` is not
  used for plugin agents (it would inherit a below-floor session model too).
  When a teammate/workflow agent would otherwise inherit a non-Opus,
  non-Fable session model, set `model: "opus"` explicitly.
- **Effort**: the cost lever, not the model — `low`/`medium` for most
  delegated tasks, `high`+ for genuinely hard reasoning, set via the
  delegate's `effort:` frontmatter or a per-spawn override where supported.
- `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` overrides every per-agent `model:`
  choice, including plugin frontmatter that pins `opus`. Remove stray
  Sonnet/Haiku suggestions on sight in any agent, workflow, skill, or rule.

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
