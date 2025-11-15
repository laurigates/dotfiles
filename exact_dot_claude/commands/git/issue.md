---
allowed-tools: Read, Write, Edit, MultiEdit, Bash(git:*), Bash(npm test:*), Bash(pytest:*), Bash(go test:*), Bash(make test:*), mcp__github__get_issue, mcp__github__update_issue, mcp__github__create_pull_request, TodoWrite
description: Process and fix a single GitHub issue with TDD workflow
argument-hint: <issue-number>
---

## Context

- Repo: !`gh repo view --json nameWithOwner`
- Current branch: !`git branch --show-current`
- Clean working tree: !`git status --porcelain | wc -l`
- Open PRs: !`gh pr list --state open --json number,title`
- Issue details: !`gh issue view $1 --json title,body,state,assignees`

## Your task

- Ensure working directory is clean (commit or stash if needed)
- Switch to main and pull latest: `git switch main && git pull`
- Create issue branch: `git switch -c fix-issue-$1`
- Analyze issue #$1 requirements
- Write failing tests first (RED phase)
- Implement fix until tests pass (GREEN phase)
- Refactor if needed (REFACTOR phase)
- Commit with message referencing issue: `Fixes #$1`
- Push branch and create PR linked to issue
