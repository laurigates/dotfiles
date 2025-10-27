---
name: Git Workflow
description: Preferred git workflow patterns including branching strategy, commit practices, pre-commit validation, and pull request preparation. Use when performing git operations or managing version control workflows.
allowed-tools: Bash, Read, Write, Edit, mcp__github
---

# Git Workflow

Expert knowledge for following preferred git workflow patterns that emphasize clean history, thorough validation, and frequent commits.

## Core Principles

**Workflow Philosophy**
- Commit early and often - track small incremental changes
- Always validate before committing - catch issues early
- Explicit staging - never use `git add .` without review
- Branch-based development - never commit directly to main
- Security first - scan for secrets before every commit

## Standard Workflow Sequence

### 1. Start New Work
```bash
# Always start with fresh main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/descriptive-name
# or
git checkout -b fix/bug-description
```

**Branch Naming Conventions**:
- `feature/` - New functionality
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation updates
- `test/` - Test additions or improvements
- `chore/` - Maintenance tasks

### 2. Make Changes and Validate

**Before Staging Anything**:
```bash
# 1. Review your changes
git status
git diff

# 2. Scan for secrets (CRITICAL)
detect-secrets scan --baseline .secrets.baseline

# 3. Run pre-commit checks
pre-commit run --all-files

# 4. Run tests if applicable
npm test         # Node.js
pytest           # Python
cargo test       # Rust
make test        # Makefile-based projects
```

### 3. Stage Files Explicitly

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

### 4. Commit with Meaningful Messages

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

**Commit Message Format**:
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

## Pre-Commit Validation Workflow

**Complete Pre-Commit Checklist**:
```bash
# 1. Secret scanning (ALWAYS first)
detect-secrets scan --baseline .secrets.baseline

# 2. Pre-commit hooks
pre-commit run --all-files

# 3. Language-specific checks
# Python
ruff check --fix .
ruff format .
pytest

# Rust
cargo fmt
cargo clippy
cargo test

# JavaScript/TypeScript
npm run lint:fix
npm run format
npm test

# 4. Review changes
git diff --cached

# 5. Commit only after all checks pass
git commit -m "type: description"
```

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

## Pull Request Preparation

### Before Creating PR
```bash
# 1. Ensure branch is up-to-date
git checkout main
git pull origin main
git checkout feature/branch-name
git rebase main             # or merge main

# 2. Run full test suite
npm test                    # or pytest, cargo test, etc.

# 3. Check for untracked files
git status

# 4. Review all commits
git log main..HEAD --oneline

# 5. Push to remote
git push origin feature/branch-name
# or first-time push
git push -u origin feature/branch-name
```

### PR Best Practices
```bash
# Create PR with gh CLI
gh pr create \
  --title "feat: add authentication system" \
  --body "$(cat <<'EOF'
## Summary
- Implemented JWT-based authentication
- Added password hashing and validation
- Created auth middleware

## Test Plan
- [x] Unit tests for auth functions
- [x] Integration tests for endpoints
- [x] Manual testing of login flow

## Breaking Changes
None

Fixes #123
EOF
)"
```

## Common Operations

### Reviewing Changes
```bash
# See what changed
git status                  # Overview
git diff                    # Unstaged changes
git diff --cached           # Staged changes
git diff HEAD               # All changes
git diff main..HEAD         # Changes vs main

# Review commit history
git log --oneline -10       # Last 10 commits
git log --graph --oneline   # Visual history
git log -p                  # With diffs
```

### Undoing Changes
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

### Branch Management
```bash
# List branches
git branch                  # Local branches
git branch -r               # Remote branches
git branch -a               # All branches

# Delete branches
git branch -d feature/done  # Safe delete (merged)
git branch -D feature/bad   # Force delete

# Clean up remote branches
git fetch --prune
git remote prune origin
```

## Troubleshooting

### Conflict Resolution
```bash
# During rebase or merge
git status                  # See conflicting files

# Edit files to resolve conflicts
# Look for <<<<<<< ======= >>>>>>>

# After resolving
git add resolved-file.py
git rebase --continue       # or git merge --continue

# Abort if needed
git rebase --abort          # or git merge --abort
```

### Recovery
```bash
# Find lost commits
git reflog                  # View reference log
git cherry-pick <commit>    # Recover specific commit

# Restore deleted branch
git reflog                  # Find branch tip commit
git checkout -b recovered-branch <commit>
```

## Security Checklist

**Before Every Commit**:
- [ ] Run `detect-secrets scan --baseline .secrets.baseline`
- [ ] No API keys, passwords, or tokens in code
- [ ] No `.env` files with real secrets
- [ ] No private keys or certificates
- [ ] Environment variables used for sensitive data
- [ ] `.gitignore` properly configured

**Secret Scanning Commands**:
```bash
# Scan for new secrets
detect-secrets scan --baseline .secrets.baseline

# Review flagged items
detect-secrets audit .secrets.baseline

# Scan git history for secrets
trufflehog git file://. --only-verified

# If secrets found in history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/secret-file' \
  --prune-empty --tag-name-filter cat -- --all
```

## Quick Reference

### Essential Workflow
```bash
# 1. Start
git checkout main && git pull
git checkout -b feature/name

# 2. Work and validate
detect-secrets scan --baseline .secrets.baseline
pre-commit run --all-files

# 3. Stage explicitly
git add specific-file.py

# 4. Commit frequently
git commit -m "type: description"

# 5. Push and PR
git push -u origin feature/name
gh pr create
```

### Pre-Commit Sequence
```bash
detect-secrets scan --baseline .secrets.baseline  # ALWAYS FIRST
pre-commit run --all-files                         # Run hooks
# Run tests                                         # Language-specific
git add files                                      # Stage explicitly
git commit -m "message"                            # Commit
```

This workflow ensures clean git history, thorough validation, and secure code management throughout the development process.
