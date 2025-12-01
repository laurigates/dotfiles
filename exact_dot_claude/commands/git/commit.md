---
allowed-tools: Bash, Edit, Read, Glob, Grep, TodoWrite, mcp__github__create_pull_request
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

Execute this commit workflow using the **main-branch development pattern**:

### Step 1: Verify State

1. **Ensure on main**: Verify working on main branch (warn if not)
2. **Check for changes**: Confirm there are staged or unstaged changes to commit (unless --no-commit)

### Step 2: Create Commits (unless --no-commit)

1. **Analyze changes** and detect if splitting into multiple PRs is appropriate
2. **Group related changes** into logical commits on main
3. **Stage changes**: Use `git add -u` for modified files, `git add <file>` for new files
4. **Run pre-commit hooks** if configured: `pre-commit run`
5. **Handle pre-commit modifications**: Stage any files modified by hooks with `git add -u`
6. **Create commit** with conventional commit message format

### Step 3: Push to Remote (if --push or --pr)

Use the main-branch development pattern:

```bash
# Push main to remote feature branch
git push origin main:<remote-branch>

# Or push commit range for multi-PR workflow
git push origin <start>^..<end>:<remote-branch>
```

### Step 4: Create PR (if --pr)

Use `mcp__github__create_pull_request` with:
- `head`: The remote branch name (e.g., `feat/auth-oauth2`)
- `base`: `main`
- `title`: Derived from commit message
- `body`: Include summary and issue link if --issue provided
- `draft`: true if --draft flag set

## Workflow Guidance

- After running pre-commit hooks, stage files modified by hooks using `git add -u`
- Unstaged changes after pre-commit are expected formatter output - stage them and continue
- Use `git push origin main:<remote-branch>` to push to remote feature branches
- For multi-PR workflow, use `git push origin <start>^..<end>:<remote-branch>` for commit ranges
- When encountering unexpected state, report findings and ask user how to proceed
- Include all pre-commit automatic fixes in commits

## See Also

- **git-branch-pr-workflow** skill for detailed patterns
- **git-commit-workflow** skill for commit message conventions
