---
allowed-tools: Task, TodoWrite
argument-hint: [remote-branch] [--push] [--pr] [--draft] [--issue <num>] [--no-commit] [--range <start>..<end>]
description: Complete workflow from changes to PR - analyze changes, create logical commits, push to remote feature branch, and optionally create pull request
---

## Context

- Pre-commit config: !`find . -maxdepth 1 -name ".pre-commit-config.yaml"`
- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Unstaged changes: !`git diff --stat`
- Staged changes: !`git diff --cached --stat`
- Recent commits: !`git log --oneline -10`
- Remote status: !`git remote -v | head -1`
- Upstream status: !`git status -sb | head -1`

## Parameters

Parse these parameters from the command (all optional):

- `$1`: Remote branch name to push to (e.g., `feat/auth-oauth2`). If not provided, auto-generate from first commit type.
- `--push`: Automatically push to remote feature branch after commits
- `--pr` / `--pull-request`: Create pull request after pushing (implies --push)
- `--draft`: Create as draft PR (requires --pr)
- `--issue <num>`: Link to specific issue number (requires --pr)
- `--no-commit`: Skip commit creation (assume commits already exist)
- `--range <start>..<end>`: Push specific commit range instead of all commits on main

## Your task

**Delegate this task to the `git-operations` agent.**

Use the Task tool with `subagent_type: git-operations` to handle this commit workflow. Pass all the context gathered above and the parsed parameters to the agent.

The git-operations agent should use the **main-branch development workflow**:

1. **Ensure on main**: Verify working on main branch (warn if not)
2. **Analyze changes** and detect if splitting into multiple PRs is appropriate
3. **Group related changes** into logical commits on main
4. **Run pre-commit hooks** if configured
5. **Push to remote feature branch**: `git push origin main:<remote-branch>` (or commit range if --range specified)
6. **Create PR** if requested (--pr flag) with proper title, body, and issue linking

**Main-Branch Development Pattern:**

```bash
# All work stays on main
git push origin main:feat/branch-name        # Push main to remote feature branch
git push origin abc123^..def456:feat/branch  # Push commit range for multi-PR workflow
```

Provide the agent with:
- All context from the section above
- The parsed parameters
- The remote branch name (auto-generated or provided)
- Whether to use commit range for multi-PR workflow

The agent has expertise in:
- Main-branch development workflow
- Conventional commit formatting
- GitHub PR creation and linking
- Pre-commit hook integration
- Multi-PR commit range strategies

**Workflow Guidance:**

- After running pre-commit hooks, stage files modified by hooks using `git add -u`
- Unstaged changes after pre-commit are expected formatter output - stage them and continue
- Use `git push origin main:<remote-branch>` to push to remote feature branches
- For multi-PR workflow, use `git push origin <start>^..<end>:<remote-branch>` for commit ranges
- When encountering unexpected state, report findings and ask user how to proceed
- Include all pre-commit automatic fixes in commits
