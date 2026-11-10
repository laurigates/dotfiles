---
reviewed: 2026-11-10
---

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
- **Scope discipline**: change what the task requires, nothing more — no
  drive-by refactors or "while I'm here" cleanups. Pre-existing bugs you
  notice stay out of the diff.
- **File follow-ups, don't only mention them**: when work turns up a reason
  for a follow-up (a pre-existing bug, an unverified claim, a known limit,
  deferred work), file it as a GitHub issue in the repo it belongs to before
  the turn ends, without waiting to be asked. The PR body and the report then
  link the issues; they do not carry the list. Search for a duplicate first,
  say in the issue which parts are unverified, and follow the repo's metadata
  and grouping rules. The tripwire exception in `~/.claude/CLAUDE.md`
  § Git Workflow still applies.
- **Temp outputs**: use the project's `tmp/` (in `.git/info/exclude`) for
  test outputs; stay in the repo root and pass paths as arguments rather than
  `cd`-ing around.
