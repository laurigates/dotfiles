---
allowed-tools: Task, TodoWrite
description: Process multiple GitHub issues in sequence
argument-hint: [--filter <label>] [--limit <n>]
---

## Context

- Repo: !`gh repo view --json nameWithOwner`
- Open issues: !`gh issue list --state open --json number,title,labels`
- Open PRs: !`gh pr list --state open --json number,title,state`
- Current branch: !`git branch --show-current`

## Parameters

Parse these parameters from the command (all optional):
- `--filter <label>`: Filter issues by label
- `--limit <n>`: Maximum number of issues to process

## Your task

**Delegate this task to the `git-operations` agent.**

Use the Task tool with `subagent_type: git-operations` to process multiple GitHub issues in sequence. Pass all the context gathered above and the parsed parameters to the agent.

The git-operations agent should:

1. **Check for unmerged PRs** and prompt user if found
2. **Filter issues** based on --filter label if provided
3. **Limit issue count** based on --limit if provided
4. **For each open issue**:
   - Switch to main and pull: `git switch main && git pull`
   - Create feature branch: `git switch -c fix-issue-<number>`
   - Analyze issue requirements
   - Write failing tests (RED phase)
   - Implement fix until tests pass (GREEN phase)
   - Run pre-commit checks
   - Commit with `Fixes #<number>` in message
   - Push and create PR via GitHub
   - Switch back to main for next issue

Provide the agent with:
- All context from the section above
- The parsed parameters (--filter, --limit)
- The project's testing framework
- Any coding standards or conventions

The agent has expertise in:
- Bulk issue processing workflows
- TDD methodology
- Git branch management
- GitHub API operations
- Sequential task orchestration
