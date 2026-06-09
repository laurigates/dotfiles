# Agent and Tool Selection

## Use Plugin-Qualified Agent IDs

When invoking `Agent` or `Task`, use the fully-qualified `plugin:agent` form
shown in the system prompt's agent list. The bare form (e.g. `security-audit`)
is only correct for agents defined at the user or project level
(`~/.claude/agents/` or `.claude/agents/`).

**Correct:**

- `agents-plugin:security-audit`
- `github-actions-plugin:github-actions-inspection`

**Incorrect (causes `Agent type 'X' not found`):**

- `security-audit`
- `github-actions-inspection`

When the agent list shows a `plugin:agent` form, always use that form. If the
expected agent is missing from the current session's agent list, prefer a
graceful fallback (different agent or direct tool use) over guessing a name.

## Always Use Opus for Subagents and Agent Teams

Every spawned subagent and every member of an agent team **must run on Opus**.
Do not select Sonnet (or Haiku) for delegated work. Opus 4.8 on *low* effort
already beats Sonnet 4.6 on *high* effort — on both quality and token
efficiency — so there is no scenario where a smaller model is the right call
for a subagent.

- **Model**: always `opus`. Never pass `model: "sonnet"` / `"haiku"` to the
  `Agent` / `Task` tools, to `agent()`/`opts.model` in `Workflow` scripts, or
  to per-phase `model` overrides. When a teammate or workflow agent would
  otherwise inherit a non-Opus session model, set `model: "opus"` explicitly.
- **Effort**: free to dial down. `low` or `medium` effort is fine — and
  preferred — for most delegated tasks; reserve `high` for genuinely hard
  reasoning. The effort knob, not the model knob, is the lever for cost.
- **Remove Sonnet suggestions on sight.** If an agent definition, workflow,
  skill, or rule still recommends or hard-codes Sonnet for a subagent, change
  it to Opus.

Rationale: a subagent's output feeds back into the main loop as a tool result,
so a weaker delegate quietly degrades everything downstream. Opus-low is both
better and cheaper than Sonnet-high, which makes "save tokens with Sonnet" a
false economy.
