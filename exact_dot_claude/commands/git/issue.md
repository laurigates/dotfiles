---
allowed-tools: Task, TodoWrite
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

**Delegate this task to the `git-operations` agent.**

Use the Task tool with `subagent_type: git-operations` to process and fix GitHub issue #$1 using a TDD workflow. Pass all the context gathered above to the agent.

The git-operations agent should:

1. **Ensure clean working directory** (commit or stash if needed)
2. **Switch to main and pull latest**: `git switch main && git pull`
3. **Create issue branch**: `git switch -c fix-issue-$1`
4. **Analyze issue requirements** from the issue details
5. **Write failing tests first** (RED phase)
6. **Implement fix** until tests pass (GREEN phase)
7. **Refactor** if needed (REFACTOR phase)
8. **Commit** with message referencing issue: `Fixes #$1`
9. **Push branch and create PR** linked to the issue

Provide the agent with:
- All context from the section above
- The issue number: $1
- The project's testing framework
- Any coding standards or conventions

The agent has expertise in:
- TDD workflow (RED → GREEN → REFACTOR)
- Git branch management
- GitHub issue and PR linking
- Conventional commit messages
