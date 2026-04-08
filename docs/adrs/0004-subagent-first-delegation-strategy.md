# ADR-0004: Subagent-First Delegation Strategy

## Status

Accepted

## Date

2024-12 (retroactively documented 2025-12)

## Context

Claude Code supports **subagents** - specialized agents that can be spawned to handle specific tasks. The dotfiles repository defines 22+ specialized agents for different domains:

- `Explore` - Code exploration and research
- `code-review` - Quality, security, performance analysis
- `test-runner` - Test execution and failure analysis
- `security-audit` - OWASP analysis and vulnerability assessment
- `system-debugging` - Root cause analysis
- `documentation` - Generate docs from code
- `cicd-pipelines` - GitHub Actions and deployment
- `code-refactoring` - Quality improvements, SOLID principles
- And 14+ more specialized agents

### The Quality Problem

When Claude handles complex tasks directly (without delegation), several issues emerge:

1. **Context overload** - Long conversations accumulate context, reducing response quality
2. **Inconsistent methodology** - Ad-hoc approaches to systematic tasks
3. **Missed edge cases** - Without specialized expertise, subtle issues escape notice
4. **No validation** - Single-pass execution without expert review

### Subagent Advantages

Subagents provide:

1. **Specialized expertise** - Each agent has domain-specific knowledge
2. **Systematic investigation** - Agents follow consistent methodologies
3. **Fresh context** - New agents start with clean context
4. **Parallel execution** - Independent tasks run simultaneously
5. **Expert validation** - Specialized review catches domain-specific issues

### The Over-Engineering Risk

However, delegation has costs:
- **Latency** - Spawning agents takes time
- **Coordination overhead** - Managing multiple agents adds complexity
- **Simple task bloat** - Trivial edits don't need specialized agents

The challenge: **When should Claude delegate vs. handle directly?**

## Decision

**Default to subagent delegation** for any task matching specialized domains, with explicit exceptions for trivial operations.

### Decision Framework

```
Task received
├─ Can it be split into independent subtasks?
│  └─ YES → Identify subtasks, launch multiple agents in parallel
├─ Is it code exploration/research?
│  └─ YES → Use Explore agent
├─ Does it match a specialized domain?
│  └─ YES → Use domain-specific agent
├─ Is it multi-step or complex?
│  └─ YES → Use general-purpose agent or appropriate specialist
├─ Is it a trivial single-file edit?
│  └─ YES → Use direct tools (state reasoning)
└─ When in doubt → Delegate to agent
```

### When to Delegate (Default)

| Task Type | Agent | Why Delegate |
|-----------|-------|--------------|
| Code exploration | `Explore` | Systematic codebase navigation |
| Security review | `security-audit` | OWASP expertise, vulnerability patterns |
| Code review | `code-review` | Quality, security, performance analysis |
| Complex debugging | `system-debugging` | Root cause analysis methodology |
| Documentation | `documentation` | Comprehensive doc generation |
| Test execution | `test-runner` | Failure analysis, concise reporting |
| Test strategy | `test-architecture` | Coverage analysis, framework selection |
| CI/CD work | `cicd-pipelines` | GitHub Actions expertise |
| Refactoring | `code-refactoring` | SOLID principles, quality patterns |

### When to Handle Directly (Exceptions)

Only handle directly when ALL conditions are met:

1. **Single file** - Edit confined to one file
2. **Crystal clear** - Requirements unambiguous
3. **Trivial scope** - Would take longer to explain than execute
4. **No domain expertise needed** - Generic text/code changes

**Examples of direct handling:**
- "Change variable name X to Y in this file"
- "Fix typo in README line 42"
- "Add this import statement"

**Counter-examples (should delegate):**
- "Find where error handling is implemented" → `Explore` agent
- "Review this code for security issues" → `security-audit` agent
- "This code is broken, help me fix it" → `system-debugging` agent

### Parallel Execution

When tasks are independent, launch multiple agents simultaneously:

```
"Review code and run tests"
  → Launch code-review + test-runner simultaneously

"Check security and update docs"
  → Launch security-audit + documentation simultaneously

"Explore auth flow and find API usages"
  → Launch multiple Explore agents with different queries
```

### Reasoning Transparency

When handling directly (exception case), explicitly state reasoning:

> "I'll handle this directly because it's a single-line typo fix in a known file. Delegating would add unnecessary overhead for this trivial change."

## Consequences

### Positive

1. **Consistent quality** - Specialized agents apply domain best practices
2. **Reduced errors** - Expert validation catches domain-specific issues
3. **Parallel throughput** - Independent tasks complete simultaneously
4. **Fresh context** - Agents avoid context pollution from long conversations
5. **Systematic approach** - Agents follow established methodologies
6. **Traceable decisions** - Explicit reasoning when not delegating

### Negative

1. **Latency overhead** - Agent spawning takes 1-3 seconds
2. **Coordination complexity** - Must track multiple agent results
3. **Potential over-delegation** - Trivial tasks routed to agents
4. **Learning curve** - Users may not understand agent selection

### Agent Selection Quick Reference

| User Says | Agent to Use |
|-----------|--------------|
| "Find...", "Where is...", "How does X work?" | `Explore` |
| "Review this code", "Check quality" | `code-review` |
| "Is this secure?", "Check for vulnerabilities" | `security-audit` |
| "Run the tests", "Why are tests failing?" | `test-runner` |
| "Help me debug", "This is broken" | `system-debugging` |
| "Generate docs", "Document this" | `documentation` |
| "Refactor this", "Improve code quality" | `code-refactoring` |
| "Set up CI", "Fix the workflow" | `cicd-pipelines` |

### Tiered Test Execution Integration

Testing follows a tiered model with agent mapping:

| Tier | Duration | Agent | When |
|------|----------|-------|------|
| Unit | < 30s | `test-runner` | After every change |
| Integration | < 5min | `test-runner` | After feature completion |
| E2E | < 30min | `test-runner` | Before commit/PR |

Complex test failures escalate to `system-debugging` agent.

## Alternatives Considered

### No Delegation (Direct Handling)
Handle all tasks directly without subagents.

**Rejected because**: Quality degrades with context accumulation; no specialized validation.

### User-Selected Delegation
Let users explicitly choose when to delegate.

**Rejected because**: Users shouldn't need to understand agent taxonomy; adds friction.

### Automatic Complexity Detection
Use heuristics to detect when tasks need delegation.

**Partially adopted**: Decision framework encodes complexity heuristics, but defaults to delegation.

### Agent Composition
Create meta-agents that coordinate multiple specialized agents.

**Future consideration**: Current manual orchestration works; may adopt as patterns stabilize.

## Related Decisions

- ADR-0003: Skill Activation via Trigger Keywords (skills inform agent behavior)
- ADR-0005: Namespace-Based Command Organization (commands invoke agents)
- ADR-0001: Chezmoi exact_ Directory Strategy (agent configs managed atomically)

## References

- Delegation strategy: `exact_dot_claude/CLAUDE.md`
- Agent definitions: `exact_dot_claude/agents/`
- Test tiers: `exact_dot_claude/CLAUDE.md` (Tiered Test Execution section)
