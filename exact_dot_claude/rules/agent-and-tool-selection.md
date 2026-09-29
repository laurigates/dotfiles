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
so a weaker model quietly degrades everything downstream. "Save tokens with
Sonnet" is a false economy: Opus at *low* effort beat Sonnet at *high* effort
on both quality and token efficiency.

- **Model**: `opus` is the floor, never `"sonnet"`/`"haiku"`, for any
  delegate that edits, verifies facts, or returns analysis the main loop
  builds on. `fable` is sanctioned for the hardest delegated work
  (long-horizon, multi-file, adversarial verification); `inherit` is not
  used for plugin agents (it would inherit a below-floor session model too).
  When a teammate/workflow agent would otherwise inherit a non-Opus,
  non-Fable session model, set `model: "opus"` explicitly.
- **Effort**: the cost lever, not the model — `low`/`medium` for most
  delegated tasks, `high`+ for genuinely hard reasoning.
- `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` overrides every per-agent `model:`
  choice, including plugin frontmatter that pins `opus`. Remove stray
  Sonnet/Haiku suggestions on sight in any agent, workflow, skill, or rule.

### Sanctioned exception: cold-read gates run on Haiku

`agent-patterns-plugin:cold-read-gate` deliberately uses `model: "haiku"` for
its fresh-reader critics: they are the **measurement instrument** ("can a
low-context reader act on this text alone?"), and their output is self-report
about their own comprehension. Do not "fix" them to Opus.

The exception ends where the reader emits **judgments, verdicts, or
evidence-bearing findings — audience-simulation personas included**. Run those
on Opus or a non-Claude model via PAL, and enforce "low-context" by **slicing
the input**, never by weakening the model. Any agent that edits, verifies
facts, or returns analysis the main loop builds on stays on Opus.
