# ADR-0006: Documentation-First Development

## Status

Accepted

## Date

2024-12 (retroactively documented 2025-12)

## Context

The dotfiles repository evolved from a simple configuration collection to a complex system with:
- 103+ skills with intricate activation patterns
- 76 slash commands across 14 namespaces
- 22 specialized agents with delegation rules
- Cross-platform templates and tool configurations
- CI/CD pipelines with automated workflows

### The Implementation-First Problem

Early development followed an implementation-first pattern:
1. Write code
2. Test manually
3. Document after (or never)

**Consequences:**

- **Undocumented features**: Skills and commands existed without clear usage guidance
- **Inconsistent patterns**: Each feature invented its own conventions
- **Knowledge silos**: Only the creator understood how features worked
- **Regression risk**: No clear specification to test against
- **Discovery failures**: Users couldn't find capabilities they didn't know existed

### The Context7 Revelation

Using the `context7` MCP server for documentation research revealed:
- Official documentation often contradicted assumptions
- Tool behaviors had changed between versions
- "Best practices" evolved faster than implementation
- Configuration options had undocumented interactions

Implementing features without checking current documentation led to:
- Using deprecated APIs
- Missing new capabilities
- Incompatible configurations
- Wasted rework cycles

### PRD-First Mandate

For significant features, the lack of upfront requirements caused:
- Scope creep during implementation
- Unclear success criteria
- Misaligned expectations
- Difficult code review (what was the goal?)

## Decision

**Adopt documentation-first development** with three pillars:

### 1. Research Before Implementation

Before writing any code:

```
1. Research relevant documentation using context7 and web search
2. Verify implementation approaches against official docs
3. Check for breaking changes and version compatibility
4. Validate configuration options against current documentation
```

**Tools:**
- `context7` MCP server for documentation lookup
- Web search for current best practices
- Official tool documentation

### 2. PRD-First for Significant Features

Every new feature or significant change MUST have a Product Requirements Document:

```markdown
# Feature Name PRD

## Problem Statement
What problem are we solving?

## Proposed Solution
How will we solve it?

## Success Criteria
How do we know it works?

## Non-Goals
What are we NOT doing?

## Technical Approach
Implementation strategy

## Testing Plan
How will we verify?
```

**Enforcement:**
- Use `requirements-documentation` agent for PRD generation
- PRD templates in `docs/` directory
- PRD review before implementation begins

### 3. Test-Driven Development (TDD)

Follow strict RED → GREEN → REFACTOR workflow:

```
1. RED: Write a failing test that defines desired behavior
2. GREEN: Implement minimal code to make the test pass
3. REFACTOR: Improve code quality while keeping tests green
4. Run full test suite to verify no regressions
```

**Tiered Test Execution:**

| Tier | When to Run | Duration |
|------|-------------|----------|
| Unit | After every change | < 30s |
| Integration | After feature completion | < 5min |
| E2E | Before commit/PR | < 30min |

### Implementation Checklist

Before implementing any change:

- [ ] Read relevant documentation sections thoroughly
- [ ] Verify syntax and parameters in official documentation
- [ ] Check for breaking changes and version compatibility
- [ ] Review best practices and recommended patterns
- [ ] Validate configuration options against current docs
- [ ] Check for deprecated features to avoid
- [ ] Confirm implementation matches current best practices

## Consequences

### Positive

1. **Reduced rework** - Documentation research catches issues early
2. **Consistent patterns** - PRDs establish conventions before code
3. **Clear success criteria** - Tests define expected behavior
4. **Knowledge preservation** - Documentation captures rationale
5. **Easier onboarding** - New contributors understand the "why"
6. **Better code review** - PRD provides review context

### Negative

1. **Initial slowdown** - Documentation takes time upfront
2. **Overhead for small changes** - PRD may be overkill for trivial fixes
3. **Documentation drift** - Must maintain docs alongside code
4. **Tool dependency** - Relies on context7 MCP availability

### Scope Guidelines

| Change Type | PRD Required? | Documentation Required? |
|-------------|---------------|------------------------|
| New feature | Yes | Yes |
| Significant refactor | Yes | Yes |
| Bug fix | No | Update if behavior changes |
| Typo fix | No | No |
| Dependency update | No | If breaking changes |
| New skill/command | Yes (brief) | Yes |

### Agent Integration

Testing agents consult based on scenario:

| Scenario | Agent |
|----------|-------|
| Run tests, analyze failures | `test-runner` |
| New feature test strategy | `test-architecture` |
| Complex test failures | `system-debugging` |
| Test code quality review | `code-review` |

Consult `test-architecture` agent when:
- Creating tests for new features
- Coverage drops or gaps identified
- Flaky tests detected
- Test framework decisions needed

## Alternatives Considered

### Pure TDD Without Documentation Research
Write tests first without researching current documentation.

**Rejected because**: Tests may encode incorrect assumptions about tool behavior.

### Documentation After Implementation
Write docs after code is complete (traditional approach).

**Rejected because**: Knowledge loss, inconsistent patterns, undocumented features.

### Wiki-Based Documentation
Maintain documentation in external wiki instead of repo.

**Rejected because**: Documentation drifts from code; not versioned together.

### Minimal Documentation
Only document public APIs and user-facing features.

**Rejected because**: Internal patterns need documentation for maintainability.

## Related Decisions

- ADR-0003: Skill Activation via Trigger Keywords (documentation enables discovery)
- ADR-0004: Subagent-First Delegation Strategy (agents enforce TDD)
- ADR-0007: Layered Knowledge Distribution (where documentation lives)

## References

- Core principles: `exact_dot_claude/CLAUDE.md` (Development Process section)
- PRD templates: `docs/` directory
- Test commands: `exact_dot_claude/commands/test/`
- requirements-documentation agent: `exact_dot_claude/agents/requirements-documentation/`
