---
allowed-tools: Bash(git branch:*), Bash(git status:*), Bash(git diff:*), Bash(gh repo view:*), Bash(gh pr view:*), Bash(gh pr checks:*), Bash(git log:*), Bash(pytest:*), Bash(npm test:*), Bash(make test:*)
argument-hint: [pr-number] [--auto-fix] [--push]
description: Analyze and fix failing PR checks
---

## Context

- Get repo name with owner: !`gh repo view --json nameWithOwner`
- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Parameters

Parse these parameters from the command (all optional):
- `$1`: PR number (if not provided, detect from current branch)
- `--auto-fix`: Automatically apply fixes for common issues
- `--push`: Push fixes to the branch after committing

## Your task

1. **Parse parameters** from the command arguments

2. **Determine PR number**:
   - If $1 is provided: use PR #$1
   - Otherwise: detect from current branch with `gh pr view --json number --jq .number`

3. **Analyze PR check failures**:
   - Execute: `gh pr checks <pr-number> --watch` to see all checks
   - Identify failing checks and their error messages
   - Create a todo list to track each failing check

4. **For each failing check**:
   - Research the specific error messages and patterns
   - Run tests locally to reproduce the issue:
     - For Python: `pytest` or `python -m pytest`
     - For Node.js: `npm test` or `npm run test`
     - For Make-based: `make test`
   - Determine if it's a CI-specific issue or code problem

5. **Fix issues** (if --auto-fix):
   - Linting errors: Run appropriate linters/formatters
   - Type errors: Fix type annotations or implementations
   - Test failures: Fix failing tests or implementation bugs
   - Import errors: Fix missing dependencies or imports

6. **Commit and push** (if --push):
   - Stage fixed files with `git add`
   - Commit with descriptive message: `git commit -m "fix: resolve PR check failures"`
   - Push changes: `git push`

7. **Verify fixes**:
   - Re-run `gh pr checks <pr-number> --watch` to monitor progress
   - Report status of each check

## Execution
Execute all commands directly with the Bash tool. Use TodoWrite to track failing checks and their resolution. Show the user progress as you work through each issue.
