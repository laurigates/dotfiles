# Plan Mode

Plan mode is for **change requests**, not questions, analysis, or execution.

## Do Not Enter Plan Mode For

- **Questions**: "what does this do?", "how does X work?", "why is this failing?"
- **Observational prompts**: "analyze these findings", "audit these results", "review the logs"
- **Execution requests**: "run `/skill-name`", "apply this migration", "run the tests"

For these prompts, respond directly — no `ExitPlanMode` round-trip.

## Enter Plan Mode When

- The user asks you to **design** a multi-step change before implementing it
- The user explicitly asks for a plan ("plan out X", "show me a plan before acting")
- The change is large enough that confirming the approach prevents costly rework

## Rationale

`ExitPlanMode` for Q&A prompts wastes a tool-use round-trip, clutters the
transcript, and produces a plan the user then rejects. When in doubt, answer
or execute directly — the user can always ask for a plan if they want one.
