# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) documenting significant technical decisions made in this dotfiles repository.

## What is an ADR?

An ADR is a document that captures an important architectural decision made along with its context and consequences. ADRs help future maintainers understand why certain decisions were made.

## ADR Index

| ID | Title | Status | Date |
|----|-------|--------|------|
| [0001](0001-chezmoi-exact-directory-strategy.md) | Chezmoi exact_ Directory Strategy | Accepted | 2024-12 |
| [0002](0002-unified-tool-version-management-mise.md) | Unified Tool Version Management with Mise | Accepted | 2024-12 |

## Planned ADRs

The following decisions have been identified for future documentation:

### Stage 2: AI Agent Architecture
- **ADR-0003**: Skill Activation via Trigger Keywords
- **ADR-0004**: Subagent-First Delegation Strategy
- **ADR-0005**: Namespace-Based Command Organization

### Stage 3: Development Culture
- **ADR-0006**: Documentation-First Development
- **ADR-0007**: Layered Knowledge Distribution (CLAUDE.md Architecture)

### Stage 4: Automation & Operations
- **ADR-0008**: Project-Scoped MCP Servers
- **ADR-0009**: Conventional Commits + Release-Please Automation
- **ADR-0010**: Tiered Test Execution with Specialized Agents

## ADR Format

Each ADR follows the [Michael Nygard format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions):

```markdown
# ADR-NNNN: Title

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Date
YYYY-MM

## Context
What is the issue motivating this decision?

## Decision
What is the change being proposed/made?

## Consequences
What are the positive and negative results?
```

## Creating a New ADR

1. Copy the template from an existing ADR
2. Number sequentially (0003, 0004, etc.)
3. Use lowercase-kebab-case for filenames
4. Update this README's index table
5. Link related ADRs in the "Related Decisions" section
