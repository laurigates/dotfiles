# Git Commit Workflow

## Description

Commit practices including frequency, messages, staging, and history management. Emphasizes commit early and often, explicit staging, meaningful messages, and clean git history.

## When to Use

Automatically apply this skill when:
- Making commits
- Writing commit messages
- Staging files
- Managing work in progress
- Amending commits
- Working with git stashes

## Core Principles

**Commit Philosophy**:
- Commit early and often - track small incremental changes
- Explicit staging - never use `git add .` without review
- Meaningful messages - follow conventional commit format
- Clean history - small focused commits are better than large ones

## Commit Frequency Best Practices

**Commit Often**:
```bash
# After each logical change
git add file.py && git commit -m "feat: add data validation"
git add test.py && git commit -m "test: add validation tests"
git add docs.md && git commit -m "docs: document validation API"

# Small focused commits are better than large ones
# Good:  3 commits for feature (impl, tests, docs)
# Bad:   1 commit with everything
```

**When to Commit**:
- After implementing a single function or method
- After fixing a specific bug
- After adding or updating tests
- After documentation updates
- Before switching context or taking a break
- After any working state you might want to return to

## Staging Files Explicitly

```bash
# Stage specific files (NEVER use git add .)
git add path/to/file1.py
git add path/to/file2.rs
git add path/to/file3.ts

# Or stage files by category
git add src/                # All files in src/
git add tests/test_*.py     # All test files
git add '*.md'              # All Markdown files

# Review staged changes
git diff --cached
```

**Important**: Always review what you're staging:
```bash
# Good practice: stage and verify
git add file.py && git diff --cached file.py
```

## Commit Message Format

```bash
# Commit with descriptive message
git commit -m "feat: add user authentication endpoint

- Implement JWT token generation
- Add password hashing with bcrypt
- Create login and logout routes
- Add auth middleware for protected routes"

# Or use editor for longer messages
git commit
```

**Commit Message Structure**:
```
type: short description (max 50 chars)

- Bullet point of change 1
- Bullet point of change 2
- Bullet point of change 3

[optional] More detailed explanation if needed
[optional] Breaking changes
[optional] Issue references: Fixes #123
```

**Commit Types**:
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `docs:` - Documentation
- `test:` - Adding tests
- `chore:` - Maintenance
- `perf:` - Performance improvement
- `style:` - Code style changes

## Advanced Commit Practices

### Interactive Staging

```bash
# Stage parts of files
git add -p file.py          # Interactive staging
git add -i                  # Interactive mode

# Useful for splitting changes into logical commits
```

### Amending Commits

```bash
# Add to last commit (if not pushed)
git add forgotten-file.py
git commit --amend --no-edit

# Update last commit message
git commit --amend -m "fix: corrected commit message"

# WARNING: Never amend pushed commits
```

### Stashing Changes

```bash
# Save work in progress
git stash push -m "WIP: feature implementation"

# Apply stashed changes
git stash list              # See all stashes
git stash apply             # Apply most recent
git stash apply stash@{1}   # Apply specific stash

# Drop stash after applying
git stash drop
```

## Reviewing Changes

```bash
# See what changed
git status                  # Overview
git diff                    # Unstaged changes
git diff --cached           # Staged changes
git diff HEAD               # All changes

# Review commit history
git log --oneline -10       # Last 10 commits
git log --graph --oneline   # Visual history
git log -p                  # With diffs
```

## Undoing Changes

```bash
# Unstage files
git reset HEAD file.py      # Unstage specific file
git reset HEAD              # Unstage all

# Discard changes
git checkout -- file.py     # Discard file changes
git restore file.py         # Modern syntax

# Undo last commit (keep changes)
git reset --soft HEAD^

# Undo last commit (discard changes)
git reset --hard HEAD^
```

## Commit Workflow Sequence

### Basic Workflow

```bash
# 1. Review changes
git status
git diff

# 2. Stage explicitly
git add specific-file.py

# 3. Review staged changes
git diff --cached

# 4. Commit with message
git commit -m "type: description"
```

### Multi-Change Workflow

```bash
# Working on feature with multiple logical parts

# 1. Implement core functionality
# Edit files...
git add src/core.py
git commit -m "feat: implement core logic"

# 2. Add tests
# Write tests...
git add tests/test_core.py
git commit -m "test: add core logic tests"

# 3. Add documentation
# Write docs...
git add docs/core.md
git commit -m "docs: document core API"

# Result: 3 clear, focused commits
```

## Best Practices

1. **Commit frequently** - Small commits are easier to review and revert
2. **Write clear messages** - Future you will thank present you
3. **Review before staging** - Always know what you're committing
4. **Stage explicitly** - Avoid `git add .` and wildcards without review
5. **Use conventional commits** - Consistent format helps automation
6. **One concern per commit** - Don't mix unrelated changes
7. **Test before committing** - Commits should represent working states

## Common Pitfalls

- ❌ Using `git add .` without reviewing changes
- ❌ Vague commit messages like "fix stuff" or "update"
- ❌ Mixing unrelated changes in one commit
- ❌ Committing broken code
- ❌ Forgetting to commit for hours (losing granular history)
- ❌ Amending commits that have been pushed
- ❌ Not reviewing `git diff --cached` before committing

## Examples

### Example 1: Feature Implementation

```bash
# Feature: Add user authentication

# Step 1: Core implementation
git add src/auth/jwt.py
git commit -m "feat: add JWT token generation

- Implement token creation with expiry
- Add token validation logic
- Use HS256 algorithm"

# Step 2: Add tests
git add tests/test_auth.py
git commit -m "test: add JWT authentication tests

- Test token generation
- Test token validation
- Test expiry handling"

# Step 3: Integration
git add src/api/routes.py
git commit -m "feat: integrate JWT auth in API routes

- Add auth middleware
- Protect sensitive endpoints
- Add login/logout routes"

# Result: 3 clear commits showing progression
```

### Example 2: Bug Fix

```bash
# Bug: Connection pool exhaustion

# Step 1: Fix the bug
git add src/database/pool.py
git commit -m "fix: increase connection pool size

Pool was too small for async workload causing timeouts.
Increased pool_size to 20, overflow to 10.

Fixes #123"

# Step 2: Add regression test
git add tests/test_pool.py
git commit -m "test: add connection pool stress test

Ensures pool handles high concurrent load without exhaustion."

# Result: Fix + test in separate commits
```

### Example 3: Refactoring

```bash
# Refactor: Extract validation logic

# Step 1: Extract function
git add src/validation.py src/api/users.py
git commit -m "refactor: extract user validation to separate module

- Create validation.py with validate_user function
- Update users.py to use new validation module
- No behavior changes"

# Step 2: Add tests for new module
git add tests/test_validation.py
git commit -m "test: add validation module tests

- Test email validation
- Test password strength validation
- Test required fields validation"

# Result: Refactor + tests clearly separated
```

## Integration with Other Skills

- **git-security-checks**: Run security checks before committing
- **git-branch-pr-workflow**: Commits are building blocks for PRs
- **release-please-protection**: Conventional commits enable automated releases

## Quick Reference

```bash
# Essential commit workflow
git status                          # Review changes
git add specific-file.py           # Stage explicitly
git diff --cached                   # Review staged
git commit -m "type: description"  # Commit

# Amend (if not pushed)
git add forgotten-file.py
git commit --amend --no-edit

# Stash work in progress
git stash push -m "WIP: description"
git stash apply

# Review history
git log --oneline -10
git log -p
```

## References

- Related Skills: `git-security-checks`, `git-branch-pr-workflow`
- Conventional Commits: https://www.conventionalcommits.org/
- Replaces: `git-workflow` (commit sections)
