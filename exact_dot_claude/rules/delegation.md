# Delegation Strategy

**STRONGLY PREFER subagents for appropriate tasks.** Subagents provide specialized expertise, systematic investigation, and expert validation that significantly improves output quality.

## When to Delegate to Subagents (PRIORITIZE THIS)

- **Code exploration and research** - Use `Explore` agent instead of manual Grep/Glob
- **Security audits** - Use `security-audit` agent for OWASP analysis and vulnerability assessment
- **Code reviews** - Use `code-review` agent for quality, security, performance analysis
- **Debugging complex issues** - Use `system-debugging` agent for systematic root cause analysis
- **Documentation generation** - Use `documentation` agent for comprehensive docs from code
- **Test execution and analysis** - Use `test-runner` agent for running tests and concise failure summaries
- **Testing strategies** - Use `test-architecture` agent for test coverage and framework selection
- **CI/CD pipelines** - Use `cicd-pipelines` agent for GitHub Actions and deployment automation
- **Code refactoring** - Use `code-refactoring` agent for quality improvements and SOLID principles
- **Any multi-step task** requiring specialized domain knowledge or systematic investigation

## When to Handle Directly (EXCEPTIONS ONLY)

- **Simple, single-file edits** with crystal-clear requirements (e.g., "change variable name X to Y")
- **Straightforward text/documentation changes** (e.g., "fix typo in README line 42")
- **Quick file reading** for context gathering (single Read tool call)
- **Trivial operations** that would take longer to explain to a subagent than to execute

## Parallel Work - Orchestrate Accordingly

When a task can be decomposed into independent subtasks, launch multiple subagents simultaneously:

- **Identify independent work** - Tasks without dependencies can run in parallel
- **Maximize throughput** - Launch all independent agents in a single message
- **Orchestrate results** - Consolidate findings after parallel execution completes

**Examples of parallel work:**
- "Review code and run tests" → Launch `code-review` + `test-runner` simultaneously
- "Check security and update docs" → Launch `security-audit` + `documentation` simultaneously
- "Explore auth flow and find API usages" → Launch multiple `Explore` agents with different queries

## Decision Framework

1. **Default to subagents** - When in doubt, delegate
2. **Parallelize when possible** - Identify independent subtasks and orchestrate accordingly
3. **State your reasoning** - If handling directly, explicitly explain why delegation isn't appropriate
4. **Consider complexity** - If task requires >3 tool calls or domain expertise, delegate
5. **Think systematically** - Subagents provide structured investigation and validation

## Decision Tree

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
