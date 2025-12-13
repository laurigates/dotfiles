# Development Process

## Documentation-First

- Research relevant documentation using context7 before implementation
- Verify syntax and parameters against official documentation
- Check for breaking changes and version compatibility
- Validate configuration options against current documentation

## PRD-First Development

- Every new feature or significant change MUST have a Product Requirements Document (PRD)
- PRDs must be created before any implementation begins
- Use the requirements-documentation agent for comprehensive PRDs

## Test-Driven Development (TDD)

Follow strict RED → GREEN → REFACTOR workflow:

1. **RED**: Write a failing test that defines desired behavior
2. **GREEN**: Implement minimal code to make the test pass
3. **REFACTOR**: Improve code quality while keeping tests green
4. Run full test suite to verify no regressions

### Tiered Test Execution

| Tier | When to Run | Command | Duration |
|------|-------------|---------|----------|
| Unit | After every change | `/test:quick` | < 30s |
| Integration | After feature completion | `/test:full` | < 5min |
| E2E | Before commit/PR | `/test:full` | < 30min |

### Testing Agent Consultation

| Scenario | Agent |
|----------|-------|
| Run tests, analyze failures | `test-runner` |
| New feature test strategy | `test-architecture` |
| Complex test failures | `system-debugging` |
| Test code quality review | `code-review` |

## Version Control

- Commit early and often to track incremental changes
- Use conventional commits for clear history and automation
- Always pull before creating a branch
- Run security checks before staging files

## Development Practices

- Use `tmp/` directory in the project root for temporary test outputs and command results
- Ensure `tmp/` is added to `.git/info/exclude` to prevent tracking
- Prefer to stay in the repository root directory
- Specify paths as command arguments to maintain clarity and avoid directory context switching
