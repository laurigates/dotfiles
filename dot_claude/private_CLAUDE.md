# CLAUDE.md - High-Level Design & Delegation

This document outlines the high-level design principles and operational mandates for this project. The core philosophy is to maintain a strategic focus and delegate all specific implementation tasks to specialized subagents.

## Subagent Delegation Strategy

**Actively delegate to specialized subagents for domain-specific tasks.** The system includes 30+ specialized agents that excel in their respective domains.

### Delegation Guidelines

When analyzing a user request:
1. **Identify Domain Match**: Look for tasks that align with specialized agent expertise
2. **Prefer Specialists**: Delegate to domain experts rather than handling specialized tasks directly
3. **Enable Parallel Execution**: Launch multiple agents when tasks can run concurrently
4. **Maintain Focus**: Let the main agent coordinate while specialists execute

### Key Delegation Areas

- **Code Development**: python-developer, nodejs-developer, rust-development, cpp-development
- **Shell & Automation**: shell-expert for scripting and CLI tools
- **Version Control**: git-operations for all Git/GitHub tasks
- **Quality & Security**: code-reviewer, security-auditor, test-architect
- **Infrastructure**: container-development, kubernetes-operations, infrastructure-terraform
- **Documentation**: documentation, research-documentation, requirements-documentation
- **Debugging**: debugging for error investigation and root cause analysis
- **Configuration**: neovim-configuration, makefile-build, template-generation

### Using the Task Tool

**The Task tool enables delegation to specialized agents:**

```python
Task(
    description="Brief task summary",  # 3-5 words
    subagent_type="agent-name",       # Match agent filename (without .md)
    prompt="Detailed instructions with context and requirements"
)
```

**Best Practices:**
- Provide complete context in the prompt
- Be specific about requirements and success criteria
- Enable parallel execution for independent tasks
- Let agents work autonomously with sufficient information

**Parallel Execution:**
```python
# Launch multiple agents simultaneously for independent tasks
Task(description="Implementation", subagent_type="python-developer", prompt="...")
Task(description="Tests", subagent_type="test-architecture", prompt="...")
Task(description="Documentation", subagent_type="documentation", prompt="...")
```

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
- **Commit early and often**: Commit changes often, rebase before pushing to GitHub. It's important to keep track of small changes as you're working. It doesn't matter if some tests fail for work-in-progress.

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
