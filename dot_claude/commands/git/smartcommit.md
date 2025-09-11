---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git branch:*), Bash(git switch:*), Bash(git fetch:*), Bash(git push:*)
argument-hint: [branch-name] [--base <branch>] [--direct] [--push]
description: Analyze changes and create logical commits with smart branch management
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Unstaged changes: !`git diff --stat`
- Staged changes: !`git diff --cached --stat`
- Remote status: !`git remote -v | head -1`

## Parameters

Parse these parameters from the command (all optional):
- `$1`: Custom branch name (if not provided, auto-generate from first commit type)
- `--base <branch>`: Base branch to create from (default: origin/main)
- `--direct`: Commit directly to current branch (skip branch creation)
- `--push`: Automatically push branch after commits

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

4. **Analyze and commit changes**:
   - Run `git status` and `git diff` to understand all changes
   - Group related changes into logical commits
   - For each logical group:
     - Output the exact git add commands for those files
     - Output a git commit command with a conventional commit message

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
   - If --push flag: `git push -u origin <branch-name>`

Output ONLY the shell commands, no explanations or markdown formatting.
Each command should be on its own line.

Example output (with branch creation):
git fetch origin
git switch -c feat/user-auth-20250109 origin/main
git add src/auth.js src/login.js
git commit -m "feat: add user authentication module"
git add README.md
git commit -m "docs: update API documentation"
git push -u origin feat/user-auth-20250109

Example output (with --direct flag):
git add file1.js file2.js
git commit -m "fix: resolve login validation issue"
git add README.md
git commit -m "docs: update troubleshooting guide"
