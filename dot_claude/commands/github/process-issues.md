---
allowed-tools: Read, Write, Edit, MultiEdit, Bash(git:*), mcp__github__list_issues, mcp__github__get_issue, mcp__github__update_issue, TodoWrite
description: Process multiple GitHub issues in sequence
argument-hint: [--filter <label>] [--limit <n>]
---

## Context

- Repo: !`gh repo view --json nameWithOwner`
- Open issues: !`gh issue list --state open --json number,title,labels`
- Open PRs: !`gh pr list --state open --json number,title,state`
- Current branch: !`git branch --show-current`

## Your task

- Check for unmerged PRs first (prompt user if found)
- For each open issue:
  - Switch to main and pull: `git switch main && git pull`
  - Create feature branch: `git switch -c fix-issue-<number>`
  - Analyze issue with zen-mcp-server (gemini pro)
  - Generate plan with planner tool
  - Write failing tests to detect issue
  - Implement fix until tests pass
  - Run precommit check (continue from previous codereview)
  - Commit with `Fixes #<number>` in message
  - Push and create PR via GitHub MCP
  - Switch back to main for next issue
