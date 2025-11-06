---
allowed-tools: Read, Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git branch:*), Bash(git switch:*), Bash(git fetch:*), Bash(git push:*), Bash(gh pr create:*), Bash(gh repo view:*), Bash(pre-commit run:*), mcp__github__create_pull_request, mcp__github__get_issue, TodoWrite
argument-hint: [branch-name] [--base <branch>] [--direct] [--push] [--pr] [--draft] [--issue <num>] [--no-commit]
description: Complete workflow from changes to PR - analyze changes, create logical commits, push, and optionally create pull request
---

## Context

- Pre-commit checks: !`pre-commit run --all-files --show-diff-on-failure || true`
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
- `--no-split`: Force single-PR mode even with multiple logical groups (disables auto-splitting)

## Your task

1. **Parse parameters** from the command arguments

2. **Check current state**:
   - If on main/master and NOT --direct: MUST create feature branch
   - If --direct flag: stay on current branch
   - Otherwise: check if we need a new branch

3. **Branch creation** (unless --direct):
   - Fetch latest from origin: `git fetch origin`
   - If no branch name provided, delay branch naming until after change analysis
   - If branch name provided, create immediately: `git switch -c <branch-name> <base-branch>`

4. **Analyze changes and detect split requirement** (when --pr is present and --no-split not set):
   - Run `git status` and `git diff` to understand all changes
   - Classify files into logical groups:
     - **Linter/formatting group** (if present):
       - Files with only whitespace/formatting changes
       - Lock files (package-lock.json, Cargo.lock, yarn.lock, etc.)
       - Auto-generated files from linters (.eslintrc changes, prettier config)
     - **Feature/fix groups** (by area):
       - Group by top-level directory/module
       - Within directory, group by commit type
       - Keep related files together (implementation + tests + docs)
   - **Auto-split logic**:
     - If 2+ distinct logical groups detected → proceed to step 4a (multi-PR flow)
     - If single group or --no-split flag → proceed to step 4b (single-PR flow)
     - Log decision: "Creating {n} separate PRs for {n} logical groups" or "Single PR for unified changes"

4a. **Multi-PR flow** (automatic when 2+ groups detected):

- Create snapshot: `git stash push -u -m "smartcommit-multi-pr-$(date +%s)"`
- **For each logical group** (in order: linter first, then features):
  a. Generate branch name: `{type}/{description}-{YYYYMMDD}`
  - Linter group: `chore/linter-fixes-{YYYYMMDD}`
  - Other groups: `{type}/{area}-{YYYYMMDD}`
    b. Create branch: `git switch -c <branch-name> <base-branch>`
    c. Restore only group files: `git checkout stash@{0} -- <file1> <file2> ...`
    d. Stage files: `git add <files>`
    e. Create conventional commit for this group
    f. Push: `git push -u origin <branch-name>`
    g. Create PR with focused title and body for this specific change group
    h. Return to base: `git switch <base-branch>`
- **After all PRs created**:
  - Verify all files captured: `git stash show --name-only stash@{0}` and cross-check with created branches
  - Drop stash only if 100% of files accounted for: `git stash drop stash@{0}`
  - If any file unaccounted for: ERROR and preserve stash
  - Output summary: "Created {n} PRs: [URLs]"
- Skip steps 5-7 (already handled per-branch in this flow)

4b. **Single-PR flow** (existing behavior, unless --no-commit):

- Group related changes into logical commits within single branch
- For each logical group:
  - Execute the git add commands for those files
  - Execute the git commit command with a conventional commit message
- Continue to steps 5-7

5. **Grouping examples** (for multi-PR flow):

   **Example 1: Mixed changes requiring split**

   ```
   Changes detected:
   - src/auth/login.ts (authentication logic)
   - src/auth/oauth.ts (authentication logic)
   - tests/auth.test.ts (authentication tests)
   - docs/api.md (documentation)
   - README.md (documentation)
   - .eslintrc (linter config)
   - src/**/*.ts (whitespace fixes only)

   Groups created:
   1. chore/linter-fixes-20250104
      - .eslintrc + src/**/*.ts (formatting)
   2. feat/authentication-20250104
      - src/auth/* + tests/auth.test.ts
   3. docs/api-documentation-20250104
      - docs/api.md + README.md

   Result: 3 separate branches with 3 focused PRs
   ```

   **Example 2: Single focus (no split)**

   ```
   Changes detected:
   - src/auth/login.ts
   - src/auth/oauth.ts
   - tests/auth.test.ts

   Groups: Single logical group
   Result: 1 branch with 1 PR (existing behavior)
   ```

6. **Conventional commit format**:
   - feat: new feature
   - fix: bug fix
   - docs: documentation changes
   - style: formatting, missing semicolons, etc
   - refactor: code restructuring without changing behavior
   - test: adding or updating tests
   - chore: maintenance tasks, dependency updates (includes linter fixes)
   - perf: performance improvements
   - ci: CI/CD changes

7. **Push if requested** (single-PR flow only; multi-PR handles in step 4a):
   - If --push OR --pr flag: Execute `git push -u origin <branch-name>`
   - Handle both new branches and existing branches with new commits

8. **Create PR if requested** (single-PR flow only; multi-PR handles in step 4a):
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

9. **Output summary**:
   - Single-PR: Output the PR URL if created
   - Multi-PR: Output all PR URLs created

## Execution

Execute all git commands directly with the Bash tool. Show the user what's being done as you go.
