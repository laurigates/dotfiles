# ADR-0010: Tiered Test Execution with Specialized Agents

## Status

Accepted

## Date

2024-12 (retroactively documented 2025-12)

## Context

The dotfiles repository and projects it manages require testing across multiple dimensions:
- Unit tests for individual functions
- Integration tests for component interactions
- End-to-end tests for full workflows
- Configuration validation tests
- Cross-platform compatibility tests

### The Flat Testing Problem

Early testing followed a "run all tests" approach:

```bash
make test  # Runs everything, every time
```

**Problems:**

1. **Slow feedback** - 10+ minute test suites for small changes
2. **Wasted resources** - E2E tests run for typo fixes
3. **Developer friction** - Long waits discourage frequent testing
4. **CI bottlenecks** - All PRs wait for full suite

### Test Duration Analysis

| Test Type | Typical Duration | When Needed |
|-----------|------------------|-------------|
| Unit | < 30 seconds | Every change |
| Integration | 1-5 minutes | Feature completion |
| E2E | 5-30 minutes | Before commit/PR |
| Performance | 10-60 minutes | Release candidates |

Running all tests for every change wastes 95%+ of test execution time.

### Agent Expertise Gap

Different test scenarios require different expertise:
- **Test failures**: Need failure analysis, not test design
- **New features**: Need test strategy, not just execution
- **Flaky tests**: Need debugging, not more test runs
- **Coverage gaps**: Need architectural guidance

A single "test" command couldn't provide specialized responses.

## Decision

**Implement tiered test execution** with specialized testing agents, exposed via namespace-organized commands.

### Test Tiers

| Tier | Duration | Trigger | Command |
|------|----------|---------|---------|
| **Unit** | < 30s | Every change | `/test:quick` |
| **Integration** | < 5min | Feature completion | `/test:full` |
| **E2E** | < 30min | Before commit/PR | `/test:full` |

### Tier Selection Criteria

The `test-tier-selection` skill automatically determines appropriate tier:

```
Change scope analysis:
├─ Single file, isolated function → Unit tier
├─ Multiple files, same module → Integration tier
├─ Cross-module changes → E2E tier
├─ Configuration changes → Full validation
└─ Documentation only → Skip tests
```

### Specialized Testing Agents

| Agent | Role | Capabilities |
|-------|------|--------------|
| `test-runner` | **Execution** | Run tests, analyze failures, report results |
| `test-architecture` | **Strategy** | Coverage analysis, framework selection, test design |
| `system-debugging` | **Investigation** | Root cause analysis, flaky test diagnosis |
| `code-review` | **Quality** | Test code review, assertion quality |

### Agent Selection Guide

| Scenario | Agent | Command |
|----------|-------|---------|
| Run tests, see results | `test-runner` | `/test:quick` or `/test:full` |
| New feature needs tests | `test-architecture` | `/test:consult new-feature` |
| Tests failing mysteriously | `system-debugging` | Direct delegation |
| Coverage dropped | `test-architecture` | `/test:consult coverage` |
| Flaky test detected | `system-debugging` | Direct delegation |
| Test code quality check | `code-review` | `/code:review` on test files |

### Command Structure

```
/test:quick     → Unit tests only (< 30s feedback)
/test:full      → All tiers (comprehensive)
/test:consult   → Consult test-architecture agent
/test:report    → Show last test results
/test:run       → Auto-detect and run appropriate tests
/test:setup     → Configure testing infrastructure
```

### Workflow Integration

**Development Cycle:**
```
1. Make change
2. /test:quick           → Immediate feedback (unit tests)
3. Continue development
4. /test:quick           → Verify each change
5. Feature complete
6. /test:full            → Comprehensive validation
7. /git:commit           → Commit with confidence
```

**TDD Loop (via /project-test-loop):**
```
1. RED: Write failing test
2. /test:quick           → Confirm failure
3. GREEN: Implement minimal code
4. /test:quick           → Confirm pass
5. REFACTOR: Improve code
6. /test:quick           → Verify no regression
```

### Agent Delegation Flow

```
User: "Run the tests"
  │
  ├─ /test:quick or /test:full
  │     └─ Delegates to test-runner agent
  │           └─ Executes tests
  │           └─ Analyzes failures
  │           └─ Reports concise summary
  │
  └─ If complex failures detected:
        └─ test-runner suggests: system-debugging agent
        └─ Orchestrator delegates for root cause analysis
```

### Failure Reporting Format

`test-runner` agent provides structured failure reports:

```
❌ 3 tests failed

1. test_auth_flow (tests/test_auth.py:42)
   Expected: 200
   Actual: 401
   Likely cause: Token expiration not handled

2. test_api_timeout (tests/test_api.py:87)
   TimeoutError after 30s
   Likely cause: Mock server not responding

3. test_config_load (tests/test_config.py:15)
   FileNotFoundError: config.yaml
   Likely cause: Missing test fixture

Suggested actions:
- Fix auth token refresh logic (test 1)
- Check mock server setup in conftest.py (test 2)
- Add config.yaml to test fixtures (test 3)
```

## Consequences

### Positive

1. **Fast feedback** - Unit tests in <30 seconds
2. **Appropriate testing** - Right tests for right changes
3. **Specialized expertise** - Agents match test scenarios
4. **Resource efficiency** - No unnecessary E2E for small changes
5. **Clear commands** - `/test:quick` vs `/test:full` intent is obvious
6. **Actionable reports** - Failure analysis, not just stack traces

### Negative

1. **Tier judgment** - Must decide which tier to run
2. **Agent selection** - Learning which agent for which scenario
3. **Configuration** - Initial setup of test tiers
4. **Potential gaps** - Wrong tier might miss issues

### Test Infrastructure Requirements

For full tier support, projects should have:

```
tests/
├── unit/           → Fast, isolated tests
├── integration/    → Component interaction tests
└── e2e/            → Full workflow tests

pytest.ini or pyproject.toml:
  markers:
    - unit: Fast unit tests
    - integration: Integration tests
    - e2e: End-to-end tests
```

### Framework Support

| Framework | Unit Command | Full Command |
|-----------|--------------|--------------|
| pytest | `pytest -m unit` | `pytest` |
| jest | `jest --testPathPattern=unit` | `jest` |
| cargo | `cargo test --lib` | `cargo test` |
| go | `go test -short` | `go test` |

### Metrics to Track

- **Time to feedback**: Unit test duration
- **Test reliability**: Flaky test rate
- **Coverage**: Per-tier coverage percentages
- **Agent accuracy**: Correct agent selection rate

## Alternatives Considered

### Single Test Command
One command runs all tests always.

**Rejected because**: Slow feedback, wasted resources, developer friction.

### Manual Tier Selection
Developer manually specifies which tests to run.

**Rejected because**: Cognitive load, inconsistent selection, easy to forget tiers.

### Parallel All Tests
Run all tiers in parallel for speed.

**Rejected because**: Resource intensive, still slow for E2E, overkill for small changes.

### Test on Commit Only
Only run tests on git commit.

**Rejected because**: Feedback too late, larger fix batches, more debugging.

## Related Decisions

- ADR-0004: Subagent-First Delegation Strategy (test agents are subagents)
- ADR-0005: Namespace-Based Command Organization (/test: namespace)
- ADR-0006: Documentation-First Development (TDD workflow)

## References

- Test commands: `exact_dot_claude/commands/test/`
- Test tier selection skill: `exact_dot_claude/skills/test-tier-selection/`
- test-runner agent: `exact_dot_claude/agents/test-runner/`
- test-architecture agent: `exact_dot_claude/agents/test-architecture/`
- TDD workflow: `exact_dot_claude/CLAUDE.md` (Tiered Test Execution section)
