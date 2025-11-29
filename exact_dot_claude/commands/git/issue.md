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

The git-operations agent should use the **main-branch development workflow**:

1. **Ensure clean working directory** (commit or stash if needed)
2. **Switch to main and pull latest**: `git switch main && git pull`
3. **Analyze issue requirements** from the issue details
4. **Write failing tests first** (RED phase)
5. **Implement fix** until tests pass (GREEN phase)
6. **Refactor** if needed (REFACTOR phase)
7. **Commit on main** with message referencing issue: `Fixes #$1`
8. **Push to remote issue branch**: `git push origin main:fix/issue-$1`
9. **Create PR** from `fix/issue-$1` to `main`, linked to the issue

**Main-Branch Development Pattern:**

```bash
# All work stays on main
git switch main && git pull
# ... make changes, commit on main ...
git push origin main:fix/issue-$1    # Push to remote feature branch
# Create PR: head=fix/issue-$1, base=main
```

Provide the agent with:
- All context from the section above
- The issue number: $1
- The project's testing framework
- Any coding standards or conventions

The agent has expertise in:
- Main-branch development workflow
- TDD workflow (RED → GREEN → REFACTOR)
- GitHub issue and PR linking
- Conventional commit messages
