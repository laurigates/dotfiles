---
reviewed: 2026-10-19
---

# Agent and Tool Selection

## Use Plugin-Qualified Agent IDs

When invoking `Agent` or `Task`, use the fully-qualified `plugin:agent` form
shown in the system prompt's agent list (`agents-plugin:security-audit`, never
bare `security-audit`). The bare form is only correct for agents defined at the
user or project level (`~/.claude/agents/`, `.claude/agents/`); otherwise it
fails with `Agent type 'X' not found`. If the expected agent is missing from
the session's list, fall back to a different agent or direct tool use rather
than guessing a name.

## Model Selection for Subagents and Agent Teams

A delegate's output comes back into the main loop as a tool result, so a
delegate that misses things degrades everything built on it without any error.
Choose the model for the task, and put an independent check behind the cheaper
one.

- **Opus is the default** for a delegate that edits, verifies facts, or returns
  analysis the main loop builds on. `fable` is sanctioned for the hardest
  delegated work (long-horizon, multi-file, adversarial verification).
- **Sonnet 5.5 is acceptable** when the task is well specified (a bounded
  diagnosis, an implementation against an explicit brief) **and** something
  independent checks the result: a mechanical gate (tests, lint, the real
  parser) or an Opus pass that re-runs its claims against the artefact. Also
  whenever Lauri asks for it.
- **Keep Opus for open-ended review and audit**, where the value is finding what
  the brief did not list. That is where the two models differed (evidence below).
- **Haiku 5.5** (the `haiku` alias since Claude Code 2.1.293) only for
  mechanical work that something stronger checks, in the shapes claude-plugins
  sanctions (`.claude/rules/agent-development.md` § Model Selection for Agents):
  - the cold-read reader (exception below);
  - a lean read-only agent file: `omitClaudeMd: true`, `tools:` limited to
    Read, Grep and Glob, an explicit `effort:` (`agents-plugin:lean-reader`;
    `scripts/check-agent-model.sh` enforces the shape);
  - a mechanical workflow `agent()` stage (verbatim extraction, closed-enum
    classification) with an explicit `effort`, whose output a stronger stage or
    a script checks (`scripts/check-workflow-js-model.sh`). The check covers
    omission too: a stage whose dropped items never reach a later stage stays
    on a stronger model;
  - a `.github/workflows` invocation, decided per workflow after a replay
    against its Opus output passes.

  A Haiku reader never emits judgments, verdicts or findings the main loop
  builds on unchecked. In the 2026-10 audit, 46% of its judgment calls held
  (evidence below).
- **`inherit`** is not used for plugin agents: it passes on whatever the session
  runs. When a teammate or workflow agent would otherwise inherit an unsuitable
  session model, set `model:` explicitly.
- **Effort** is the other cost lever: `low`/`medium` for most delegated tasks,
  `high`+ for genuinely hard reasoning.
- **Sonnet 5.5 specifics**, from the
  [announcement](https://www.anthropic.com/claude-sonnet-5-5):
  - Set effort explicitly on a Sonnet delegate wherever it can be set (agent
    frontmatter `effort:`, `claude --effort` in CI). Claude Code defaults it to
    Medium.
  - Cap it at `high`/`xhigh` for scoped edits, never `max`. On FrontierCode,
    Sonnet 5.5 at Max scored below Xhigh because it ran the code-review skill's
    subagents more often, which led to timeouts and out-of-scope edits.
  - Send security review to Opus. Sonnet 5.5 falls back to Sonnet 5 on
    higher-risk cyber tasks.
- **Next re-run**: claude-plugins #3116, the Tier 2 opus/sonnet/haiku matrix
  at matched effort, calibrates these tier boundaries. Re-check the Sonnet and
  Haiku bullets against its result.
- `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` overrides every per-agent `model:` choice,
  including plugin frontmatter. Don't hard-code a cheaper model into an agent
  definition, workflow or skill as a blanket cost default; choose per task under
  the rules above.

### Evidence

The graded runs behind these tiers (2026-06 Opus/Sonnet, 2026-09-30
infrastructure 10/12 vs 12/12, 2026-10-14 Sonnet implementers, 2026-10-10 Haiku
re-evaluation) are in `~/.local/share/chezmoi/docs/rules-evidence.md`
§ agent-and-tool-selection.md.

### Sanctioned exception: cold-read gates run on Haiku

`agent-patterns-plugin:cold-read-gate` deliberately uses `model: "haiku"` for
its fresh-reader critics: they are the **measurement instrument** ("can a
low-context reader act on this text alone?"), and their output is self-report
about their own comprehension. Do not "fix" them to Opus.

The exception ends where the reader emits **judgments, verdicts, or
evidence-bearing findings — audience-simulation personas included**. Run those
on Opus or a non-Claude model via PAL, and enforce "low-context" by **slicing
the input**, never by weakening the model. Any agent that edits, verifies
facts, or returns analysis the main loop builds on follows the model rules
above.
