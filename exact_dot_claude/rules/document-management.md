# Document Management

## Decision Detection

Watch for these patterns during conversations and prompt to create formal documents:

**Architecture decisions** (→ create ADR in `docs/adrs/`):
- Choosing between tools, approaches, or patterns
- Deciding on configuration strategies
- Selecting package managers or version managers
- Making cross-platform compatibility choices

**Feature requirements** (→ create/update PRD in `docs/prds/`):
- Discussing new dotfiles features or capabilities
- Defining desired shell behaviors or integrations
- Planning new tool configurations

**Implementation plans** (→ create PRP in `docs/prps/`):
- Detailed plans for implementing a new tool setup
- Migration strategies between tools
- Complex configuration refactoring

## Document Locations

- PRDs: `docs/prds/` — what and why
- ADRs: `docs/adrs/` — architecture decisions with context and trade-offs
- PRPs: `docs/prps/` — how to implement

## ADR Naming

`docs/adrs/NNNN-kebab-case-title.md` — use next sequential number.
