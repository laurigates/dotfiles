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

### Development Philosophy
- **PRD-First Development**: Every new feature or significant change MUST have a Product Requirements Document (PRD) created before any implementation begins. Use the `prd-writer` subagent for all feature requests.
- **Human-Centered Design**: Prioritize user experience and discoverability in all solutions
- **Don't Reinvent the Wheel**: Leverage existing, proven solutions before creating custom implementations
- **Test-Driven Development (TDD)**: Follow strict RED, GREEN, REFACTOR workflow to ensure robust and maintainable code

### Code Quality Standards
- **Readability First**: Simplicity and clarity are paramount - avoid unnecessary complexity
- **Self-Documenting Code**: Use descriptive names that reveal intent; minimize comments in favor of self-explanatory code
- **Small, Focused Functions**: Keep functions small with minimal arguments for better composability
- **Error Handling**: Use exceptions for robust error management and fail fast for early detection
- **Security by Design**: Always consider and protect against vulnerabilities

### Architectural Principles
- **Functional Programming**: Emphasize pure functions, immutability, function composition, and declarative code
- **Avoid Object-Oriented Programming**: Prefer functional and procedural approaches for simplicity
- **Twelve-Factor App Methodology**: Build portable, resilient applications following cloud-native principles
- **Separation of Concerns (SOC)**: Maintain clear boundaries between different parts of the system

### Engineering Practices
- **YAGNI** (You Aren't Gonna Need It): Implement only what's necessary
- **KISS** (Keep It Simple, Stupid): Choose the simplest solution that works
- **DRY** (Don't Repeat Yourself): Eliminate duplication through abstraction
- **Convention over Configuration**: Reduce decisions by establishing sensible defaults
- **JEDI** (Just Enough Design Initially): Start with minimal design, evolve as needed
- **Test After Changes**: Always run tests after making modifications to ensure nothing breaks
