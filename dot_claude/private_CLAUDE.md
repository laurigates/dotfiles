# CLAUDE.md - High-Level Design & Delegation

This document outlines the high-level design principles and operational mandates for this project. The core philosophy is to maintain a strategic focus and delegate all specific implementation tasks to specialized subagents.

## Operational Mandate: Subagent Delegation Protocol

**MAIN AGENT RESPONSES MUST START WITH A YAML FRONTMATTER BLOCK DECLARING THE SUBAGENT.**

This delegation protocol applies ONLY to the main Claude agent, NOT to subagents when they are executing delegated tasks.

### Delegation Decision Framework

**Actively seek opportunities to delegate to specialized subagents.** When analyzing a user request:

1. **Scan for Domain Keywords**: Look for technical terms that match subagent expertise
2. **Match Task Patterns**: Identify tasks that align with subagent descriptions
3. **Consider Parallel Execution**: Deploy multiple subagents when tasks can run concurrently
4. **Prefer Specialists**: Always delegate to specialists rather than handling tasks directly

### When to Delegate (Always Delegate These)

- **Code Operations**: python-developer, nodejs-developer, embedded-expert
- **Git/GitHub Tasks**: git-expert for ALL version control operations
- **Quality Analysis**: code-reviewer, security-auditor, test-architect
- **Infrastructure**: container-maestro, k8s-captain, infra-sculptor
- **Documentation**: docs-expert, research-assistant
- **Debugging**: debug-specialist for ANY error investigation
- **Configuration**: neovim-expert, dotfiles-manager, makefile-expert

### Delegation Execution

**When you are the main agent** (not executing as a delegated subagent):

```yaml
---
subagent: <subagent_name>
reason: <specific task match>
---
```

Then immediately use the Task tool to delegate:

```
Task(description="Clear task description", subagent_type="subagent_name", prompt="Detailed instructions")
```

**When you are executing as a delegated subagent** (called via Task tool), proceed directly with task execution using your agent's specialized protocols.

### Examples of Effective Delegation

```yaml
---
subagent: git-expert
reason: User needs to create a pull request
---
```

```yaml
---
subagent: python-developer
reason: Python code implementation requested
---
```

```yaml
---
subagent: debug-specialist
reason: Error investigation and root cause analysis needed
---
```

**Context Detection:** If you are being called via the Task tool with a specific subagent type, you are executing as that subagent and should NOT use the delegation frontmatter.

### Task Tool Usage Best Practices

**The Task tool is your primary mechanism for delegation.** Use it immediately after the YAML frontmatter:

1. **Provide Complete Context**: Include all relevant information in the prompt parameter
2. **Be Specific**: Give clear, actionable instructions to the subagent
3. **Enable Autonomy**: Provide enough context for the subagent to work independently
4. **Use Parallel Execution**: Launch multiple Task tools simultaneously when appropriate

**Effective Task Tool Pattern:**

```python
Task(
    description="Brief task summary",  # 3-5 words
    subagent_type="exact-agent-name",  # Must match agent filename
    prompt="Detailed instructions including:\n" +
           "- Specific requirements\n" +
           "- Context and background\n" +
           "- Success criteria\n" +
           "- Any constraints or preferences"
)
```

**Parallel Execution Example:**

```python
# Launch multiple agents simultaneously
Task(description="Python implementation", subagent_type="python-developer", prompt="...")
Task(description="Test creation", subagent_type="test-architect", prompt="...")
Task(description="Documentation", subagent_type="docs-expert", prompt="...")
```

## Memory Integration Protocol

**BEFORE RESPONDING TO ANY USER MESSAGE, QUERY MEMORY FOR RELEVANT CONTEXT.**

When receiving a user message:

1. Use `mcp__graphiti-memory__search_memory_nodes` to search for relevant entities related to the user's query
2. Use `mcp__graphiti-memory__search_memory_facts` to find relevant relationships and facts
3. Include any relevant memory context in your response to provide better, more personalized assistance
4. Store important new information from conversations using `mcp__graphiti-memory__add_memory`

This ensures continuity and context-aware responses across all interactions.

## Quick Reference: Command-Line Tools

- **`jq`**: Use for querying and transforming JSON data.

  - **Example (Pretty-print)**:
    ```bash
    jq . data.json
    ```
  - **Example (Extract a value)**:
    ```bash
    jq -r '.key.subkey' data.json
    ```

- **`yq`**: Use for querying and editing YAML data.

  - **Example (Read a value)**:
    ```bash
    yq '.services.web.image' docker-compose.yml
    ```
  - **Example (Update in-place)**:
    ```bash
    yq -i '.version = "2.1.0"' config.yml
    ```

- **`jd`**: Use for diffing and patching JSON files.

  - **Example (Show differences)**:
    ```bash
    jd v1.json v2.json
    ```
  - **Example (Apply a patch file)**:
    ```bash
    jd -p patch.json v1.json
    ```

- **`fd`**: Use as a fast, user-friendly alternative to `find`.

  - **Example (Find files by pattern)**:
    ```bash
    fd 'ReportGenerator'
    ```
  - **Example (Find by extension)**:
    ```bash
    fd -e md
    ```

- **`rg` (ripgrep)**: Use as a fast, recursive alternative to `grep` that respects `.gitignore`.

  - **Example (Find a string in all files)**:
    ```bash
    rg 'DATABASE_URL'
    ```
  - **Example (Find a string in a specific file type)**:
    ```bash
    rg 'TODO' -t python
    ```

- **`lsd`**: Use as a modern replacement for `ls` with better visuals.

  - **Example (List files with details and icons)**:
    ```bash
    lsd -l
    ```
  - **Example (Display directory hierarchy)**:
    ```bash
    lsd --tree
    ```

- **`mermaid-cli`**: Use for generating diagrams from text definitions (diagrams as code). It uses Mermaid.js, which is also supported directly in Markdown on platforms like GitHub.

  - **Example (Input file `flow.mmd`)**:
    ```mermaid
    graph TD;
        A[Start] --> B{Is it working?};
        B -- Yes --> C[End];
        B -- No --> D[Check logs];
        D --> B;
    ```
  - **Example (Generate an SVG diagram)**:
    ```bash
    mmdc -i flow.mmd -o flow.svg
    ```

- **LSP & Vectorcode**: Use for deep codebase understanding.

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
