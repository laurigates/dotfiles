# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) documenting significant technical decisions made in this dotfiles repository.

## What is an ADR?

An ADR is a document that captures an important architectural decision made along with its context and consequences. ADRs help future maintainers understand why certain decisions were made.

## ADR Index

| ID | Title | Status | Date |
|----|-------|--------|------|
| [0001](0001-chezmoi-exact-directory-strategy.md) | Chezmoi exact_ Directory Strategy | Accepted | 2024-12 |
| [0002](0002-unified-tool-version-management-mise.md) | Unified Tool Version Management with Mise | Accepted | 2024-12 |
| [0003](0003-skill-activation-trigger-keywords.md) | Skill Activation via Trigger Keywords | Accepted | 2024-12 |
| [0004](0004-subagent-first-delegation-strategy.md) | Subagent-First Delegation Strategy | Accepted | 2024-12 |
| [0005](0005-namespace-based-command-organization.md) | Namespace-Based Command Organization | Accepted | 2024-12 |
| [0006](0006-documentation-first-development.md) | Documentation-First Development | Accepted | 2024-12 |
| [0007](0007-layered-knowledge-distribution.md) | Layered Knowledge Distribution | Accepted | 2024-12 |
| [0008](0008-project-scoped-mcp-servers.md) | Project-Scoped MCP Servers | Accepted | 2024-12 |
| [0009](0009-conventional-commits-release-please.md) | Conventional Commits + Release-Please | Accepted | 2024-12 |
| [0010](0010-tiered-test-execution.md) | Tiered Test Execution | Accepted | 2024-12 |
| [0011](0011-claude-rules-migration.md) | Claude Rules Migration | Accepted | 2025-12 |
| [0012](0012-justfile-command-runner.md) | Justfile Command Runner | Accepted | 2025-12 |

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
