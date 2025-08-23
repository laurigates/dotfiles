# Code Review Command

Perform comprehensive code review with automated fixes using zen-mcp-server.

## Usage
```bash
claude chat --file ~/.claude/commands/codereview.md [PATH]
```

## Arguments
- `PATH` (optional): Directory or file to review (defaults to current directory)

## Workflow

1. **Initial Analysis**
   - Use `mcp__zen-mcp-server__codereview` with Gemini Pro model
   - Specify review type (full, security, performance, or quick)
   - Set confidence level and thinking mode based on complexity

2. **Planning Phase**
   - Use `mcp__zen-mcp-server__planner` to generate detailed action plan
   - Identify critical issues requiring immediate attention
   - Prioritize fixes by impact and complexity

3. **Review Categories**
   - **Code Quality**: Naming, structure, readability, maintainability
   - **Security**: Vulnerabilities, input validation, authentication, secrets
   - **Performance**: Bottlenecks, memory leaks, optimization opportunities
   - **Architecture**: Design patterns, SOLID principles, coupling issues
   - **Testing**: Coverage gaps, test quality, edge cases

4. **Issue Documentation**
   Each identified issue includes:
   - Severity level (critical, high, medium, low)
   - File location and line numbers
   - Clear description of the problem
   - Suggested fix with code example
   - Impact assessment

5. **Automated Fixes**
   - Generate fixes for identified issues
   - Apply fixes incrementally with validation
   - Maintain git history for rollback capability

6. **Validation**
   - Run existing tests after each fix
   - Use `mcp__zen-mcp-server__precommit` for final validation
   - Continue from previous codereview context for consistency
   - Ensure no regressions introduced

7. **Report Generation**
   - Summary of issues found and fixed
   - Remaining issues requiring manual intervention
   - Recommendations for long-term improvements
   - Metrics: issues by category and severity

## Configuration Options

```yaml
review_type: full           # full, security, performance, quick
severity_filter: all        # critical, high, medium, low, all
auto_fix: true             # Apply fixes automatically
standards: project         # project, pep8, google, custom
thinking_mode: high        # minimal, low, medium, high, max
```

## Integration Points

- **Memory**: Stores review patterns in Graphiti for learning
- **Pre-commit**: Validates changes before committing
- **CI/CD**: Can be triggered in GitHub Actions
- **Documentation**: Updates code comments and docstrings

## Success Criteria
- All critical issues addressed
- Code quality metrics improved
- Tests still passing
- No new vulnerabilities introduced
- Performance maintained or improved
