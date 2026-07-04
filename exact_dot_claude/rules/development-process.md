# Development Process

- **Documentation-first**: before implementing against any tool/framework,
  verify syntax, parameters, breaking changes, and deprecations in current
  official docs (context7, WebFetch, WebSearch) — don't code from memory.
- **PRD-first**: significant features get a PRD before implementation; use
  the blueprint-plugin skills (`blueprint-prp-create`, `document-detection`)
  for PRDs/ADRs/PRPs.
- **TDD**: RED → GREEN → REFACTOR; tier test runs by change scope (unit after
  every change, integration after feature completion, E2E before commit/PR) —
  the testing-plugin skills (`test-quick`, `test-full`, `test-tier-selection`)
  encode the tiers and commands.
- **Version control**: commit early and often, conventional commits, pull
  before branching, security checks before staging.
- **Temp outputs**: use the project's `tmp/` (in `.git/info/exclude`) for
  test outputs; stay in the repo root and pass paths as arguments rather than
  `cd`-ing around.
