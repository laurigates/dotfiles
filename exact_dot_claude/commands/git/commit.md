---
allowed-tools: Task, TodoWrite
argument-hint: [branch-name] [--base <branch>] [--direct] [--push] [--pr] [--draft] [--issue <num>] [--no-commit]
description: Complete workflow from changes to PR - analyze changes, create logical commits, push, and optionally create pull request
---

## Context

- Pre-commit config: !`find . -maxdepth 1 -name ".pre-commit-config.yaml"`
- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Unstaged changes: !`git diff --stat`
- Staged changes: !`git diff --cached --stat`
- Recent commits: !`git log --oneline -5`
- Remote status: !`git remote -v | head -1`
- Upstream status: !`git status -sb | head -1`

## Parameters

Parse these parameters from the command (all optional):

- `$1`: Custom branch name (if not provided, auto-generate from first commit type)
- `--base <branch>`: Base branch to create from (default: main)
- `--direct`: Commit directly to current branch (skip branch creation)
- `--push`: Automatically push branch after commits
- `--pr` / `--pull-request`: Create pull request after pushing (implies --push)
- `--draft`: Create as draft PR (requires --pr)
- `--issue <num>`: Link to specific issue number (requires --pr)
- `--no-commit`: Skip commit creation (assume commits already exist)
- `--no-split`: Force single-PR mode even with multiple logical groups (disables auto-splitting)

## Your task

**Delegate this task to the `git-operations` agent.**

Use the Task tool with `subagent_type: git-operations` to handle this commit workflow. Pass all the context gathered above and the parsed parameters to the agent.

The git-operations agent should:

1. **Check current state** and determine if branch creation is needed
2. **Create branch** (unless --direct flag)
3. **Analyze changes** and detect if splitting into multiple PRs is appropriate
4. **Group related changes** into logical commits
5. **Run pre-commit hooks** if configured
6. **Push** if requested (--push or --pr flag)
7. **Create PR** if requested (--pr flag) with proper title, body, and issue linking

Provide the agent with:
- All context from the section above
- The parsed parameters
- Any specific branch naming conventions or commit message preferences
- Whether to use multi-PR flow (auto-split) or single-PR flow

The agent has expertise in:
- Git workflows and branch management
- Conventional commit formatting
- GitHub PR creation and linking
- Pre-commit hook integration
- Multi-PR splitting strategies

**Workflow Guidance:**

- After running pre-commit hooks, stage files modified by hooks using `git add -u`
- Unstaged changes after pre-commit are expected formatter output - stage them and continue
- Branch operations (deletion, force push) require user confirmation first
- When encountering unexpected state, report findings and ask user how to proceed
- Include all pre-commit automatic fixes in commits
