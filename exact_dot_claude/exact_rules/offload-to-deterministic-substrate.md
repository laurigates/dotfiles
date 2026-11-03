# Offload Mechanical Work to a Deterministic Substrate

The agent is good at **judgment** and bad at being **repeatable**; scripts,
hooks, and structured-output contracts are the opposite. The law:

> **Anything mechanical, repeatable, and verifiable belongs *outside* the
> agent's reasoning loop — in a deterministic artifact the agent invokes and
> consumes. Spend the context window on judgment, not on re-deriving facts a
> script would produce identically every time. The agent decides; the
> substrate verifies and remembers.**

## Routing a task to the right substrate

| The work is… | Put it in… | Because |
|---|---|---|
| A one-shot mechanical computation (parse, count, audit, link-resolve, frontmatter scan) | A single inline `python3`/`rg`/`jq` pass | Cheaper, reproducible, and rate-limit-immune vs. an agent fan-out. |
| A diagnostic that an orchestrating skill rolls up | A script emitting `=== SECTION ===` / `KEY=VALUE` / `STATUS=` | Two lines of tokens per check instead of re-reading prose. |
| A guardrail that must fire *every* time, not when the agent remembers | A PreToolUse / SessionStart **hook** | Deterministic enforcement the agent can't skip. |
| The exit/"done" judgment of a loop | A mechanical gate (green suite, `tsc` exit 0) or a **fresh** independent verifier | The worker has a stake in finishing; the judge must not. |
| A drift sweep that already exists as a script | The existing script, mounted on an autonomous **trigger** | The gap is usually triggering, not logic — don't rewrite the sweep. |
| Pinning a fixed bug so it can't silently return | A regression **test/script check** | The fix survives in a deterministic gate, not in the agent's promise to remember. |
| A membership/ownership/security fact a subagent would **infer** (tracked? public? managed-by-X?) | A deterministic lookup (`chezmoi managed`, `git ls-files`) passed **in** as ground truth | Agents conflate co-location with membership: a live `~/.gemini/` cred was mis-reported as tracked-and-public (false leak) until checked against `chezmoi managed`. Treat such a tag as an unverified claim. |

## The litmus test

Before doing something by hand, ask: *"Would a script give the same answer every
time, and would I trust it more?"* If yes, write it once and invoke it.

- **Don't pre-build substrate for a one-off.** YAGNI: the payoff is in
  *repeated* mechanical work; a throwaway computation is fine inline.
- **Don't double-gate.** A hook re-implementing a check auto mode (or another
  hook) already performs just adds friction — make it defer.
