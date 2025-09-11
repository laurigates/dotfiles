---
allowed-tools: Bash(git branch:*), Bash(git status:*), Bash(git diff:*), Bash(gh repo view:*), Bash(git switch:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git log:*), Bash(git fetch:*), Bash(gh pr create:*)
argument-hint: [pr-title] [--base <branch>] [--draft] [--no-commit] [--issue <num>]
description: Complete PR workflow from any state with smart automation
---

## Context

- Repo: !`gh repo view --json nameWithOwner`
- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Uncommitted changes: !`git diff --name-status`
- Recent commits: !`git log --oneline -5 2>/dev/null || echo "No commits yet"`
- Upstream status: !`git status -sb | head -1`

## Parameters

Parse these parameters from the command (all optional):
- `$1`: PR title (if not provided, auto-generate from commits)
- `--base <branch>`: PR base branch (default: main)
- `--draft`: Create as draft PR
- `--no-commit`: Skip commit creation (assume commits already exist)
- `--issue <num>`: Link to specific issue number

## Your task

1. **Parse parameters** from the command arguments

2. **Detect current state**:
   - Check for uncommitted changes: `git status --porcelain`
   - Check current branch (main/master vs feature branch)
   - Check if branch has unpushed commits

3. **Handle uncommitted changes** (unless --no-commit):
   - If uncommitted changes exist, delegate to smartcommit:
     - Use `/git:smartcommit` to create logical commits
     - Ensure feature branch is created if on main
   - If no changes but on main, still create feature branch

4. **Ensure proper branch**:
   - If still on main/master after commits:
     - Create branch with smart naming
     - Format: `{type}/{description}-{YYYYMMDD}` based on commits
   - If already on feature branch: continue

5. **Push branch**:
   - Ensure branch is pushed: `git push -u origin <branch-name>`
   - Handle both new branches and existing branches with new commits

6. **Create PR**:
   - Generate PR title:
     - Use provided title if given
     - Otherwise, derive from commit messages
   - Generate PR body:
     - List key changes from commits
     - Link to issue if --issue provided or detected in commits
     - Add "Closes #X" or "Fixes #X" if applicable
   - Create PR with gh CLI:
     - Add --draft flag if requested
     - Set base branch from --base parameter

Output the executed commands as you work.
Show progress messages for each major step.

Example workflow (dirty state, no params):
# Detecting uncommitted changes...
git status --porcelain
# Creating commits with smartcommit...
[smartcommit commands]
# Pushing branch...
git push -u origin feat/new-feature-20250109
# Creating PR...
gh pr create --title "Add new feature" --body "..."

Example workflow (clean state with --no-commit):
# Branch already has commits, pushing...
git push -u origin current-branch
# Creating PR...
gh pr create --title "Custom title" --body "..." --draft
