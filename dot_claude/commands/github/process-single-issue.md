# Process Single GitHub Issue

Process and fix a single GitHub issue with comprehensive workflow.

## Usage
```bash
claude chat --file ~/.claude/commands/github/process-single-issue.md [ISSUE_NUMBER]
```

## Arguments
- `ISSUE_NUMBER`: The issue number to process (e.g., 42)

## Workflow

1. **Pre-flight Check**
   - Use GitHub MCP to check for unmerged pull requests
   - If unmerged PRs exist, prompt user to handle them first
   - Ensure working directory is clean

2. **Branch Setup**
   ```bash
   git switch main && git pull
   git switch -c fix-issue-${ISSUE_NUMBER}
   ```

3. **Issue Analysis**
   - Fetch issue details using GitHub MCP: `mcp__github__get_issue`
   - Analyze issue description and requirements
   - Use zen-mcp-server to understand root cause with Gemini Pro

4. **Planning**
   - Use planner tool to generate detailed implementation plan
   - Break down into manageable subtasks
   - Identify test requirements

5. **Test-Driven Development**
   - Write tests that reproduce the issue (RED phase)
   - Verify tests fail as expected
   - Document expected behavior

6. **Implementation**
   - Implement fixes following the plan
   - Ensure tests pass (GREEN phase)
   - Refactor if needed (REFACTOR phase)

7. **Validation**
   - Run precommit checks using codereview continuation
   - Verify all tests pass
   - Check for regressions

8. **Commit**
   ```bash
   git add -A
   git commit -m "fix: <description>

   Fixes #${ISSUE_NUMBER}"
   ```

9. **Pull Request**
   - Push branch: `git push -u origin fix-issue-${ISSUE_NUMBER}`
   - Create PR using GitHub MCP with issue reference
   - Link PR to issue for automatic closure

10. **Cleanup**
    - Switch back to main: `git switch main`
    - Optional: Delete local branch after PR merge

## Error Handling
- If tests don't pass, iterate on implementation
- If PR checks fail, fix issues before merge
- Keep issue updated with progress comments

## Success Criteria
- Issue is fully resolved
- Tests cover the fix
- PR passes all checks
- Code follows project conventions
