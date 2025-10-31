---
allowed-tools: Read, Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git branch:*), Bash(git switch:*), Bash(git fetch:*), Bash(git push:*), Bash(gh pr create:*), Bash(gh repo view:*), Bash(pre-commit run:*), mcp__github__create_pull_request, mcp__github__get_issue, TodoWrite
argument-hint: [branch-name] [--base <branch>] [--direct] [--push] [--pr] [--draft] [--issue <num>] [--no-commit]
description: Complete workflow from changes to PR - analyze changes, create logical commits, push, and optionally create pull request
---

## Context

- Pre-commit checks: !`pre-commit run --all-files --show-diff-on-failure || true`
- Repo: !`gh repo view --json nameWithOwner`
- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Unstaged changes: !`git diff --stat`
- Staged changes: !`git diff --cached --stat`
- Recent commits: !`git log --oneline -5 2>/dev/null || echo "No commits yet"`
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

## Your task

1. **Parse parameters** from the command arguments

2. **Check current state**:
   - If on main/master and NOT --direct: MUST create feature branch
   - If --direct flag: stay on current branch
   - Otherwise: check if we need a new branch

3. **Branch creation** (unless --direct):
   - Fetch latest from origin: `git fetch origin`
   - Create branch from base: `git switch -c <branch-name> <base-branch>`
   - If no branch name provided, generate from first commit:
     - Format: `{type}/{brief-description}-{YYYYMMDD}`
     - Examples: `feat/auth-module-20250109`, `fix/login-validation-20250109`

4. **Analyze and commit changes** (unless --no-commit):
   - Run `git status` and `git diff` to understand all changes
   - Group related changes into logical commits
   - For each logical group:
     - Execute the git add commands for those files
     - Execute the git commit command with a conventional commit message

5. **Conventional commit format**:
   - feat: new feature
   - fix: bug fix
   - docs: documentation changes
   - style: formatting, missing semicolons, etc
   - refactor: code restructuring without changing behavior
   - test: adding or updating tests
   - chore: maintenance tasks, dependency updates
   - perf: performance improvements
   - ci: CI/CD changes

6. **Push if requested**:
   - If --push OR --pr flag: Execute `git push -u origin <branch-name>`
   - Handle both new branches and existing branches with new commits

7. **Create PR if requested** (only if --pr):
   - Generate PR title:
     - Use provided title if given as $1
     - Otherwise, derive from commit messages
   - Generate PR body:
     - List key changes from commits
     - Link to issue if --issue provided or detected in commits
     - Add "Closes #X" or "Fixes #X" if applicable
   - Create PR with gh CLI:
     - Add --draft flag if requested
     - Set base branch from --base parameter
     - Example: `gh pr create --title "..." --body "..." --base main`

8. **Output PR URL** if created

## Execution

Execute all git commands directly with the Bash tool. Show the user what's being done as you go.
