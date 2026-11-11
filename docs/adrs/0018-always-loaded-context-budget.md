---
id: ADR-0018
status: Accepted
created: 2026-11-11
modified: 2026-11-11
deciders: "Lauri Gates"
domain: context-engineering
relates-to: [ADR-0007, ADR-0011, ADR-0020]
---

# ADR-0018: Byte Budget for Always-Loaded Claude Context

## Context

Every file under `~/.claude/rules/` and both `CLAUDE.md` files load on every
turn of every session, in every project. ADR-0011 moved guidance into rule
files, and the rule set then grew with each incident it recorded. By 2026-07 the
user-global surface was about 150 KB, most of it narrative that applied to a
small share of sessions.

Nothing limited the growth. A rule added for one repository cost tokens in all
of them, and there was no moment at which the cost was looked at.

Derived from commits 8cf3eef (#300, 2026-07-04), 2373af3 (#302), d0ab77f (#378),
0740ac2 (#431) and 0442878 (#580, 2026-11-11).

## Decision

The always-loaded surface has a byte ceiling, enforced by
`tests/test-claude-context-budget.sh` as a pre-commit hook and in CI. Content
that does not need to load on every turn moves to the cheapest place that still
reaches the reader:

| Content | Destination |
|---|---|
| Applies to one repository | That repository's `.claude/rules/` |
| Applies when certain files are edited | A rule with `paths:` frontmatter |
| Has a trigger recognisable in advance | A marketplace skill; the rule shrinks to a pointer stub naming it |
| Must fire every time | A hook |
| Dated incidents, graded runs, procedures | `docs/rules-evidence.md` and `docs/scheduled-work.md` |

A rule keeps its invariant inline and links to the rest. Two kinds of content
stay inline even when a skill holds the detail: a gate read while the decision
is being made, and a rule unscoped on purpose because its hazard fires on a
command rather than on a file edit (`chezmoi-apply-hazards.md`).

The ceiling is `TOTAL_BUDGET_BYTES` in the test. The test file carries a dated
ledger of every change to it. When the surface exceeds the ceiling, the default
response is to promote or cut content, not to raise the number.

## Consequences

### Positive

- The per-turn cost of global configuration is measured and has a limit.
- A rule added for one repository no longer loads in the others.
- Skills load on intent, so long procedures cost nothing in sessions that do
  not need them.

### Negative

- A pointer stub works only when the skill it names exists. The stub and the
  skill live in different repositories, so the skill's PR has to merge first.
- A skill has to be invoked. A trigger that goes unrecognised means the
  guidance is not read; a rule would have been.
- A full rule set that exceeds the ceiling turns `main` red until someone
  triages it (this happened on 2026-09-21, #431).

## Options Considered

### Option 1: Byte ceiling with a promotion ladder (chosen)

A regression test fails above a fixed byte count, and content moves down the
table above. **Pros:** deterministic; the limit is checked on every commit.
**Cons:** bytes approximate tokens; the stub and skill can drift apart.

### Option 2: Raise the ceiling as the rule set grows

**Pros:** no triage work. **Cons:** the test stops prompting any cleanup.
**Rejected because:** the ledger records two earlier bumps as deferring debt
that then had to be repaid.

### Option 3: No limit, periodic manual review

**Pros:** nothing to maintain. **Cons:** the review depends on someone
remembering. **Rejected because:** the surface reached about 150 KB under this
arrangement.

## Related ADRs

- [ADR-0007: Layered Knowledge Distribution](0007-layered-knowledge-distribution.md) — this ADR adds a size limit to the layers it defines.
- [ADR-0011: Migration to Claude Code Rules System](0011-claude-rules-migration.md) — this ADR constrains what stays in the rule files that migration created.
- [ADR-0020: Marketplace Plugins with a Project-Level Pin](0020-marketplace-plugins-project-pin.md) — the skills that pointer stubs name come from that marketplace.
