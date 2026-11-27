---
reviewed: 2026-11-26
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
- **Route follow-ups, don't only mention them**: when work turns up a reason
  for a follow-up (a pre-existing bug, an unverified claim, a known limit,
  deferred work), record it before the turn ends, without waiting to be asked,
  in as few issues as the work allows. Check each one once against the
  default branch and drop what is already handled. Then:
  1. In a file the PR touches, or under about 30 lines: fix it in the PR as
     its own commit.
  2. Needs a check on hardware or by a person: a line on the repo's
     verification-queue issue, where one exists.
  3. Everything else: one rollup checklist issue per PR, or a line on the
     subsystem's open rollup. Never one issue per finding.
  The PR body and the report link the rollup; they do not carry the list.
  Search for a duplicate first, say which parts are unverified, and follow
  the repo's metadata and grouping rules. The tripwire exception in
  `~/.claude/CLAUDE.md` § Git Workflow still applies. Evidence:
  `~/.local/share/chezmoi/docs/rules-evidence.md` § development-process.md.
- **Temp outputs**: use the project's `tmp/` (in `.git/info/exclude`) for
  test outputs; stay in the repo root and pass paths as arguments rather than
  `cd`-ing around.
