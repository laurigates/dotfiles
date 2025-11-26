---
allowed-tools: Task, TodoWrite
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

**Delegate this task to the `git-operations` agent.**

Use the Task tool with `subagent_type: git-operations` to analyze and fix the failing PR checks. Pass all the context gathered above and the parsed parameters to the agent.

The git-operations agent should:

1. **Determine PR number** from argument or current branch
2. **Analyze PR check failures** using `gh pr checks`
3. **Identify failing checks** and research error messages
4. **Run tests locally** to reproduce issues
5. **Apply fixes** if --auto-fix flag is set:
   - Linting errors: Run appropriate linters/formatters
   - Type errors: Fix type annotations or implementations
   - Test failures: Fix failing tests or implementation bugs
6. **Commit and push** if --push flag is set
7. **Verify fixes** by re-running checks

Provide the agent with:
- All context from the section above
- The parsed parameters
- The project's testing framework (pytest, npm test, etc.)
- Any CI/CD configuration files if relevant

The agent has expertise in:
- GitHub Actions workflow analysis
- CI/CD failure debugging
- Common fix patterns for linting, types, and tests
- Git operations for committing and pushing fixes
