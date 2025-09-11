---
allowed-tools: Bash(git branch:*), Bash(git status:*), Bash(git diff:*), Bash(gh repo view:*), Bash(gh pr view:*), Bash(git log:*)
description: Fix PR checks
---

## Context

- Get repo name with owner: !`gh repo view --json nameWithOwner`
- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## PR Detection

First, determine the PR number:
- If $1 is provided, use PR #$1
- If $1 is empty, get current branch's PR: !`gh pr view --json number --jq .number`

## Your task

- Gather information from GitHub about the checks failing in the detected PR and create a todo list to track them.
- Research documentation around the error
- Run the tests locally to see if the error is reproducible or CI specific
- Analyze each error and think about which subagent to delegate fixing it to
