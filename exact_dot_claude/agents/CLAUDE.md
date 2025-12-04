# CLAUDE.md - Agent Architecture

Comprehensive documentation for Claude Code's specialized agent system.

## Agent Architecture Philosophy

Claude Code uses specialized agents to handle domain-specific tasks systematically. The architecture enforces clean separation of concerns through a **fail-fast delegation pattern**:

- **Analysis agents** provide expert review, assessment, and recommendations (read-only)
- **Implementation agents** execute code changes and create artifacts (write-enabled)
- **Orchestrator** (main Claude instance) coordinates delegation between agents

## Core Principles

### Analysis Agents (Read-Only)

Analysis agents focus on their specialized domain without modifying code:

**Responsibilities:**
- Complete specialized analysis, review, or diagnostic work
- Report findings with clear, actionable recommendations
- Identify root causes and provide detailed context
- Suggest appropriate implementation agent for fixes
- Return control to orchestrator for delegation

**Tools:** Glob, Grep, LS, Read, Bash, BashOutput, TodoWrite, [MCP tools]

**Do NOT have:** Edit, MultiEdit, Write

### Implementation Agents (Write-Enabled)

Implementation agents execute changes based on specifications:

**Responsibilities:**
- Complete their primary mission (refactoring, fixing, creating)
- Execute code changes with full write access
- Implement specifications provided by analysis agents or users

**Tools:** Glob, Grep, LS, Read, Edit, MultiEdit, Write, Bash, BashOutput, TodoWrite, [MCP tools]

### Orchestration Pattern

When an analysis agent encounters blocking issues:

1. Analysis agent completes its diagnostic/review work
2. Agent reports findings with file:line references
3. Agent suggests appropriate implementation agent
4. Agent returns control to orchestrator
5. Orchestrator delegates to implementation agent
6. Implementation agent executes fixes
7. Return to original agent if needed (e.g., rerun tests)

## Agent Catalog

### Analysis Agents (9)

| Agent | Purpose | Key Capabilities |
|-------|---------|------------------|
| **code-analysis** | Deep code analysis, semantic search, LSP capabilities | Code structure, diagnostics, advanced searches |
| **code-review** | Code quality, security, performance review | Quality analysis, architecture assessment |
| **commit-review** | Commit analysis for quality, security, consistency | Code quality review, vulnerability scanning |
| **research-documentation** | Documentation lookup, technical research | Context gathering, system understanding |
| **security-audit** | Security analysis, vulnerability scanning, compliance | OWASP Top 10, dependency audits, threat modeling |
| **test-runner** | Test execution, failure analysis, concise reporting | Run tests, analyze failures, report results |
| **test-architecture** | Testing strategy, coverage analysis, framework selection | Test design, quality gates, automation strategy |
| **service-design** | UX architecture, service blueprints, interaction design | Journey mapping, accessibility, design systems |
| **system-debugging** | Root cause analysis, performance profiling, system tracing | Memory leaks, concurrency, distributed systems |

### Implementation Agents (12)

| Agent | Purpose | Key Capabilities |
|-------|---------|------------------|
| **api-integration** | REST API exploration and integration | Endpoint discovery, schema inference, client generation |
| **cicd-pipelines** | GitHub Actions, deployment automation, build optimization | Workflow creation, pipeline monitoring |
| **code-refactoring** | Code improvements, SOLID principles, design patterns | Quality improvement, behavior-preserving refactoring |
| **documentation** | Generate docs from code, API references, README creation | Comprehensive documentation, GitHub Pages |
| **dotfiles-manager** | Dotfiles management with chezmoi | Cross-platform configuration, reproducible environments |
| **javascript-development** | Modern ES2024+, async patterns, ecosystem tooling | JavaScript/TypeScript projects, modern features |
| **linter-fixer** | Fix linting and formatting issues | Automated lint fixes, code style enforcement |
| **python-development** | Modern Python 3.12+, type hints, async patterns | Python projects, uv/ruff tooling |
| **requirements-documentation** | Create Product Requirements Documents (PRDs) | PRD generation before implementation |
| **rust-development** | Modern Rust 2024+, ownership patterns, systems programming | Rust projects, memory safety, concurrency |
| **typescript-development** | TypeScript type system, compiler configuration, modern patterns | TypeScript projects, type safety |
| **ux-implementation** | Implement UX designs, accessibility compliance (WCAG/ARIA) | Component implementation, design tokens |

## Delegation Patterns

### Common Delegation Flows

**Test Failure → Fix:**
```
test-runner (analysis)
  └→ Detects test failures
  └→ Reports file:line, expected vs actual
  └→ Suggests: code-refactoring (for bugs) or test-architecture (for test design)
  └→ Returns to orchestrator
     └→ code-refactoring (implementation)
        └→ Fixes bugs
        └→ Returns to orchestrator
           └→ test-runner (analysis)
              └→ Reruns tests, verifies fixes
```

**Security Issue → Remediation:**
```
security-audit (analysis)
  └→ Identifies vulnerabilities
  └→ Reports severity, file:line, OWASP category
  └→ Suggests: code-refactoring or appropriate language agent
  └→ Returns to orchestrator
     └→ code-refactoring (implementation)
        └→ Remediates security issues
```

**Design → Implementation:**
```
service-design (analysis)
  └→ Creates UX specifications
  └→ Documents interaction patterns
  └→ Uses @HANDOFF markers
  └→ Suggests: ux-implementation
  └→ Returns to orchestrator
     └→ ux-implementation (implementation)
        └→ Implements design
```

### Delegation Targets Reference

When analysis agents need implementation work delegated:

| Need | Delegate To |
|------|-------------|
| Code improvements, bug fixes | code-refactoring |
| Linting and formatting | linter-fixer |
| Language-specific implementation | [language]-development agents |
| UI/UX code changes | ux-implementation |
| Documentation file updates | documentation |
| Test implementation | code-refactoring or [language]-development |
| CI/CD pipeline changes | cicd-pipelines |

## Tool Configuration Reference

### Analysis Agent Standard Tools
```yaml
tools: Glob, Grep, LS, Read, Bash, BashOutput, TodoWrite, [MCP tools]
```

**Rationale:**
- Read-only access prevents scope creep
- Bash for running diagnostic commands (not file editing)
- TodoWrite for task tracking
- MCP tools for specialized domain knowledge

### Implementation Agent Standard Tools
```yaml
tools: Glob, Grep, LS, Read, Edit, MultiEdit, Write, Bash, BashOutput, TodoWrite, [MCP tools]
```

**Rationale:**
- Full write access to complete implementation work
- Edit/MultiEdit for targeted file modifications
- Write for creating new files
- Bash for build/test commands

## Role-Scope Guidance Template

All analysis agents include this guidance pattern:

```markdown
<role-scope>
[Agent-specific purpose statement]

When [implementation work] is needed:
- [Provide detailed specifications/reports]
- [Identify specific locations and requirements]
- Suggest delegation to [appropriate implementation agent]
- Use @HANDOFF markers to indicate implementation requirements
- Return control to orchestrator for delegation
</role-scope>
```

This guidance:
- Clarifies the agent's advisory role
- Frames delegation positively (focus on what to do)
- Provides clear handoff patterns
- Maintains clean separation of concerns

## Benefits of This Architecture

### Clean Separation of Concerns
- Agents stay within their domain expertise
- Analysis agents don't implement fixes
- Implementation agents execute clear specifications

### Explicit Delegation Chains
- Delegation patterns are visible and traceable
- Orchestrator coordinates cross-domain work
- No hidden bash workarounds (sed/awk/perl)

### Fail-Fast Feedback
- Analysis agents complete work quickly
- Blocking issues are reported immediately
- Proper agent handles implementation

### Maintainable Agent Design
- Each agent has clear, focused purpose
- Tool configurations match responsibilities
- Easy to reason about agent capabilities

## Agent Development Guidelines

When creating or modifying agents:

1. **Determine category:** Is this analysis or implementation work?
2. **Set tools appropriately:** Read-only for analysis, write-enabled for implementation
3. **Add role-scope guidance:** Help agent understand delegation patterns
4. **Document purpose clearly:** Agent description should reflect category
5. **Test delegation flow:** Verify agent reports issues appropriately

## Historical Context

Prior to this architecture, some agents (test-runner, test-architecture, service-design, system-debugging) had write tools despite being analysis-focused. This led to:

- Agents using bash workarounds (Perl scripts, sed/awk) to edit files
- Scope creep beyond intended domain
- Unclear delegation patterns
- Mixed responsibilities

The fail-fast architecture was implemented to enforce clean separation and make delegation explicit.

## Future Considerations

**Potential enhancements:**
- @HANDOFF marker automation for seamless delegation
- Agent delegation metrics and optimization
- Cross-agent collaboration patterns
- Delegation chain visualization

**Stability considerations:**
- Maintain strict tool configurations per category
- Keep role-scope guidance positive and clear
- Document new delegation patterns as they emerge
- Regular audits to ensure consistency

---

**Last Updated:** 2025-12-04
**Total Agents:** 21 (9 analysis, 12 implementation)
**Architecture Version:** 1.0 (Fail-Fast Delegation Pattern)
