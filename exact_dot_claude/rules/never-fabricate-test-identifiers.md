# Never Fabricate an Identifier You're About to Test Against

Promoted to a skill: invoke `agent-patterns-plugin:probe-input-integrity` when
building a probe, repro, or test harness — it carries the three forms
(invented identifier, retyped subject, inert stub), their canonical breaks,
and the borrowed-control-set technique for an empty target set.

- **Obtain the identifier from the system itself. Never invent a
  plausible-looking one** — list before you get.
- **Always run a known-good control.** Without one, "access denied", "not
  found" and "wrong shape" are indistinguishable.
- **Extract the shipped text** (`sed -n '/start/,/end/p' <file>`); never
  retype the code under test into the harness.
- **`chmod +x` a stub and assert it** (`command -v <tool>`, or a sentinel the
  real tool never prints) — a non-executable stub is skipped and the real tool
  runs, side effects included.
