# Offload Mechanical Work to a Deterministic Substrate

The agent and the substrate it runs on have complementary strengths, and the
recurring quality problem is putting work on the wrong one. The agent is good
at **judgment** — reading intent, weighing trade-offs, synthesizing. It is bad
at being **repeatable**: ask it to count, parse, audit, or enforce the same
thing twice and you get two slightly different answers, each consuming scarce,
lossy context. Scripts, hooks, justfile recipes, and structured-output
contracts are the opposite — narrow, but byte-identical every run, and free of
context cost once written.

So the law:

> **Anything mechanical, repeatable, and verifiable belongs *outside* the
> agent's reasoning loop — in a deterministic artifact the agent invokes and
> consumes. Spend the context window on judgment, not on re-deriving facts a
> script would produce identically every time. The agent decides; the
> substrate verifies and remembers.**

## Three distinct claims (don't conflate them)

The principle is load-bearing in three different ways. Naming them separately
is what lets you decide *which* substrate fits a given task.

| Claim | Why it matters | The lever |
|---|---|---|
| **Context economy** | The context window is the bottleneck and it is *lossy* — summarized across turns, drifts over a long session. Every token spent watching the agent grep/count/parse is a token unavailable for reasoning. | A script returns a compact `STATUS=` / `KEY=VALUE` rollup; the agent reads the verdict, not the computation. |
| **Determinism / reproducibility** | Correctness you rely on must be repeatable. An agent re-doing a mechanical task varies run-to-run; a script does not. | Encode the check once. The agent consumes its result; it never recomputes. |
| **Independent enforcement** | An agent asked to *both* do the work *and* judge whether it followed the rules is biased toward "done" (it optimizes for completion, not correctness). | A hook judges from outside, with no stake in the outcome — the agent cannot rationalize past it. |

## Routing a task to the right substrate

| The work is… | Put it in… | Because |
|---|---|---|
| A one-shot mechanical computation (parse, count, audit, link-resolve, frontmatter scan) | A single inline `python3`/`rg`/`jq` pass | Cheaper, reproducible, and rate-limit-immune vs. an agent fan-out (`tool-use-patterns.md`). |
| A diagnostic that an orchestrating skill rolls up | A script emitting `=== SECTION ===` / `KEY=VALUE` / `STATUS=` | Two lines of tokens per check instead of re-reading prose (`structured-script-output.md`). |
| A guardrail that must fire *every* time, not when the agent remembers | A PreToolUse / SessionStart **hook** | Deterministic enforcement the agent can't skip (`bash-antipatterns`, branch-protection, coworker-detection hooks). |
| The exit/"done" judgment of a loop | A mechanical gate (green suite, `tsc` exit 0) or a **fresh** independent verifier | The worker has a stake in finishing; the judge must not (`loop-integrity.md`). |
| A drift sweep that already exists as a script | The existing script, mounted on an autonomous **trigger** | The gap is usually triggering, not logic — don't rewrite the sweep (`drift-detection-triggering.md`). |
| Pinning a fixed bug so it can't silently return | A regression **test/script check** | The fix survives in a deterministic gate, not in the agent's promise to remember. |

## The litmus test

Before letting the agent do something by hand, ask: *"Would a script give the
same answer every time, and would I trust that answer more?"* If yes, the work
wants a script or hook — write it once and have the agent invoke it. Reserve
the agent's reasoning for the part that genuinely needs judgment.

Two cautions so this doesn't overreach:

- **Don't pre-build substrate for a one-off.** YAGNI applies (`code-quality.md`).
  The payoff is in *repeated* mechanical work; a single throwaway computation is
  fine inline.
- **Don't double-gate.** A hook that re-implements a check auto mode (or another
  hook) already performs just adds friction — make it defer
  (`claude-code-auto-mode.md`).

## Rationale

This is the parent principle behind a family of rules that each apply it to one
situation — structured script output, drift-trigger separation, loop integrity,
regression tests, the Bash→tool hooks, prefer-inline-pass-over-fan-out. Each was
written to solve its own problem; the common law underneath is that **the lossy,
probabilistic agent should not be the system of record for anything a
deterministic artifact can compute, enforce, or remember.** Putting mechanical
work back in the agent's loop is the silent tax — it burns context, drifts
between runs, and lets the agent grade its own homework.

## Related

- `tool-use-patterns.md` — prefer one inline `python3`/`rg` pass over agent fan-out for mechanical work
- `claude-code-auto-mode.md` — don't double-gate: hooks should defer to auto mode where it already covers the concern
- `code-quality.md` — YAGNI: build the substrate when the work repeats, not speculatively
- (claude-plugins) `structured-script-output.md`, `drift-detection-triggering.md`, `loop-integrity.md`, `regression-testing.md` — plugin-authoring instances of this law
