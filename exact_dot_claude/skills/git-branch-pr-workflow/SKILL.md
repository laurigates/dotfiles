---
name: Git Branch PR Workflow
description: Branch management, pull request workflows, and GitHub integration. Main-branch development pattern (push main to remote feature branches), modern Git commands (switch, restore), branch naming conventions, linear history, and GitHub MCP tools for PRs.
allowed-tools: Bash, Read, mcp__github__create_pull_request, mcp__github__list_pull_requests, mcp__github__update_pull_request
---

# Git Branch PR Workflow

Expert guidance for branch management, pull request workflows, and GitHub integration using modern Git commands and linear history practices.

## Core Expertise

- **Main-Branch Development**: Work on main locally, push to remote feature branches for PRs
- **Modern Git Commands**: Use `git switch` and `git restore` instead of checkout
- **Branch Naming**: Structured conventions (feat/, fix/, chore/, hotfix/)
- **Linear History**: Rebase-first workflow, squash merging, clean history
- **GitHub MCP Integration**: Use mcp__github__* tools instead of gh CLI

## Main-Branch Development (Preferred)

Develop directly on main, push to remote feature branches for PRs. This eliminates local branch management overhead.

### Basic Workflow

```bash
# All work happens on main
git switch main
git pull origin main

# Make changes, commit on main
git add file.ts
git commit -m "feat(auth): add OAuth2 support"

# Push to remote feature branch (creates PR target)
git push origin main:feat/auth-oauth2

# Create PR using GitHub MCP (head: feat/auth-oauth2, base: main)
```

### Multi-PR Workflow (Sequential Commits)

When you have commits for multiple PRs on main, push specific commit ranges to different remote branches:

```bash
# Commits on main:
# abc1234 feat(auth): add OAuth2 support       <- PR #1
# def5678 feat(auth): add token refresh        <- PR #1
# ghi9012 fix(api): handle timeout edge case   <- PR #2

# Push first 2 commits to auth feature branch
git push origin abc1234^..def5678:feat/auth-oauth2

# Push remaining commit to fix branch
git push origin ghi9012^..ghi9012:fix/api-timeout

# Alternative: push from a specific commit to HEAD
git push origin def5678..HEAD:fix/api-timeout
```

**Commit range patterns:**
- `git push origin <start>^..<end>:<remote-branch>` - Push commit range (inclusive)
- `git push origin <commit>..<commit>:<remote-branch>` - Push range (exclusive start)
- `git push origin <commit>..HEAD:<remote-branch>` - Push from commit to current HEAD
- `git push origin main:<remote-branch>` - Push entire main to remote branch

### Benefits

- **No local branch juggling** - Always on main
- **Always on latest main** - No branch drift
- **Clean local state** - No stale branches to clean up
- **Remote branches are ephemeral** - Deleted after PR merge
- **Simpler mental model** - One local branch, many remote targets

## Modern Git Commands (2025)

### Switch vs Checkout

Modern Git uses specialized commands instead of multi-purpose `git checkout`:

```bash
# Branch switching - NEW WAY (Git 2.23+)
git switch feature-branch          # vs git checkout feature-branch
git switch -c new-feature          # vs git checkout -b new-feature
git switch -                       # vs git checkout -

# Creating branches with tracking
git switch -c feature --track origin/feature
git switch -C force-recreate-branch
```

### Restore vs Reset/Checkout

File restoration is now handled by `git restore`:

```bash
# Unstaging files - NEW WAY
git restore --staged file.txt      # vs git reset HEAD file.txt
git restore --staged .             # vs git reset HEAD .

# Discarding changes - NEW WAY
git restore file.txt               # vs git checkout -- file.txt
git restore .                      # vs git checkout -- .

# Restore from specific commit
git restore --source=HEAD~2 file.txt    # vs git checkout HEAD~2 -- file.txt
git restore --source=main --staged .    # vs git reset main .
```

### Command Migration Guide

| Legacy Command                | Modern Alternative                 | Purpose             |
| ----------------------------- | ---------------------------------- | ------------------- |
| `git checkout branch`         | `git switch branch`                | Switch branches     |
| `git checkout -b new`         | `git switch -c new`                | Create & switch     |
| `git checkout -- file`        | `git restore file`                 | Discard changes     |
| `git reset HEAD file`         | `git restore --staged file`        | Unstage file        |
| `git checkout HEAD~1 -- file` | `git restore --source=HEAD~1 file` | Restore from commit |

## Branch Naming Conventions

### Structured Branch Names

```bash
# Feature development
git switch -c feat/payment-integration
git switch -c feat/user-dashboard
git switch -c feat/api-v2

# Bug fixes
git switch -c fix/login-validation
git switch -c fix/memory-leak-auth
git switch -c fix/broken-tests

# Maintenance and refactoring
git switch -c chore/update-dependencies
git switch -c chore/cleanup-tests
git switch -c refactor/auth-service

# Hotfixes (for production)
git switch -c hotfix/security-patch
git switch -c hotfix/critical-bug-fix
```

### Branch Naming Format

`{type}/{description}-{YYYYMMDD}` (date optional but recommended for clarity)

**Types:**
- `feat/` - New features
- `fix/` - Bug fixes
- `chore/` - Maintenance, dependencies, linter fixes
- `docs/` - Documentation changes
- `refactor/` - Code restructuring
- `hotfix/` - Emergency production fixes

## Linear History Workflow

### Trunk-Based Development

**Preferred: Main-branch development** (see above) - no local feature branches needed.

**Alternative: Local feature branches** for complex multi-day work:

```bash
# Feature branch lifecycle (max 2 days)
git switch main
git pull origin main
git switch -c feat/user-auth

# Daily rebase to stay current
git switch main && git pull
git switch feat/user-auth
git rebase main

# Interactive cleanup before PR
git rebase -i main
# Squash, fixup, reword commits for clean history

# Push and create PR
git push -u origin feat/user-auth
```

Use local branches only when:
- Multi-day complex features requiring isolation
- Experimental work that might be abandoned
- Need to switch contexts frequently between unrelated work

### Squash Merge Strategy

Maintain linear main branch history:

```bash
# Manual squash merge
git switch main
git merge --squash feat/user-auth
git commit -m "feat: add user authentication system

- Implement JWT token validation
- Add login/logout endpoints
- Create user session management

Closes #123"
```

### Interactive Rebase Workflow

Clean up commits before sharing:

```bash
# Rebase last 3 commits
git rebase -i HEAD~3

# Common rebase commands:
# pick   = use commit as-is
# squash = combine with previous commit
# fixup  = squash without editing message
# reword = change commit message
# drop   = remove commit entirely

# Example rebase todo list:
pick a1b2c3d feat: add login form
fixup d4e5f6g fix typo in login form
squash g7h8i9j add form validation
reword j1k2l3m implement JWT tokens
```

## GitHub MCP Integration

Use GitHub MCP tools for all GitHub operations:

```python
# Get repository information
mcp__github__get_me()  # Get authenticated user info

# List and create PRs
mcp__github__list_pull_requests(owner="owner", repo="repo")
mcp__github__create_pull_request(
  owner="owner",
  repo="repo",
  title="feat: add authentication",
  head="feat/auth",
  base="main",
  body="## Summary\n- JWT authentication\n- OAuth support\n\nCloses #123"
)

# Update PRs
mcp__github__update_pull_request(
  owner="owner",
  repo="repo",
  pullNumber=42,
  title="Updated title",
  state="open"
)

# List and create issues
mcp__github__list_issues(owner="owner", repo="repo")
```

## Best Practices

### Daily Integration Workflow

```bash
# Start of day: sync with main
git switch main
git pull origin main
git switch feat/current-work
git rebase main

# End of day: push progress
git add . && git commit -m "wip: daily progress checkpoint"
git push origin feat/current-work

# Before PR: clean up history
git rebase -i main
git push --force-with-lease origin feat/current-work
```

### Conflict Resolution with Rebase

```bash
# When rebase conflicts occur
git rebase main
# Fix conflicts in editor
git add resolved-file.txt
git rebase --continue

# If rebase gets messy, abort and merge instead
git rebase --abort
git merge main
```

### Safe Force Pushing

```bash
# Always use --force-with-lease to prevent overwriting others' work
git push --force-with-lease origin feat/branch-name

# Never force push to main/shared branches
# Use this alias for safety:
git config alias.pushf 'push --force-with-lease'
```

## Main Branch Protection

Configure branch rules for linear history via GitHub MCP:

```bash
# Require linear history (disable merge commits)
# Configure via GitHub settings or MCP tools
# - Require pull request reviews
# - Require status checks to pass
# - Enforce linear history (squash merge only)
```

## Pull Request Workflow

### PR Title Format

Use conventional commit format in PR titles:

- `feat: add user authentication`
- `fix: resolve login validation bug`
- `docs: update API documentation`
- `chore: update dependencies`

### PR Body Template

```markdown
## Summary
Brief description of changes

## Changes
- Bullet points of key changes
- Link related work

## Testing
How changes were tested

Closes #123
```

### PR Creation Best Practices

- **One focus per PR** - Single logical change
- **Small PRs** - Easier to review (< 400 lines preferred)
- **Link issues** - Use "Closes #123" or "Fixes #456"
- **Add labels** - Use GitHub labels for categorization
- **Request reviewers** - Tag specific reviewers when needed

## Troubleshooting

### Branch Diverged from Remote

```bash
# Pull with rebase to maintain linear history
git pull --rebase origin feat/branch-name

# Or reset if local changes can be discarded
git fetch origin
git reset --hard origin/feat/branch-name
```

### Committed to Main (Expected Workflow)

With main-branch development, committing to main is the expected workflow:

```bash
# Commits are already on main - just push to remote feature branch
git push origin main:feat/new-feature

# Create PR using GitHub MCP (head: feat/new-feature, base: main)

# After PR is merged, local main is behind - sync it:
git pull origin main  # Fast-forward merge handles this cleanly
```

**Why this works:**
- Commits exist on both local main and remote feature branch
- When PR merges to remote main, your local main is behind by same commits
- `git pull` recognizes the commits and fast-forwards cleanly
- No history rewriting, no data loss, no merge conflicts

### Rebase Conflicts Are Too Complex

```bash
# Abort rebase and use merge instead
git rebase --abort
git merge main
```
