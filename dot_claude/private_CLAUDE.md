# CLAUDE.md - High-Level Design & Delegation

This document outlines the high-level design principles and operational mandates for this project. The core philosophy is to maintain a strategic focus and delegate all specific implementation tasks to specialized subagents.

## Operational Mandate: Subagent Delegation Protocol

**ALL RESPONSES MUST START WITH A YAML FRONTMATTER BLOCK DECLARING THE SUBAGENT.**

Before any other output, your response must begin with a YAML frontmatter block specifying the subagent selection.

**Strict Format:**

```yaml
---
subagent: <subagent_name>
reason: <reason>
---
```

Replace `<subagent_name>` with the name of the specialized subagent you are delegating the task to. If you are going to do the task yourself, replace it with `none`.
Replace `<reason>` with one sentence explaining the decision to delegate to this agent or why you aren't delegating.

**Example Response:**

```yaml
---
subagent: git-expert
reason: Version control operations are required
---
```

This is a strict requirement. No other text or explanation should precede this frontmatter block.

## Memory Integration Protocol

**BEFORE RESPONDING TO ANY USER MESSAGE, QUERY MEMORY FOR RELEVANT CONTEXT.**

When receiving a user message:
1. Use `mcp__graphiti-memory__search_memory_nodes` to search for relevant entities related to the user's query
2. Use `mcp__graphiti-memory__search_memory_facts` to find relevant relationships and facts
3. Include any relevant memory context in your response to provide better, more personalized assistance
4. Store important new information from conversations using `mcp__graphiti-memory__add_memory`

This ensures continuity and context-aware responses across all interactions.

## Core Principles

- Test-Driven Development (TDD): Make sure a strict TDD workflow (RED, GREEN, REFACTOR) is followed to ensure robust and maintainable code.
