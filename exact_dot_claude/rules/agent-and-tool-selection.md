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
- **Haiku** only for the cold-read exception below.
- **`inherit`** is not used for plugin agents: it passes on whatever the session
  runs. When a teammate or workflow agent would otherwise inherit an unsuitable
  session model, set `model:` explicitly.
- **Effort** is the other cost lever: `low`/`medium` for most delegated tasks,
  `high`+ for genuinely hard reasoning.
- `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` overrides every per-agent `model:` choice,
  including plugin frontmatter. Don't hard-code a cheaper model into an agent
  definition, workflow or skill as a blanket cost default; choose per task under
  the rules above.

### Evidence

> 2026-06 (dotfiles #237): Opus 4.8 at low effort beat Sonnet 4.6 at high effort
> on quality and token efficiency. That result set the earlier Opus-only floor.
> It compared those model versions and says nothing about later ones.
>
> 2026-09-30 (FVH `infrastructure`): Sonnet 5.5 and Opus 5.5 got identical
> read-only briefs against a frozen snapshot, at the same default effort, graded
> against defects verified before the runs.
>
> | Task | Sonnet 5.5 | Opus 5.5 |
> |---|---|---|
> | Diagnosis: why a classifier resolves nothing (4 known causes) | 4/4 | 4/4 |
> | Review of three recipes (12 known defects) | 10/12 | 12/12 |
>
> Token use was within 3% on both tasks, and neither run made a false claim.
> Sonnet's one unique review find was a latent crash under macOS bash 3.2.
> Opus's unique finds included the recipe's silent exit without a terminal, and
> a plausible pattern (`client.id`) that would have rotated 14 third-party OAuth
> client IDs. A separate Sonnet 5.5 implementation task (infrastructure
> #2517–#2519) held on every claim re-run against the pushed branches. Four graded runs, scored by an Opus session, are
> a small sample. Re-run the comparison when either model changes.

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
