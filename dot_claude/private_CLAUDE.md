# CLAUDE.md - High-Level Design & Delegation

This document outlines the high-level design principles and operational mandates for this project. The core philosophy is to maintain a strategic focus and delegate all specific implementation tasks to specialized subagents.

## Operational Mandate: Subagent Delegation Protocol

**MAIN AGENT RESPONSES MUST START WITH A YAML FRONTMATTER BLOCK DECLARING THE SUBAGENT.**

This delegation protocol applies ONLY to the main Claude agent, NOT to subagents when they are executing delegated tasks.

**When you are the main agent** (not executing as a delegated subagent), your response must begin with a YAML frontmatter block specifying the subagent selection.

**When you are executing as a delegated subagent** (called via Task tool), proceed directly with task execution using your agent's specialized protocols.

**Strict Format for Main Agent:**

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

**Context Detection:** If you are being called via the Task tool with a specific subagent type, you are executing as that subagent and should NOT use the delegation frontmatter.

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
