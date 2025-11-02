# Git Branch and PR Workflow

## Description

Branch management, pull request creation, and collaboration workflows. Covers branch naming conventions, PR preparation, conflict resolution, and branch cleanup.

## When to Use

Automatically apply this skill when:
- Creating feature branches
- Preparing pull requests
- Managing branches
- Resolving conflicts
- Reviewing PR readiness
- Cleaning up merged branches

## Core Principles

**Branch-Based Development**:
- Never commit directly to main
- Create feature branches for all work
- Use descriptive branch names
- Keep branches up-to-date with main
- Clean up after merging

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

**Examples**:
```bash
git checkout -b feature/user-authentication
git checkout -b fix/connection-pool-timeout
git checkout -b refactor/extract-validation
git checkout -b docs/api-documentation
git checkout -b test/add-integration-tests
git checkout -b chore/update-dependencies
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

**PR Template Structure**:
```markdown
## Summary
- Bullet points of what changed
- What problem this solves
- How it solves it

## Test Plan
- [x] Unit tests added/updated
- [x] Integration tests pass
- [x] Manual testing completed

## Breaking Changes
List any breaking changes or "None"

## Related Issues
Fixes #123
Relates to #456
```

## Branch Management

### List Branches

```bash
# Local branches
git branch

# Remote branches
git branch -r

# All branches
git branch -a

# Branches with last commit
git branch -v
```

### Delete Branches

```bash
# Delete merged branch (safe)
git branch -d feature/done

# Force delete unmerged branch
git branch -D feature/bad

# Delete remote branch
git push origin --delete feature/done
```

### Clean Up Branches

```bash
# Remove local references to deleted remote branches
git fetch --prune
git remote prune origin

# List merged branches (candidates for deletion)
git branch --merged main

# Delete all merged branches except main
git branch --merged main | grep -v "main" | xargs git branch -d
```

## Conflict Resolution

### During Rebase or Merge

```bash
# See conflicting files
git status

# Edit files to resolve conflicts
# Look for <<<<<<< ======= >>>>>>>

# After resolving
git add resolved-file.py
git rebase --continue       # or git merge --continue

# Abort if needed
git rebase --abort          # or git merge --abort
```

### Conflict Markers

```python
<<<<<<< HEAD
# Your current branch changes
def authenticate(user):
    return validate_jwt(user.token)
=======
# Incoming changes from main
def authenticate(user):
    return validate_oauth(user.credentials)
>>>>>>> main
```

**Resolve by choosing or combining**:
```python
# Resolved: Keep both approaches
def authenticate(user):
    if user.token:
        return validate_jwt(user.token)
    return validate_oauth(user.credentials)
```

## Keeping Branch Up-to-Date

### Rebase Strategy (Preferred)

```bash
# Update main
git checkout main
git pull origin main

# Rebase your branch
git checkout feature/branch-name
git rebase main

# Resolve conflicts if any
# Then force push (if already pushed)
git push --force-with-lease
```

**Advantages**:
- Clean linear history
- No merge commits
- Easier to review

### Merge Strategy

```bash
# Update main
git checkout main
git pull origin main

# Merge into your branch
git checkout feature/branch-name
git merge main

# Resolve conflicts if any
# Then push
git push
```

**Advantages**:
- Preserves exact history
- No force push needed
- Safer for collaboration

## Recovery and Troubleshooting

### Find Lost Commits

```bash
# View reference log
git reflog

# Recover specific commit
git cherry-pick <commit>

# Restore deleted branch
git reflog                  # Find branch tip commit
git checkout -b recovered-branch <commit>
```

### Undo Changes

```bash
# Undo last commit (keep changes)
git reset --soft HEAD^

# Undo last commit (discard changes)
git reset --hard HEAD^

# Undo local changes to file
git checkout -- file.py
git restore file.py         # Modern syntax
```

## Working with Remote

### Push Strategies

```bash
# First push (set upstream)
git push -u origin feature/branch-name

# Regular push
git push

# Force push (after rebase, use with caution)
git push --force-with-lease  # Safer than --force
```

### Pull Strategies

```bash
# Pull with rebase
git pull --rebase

# Pull with merge
git pull

# Fetch without merging
git fetch origin
git diff main origin/main
```

## Best Practices

1. **Always branch from updated main** - Avoid stale starting points
2. **Use descriptive branch names** - Clear purpose from name
3. **Keep branches focused** - One feature/fix per branch
4. **Update regularly** - Rebase or merge main frequently
5. **Test before PR** - All tests must pass
6. **Review your own diff** - Catch issues before others see
7. **Clean up after merge** - Delete merged branches promptly
8. **Use force-with-lease** - Safer than force push

## Common Pitfalls

- ❌ Committing directly to main
- ❌ Vague branch names like "updates" or "fixes"
- ❌ Long-lived branches that drift from main
- ❌ Not testing before creating PR
- ❌ Using `--force` instead of `--force-with-lease`
- ❌ Forgetting to delete merged branches
- ❌ Not keeping branch up-to-date with main

## Examples

### Example 1: Feature Branch Workflow

```bash
# Start feature
git checkout main
git pull origin main
git checkout -b feature/add-payment-processing

# Work and commit
# ... multiple commits ...

# Before PR: update with main
git checkout main
git pull origin main
git checkout feature/add-payment-processing
git rebase main

# Run tests
npm test

# Push and create PR
git push -u origin feature/add-payment-processing
gh pr create \
  --title "feat: add payment processing" \
  --body "Implements Stripe payment integration"

# After merge: cleanup
git checkout main
git pull origin main
git branch -d feature/add-payment-processing
```

### Example 2: Bug Fix Workflow

```bash
# Create fix branch
git checkout main
git pull origin main
git checkout -b fix/resolve-memory-leak

# Fix and test
# Edit files...
git add src/cache.py
git commit -m "fix: prevent memory leak in cache

Clear cache entries when limit reached to prevent unbounded growth.

Fixes #456"

# Push and PR
git push -u origin fix/resolve-memory-leak
gh pr create \
  --title "fix: resolve memory leak in cache" \
  --body "Fixes #456"

# After merge
git checkout main
git pull origin main
git branch -d fix/resolve-memory-leak
```

### Example 3: Handling Conflicts

```bash
# Update branch with main
git checkout main
git pull origin main
git checkout feature/new-api
git rebase main

# Conflict occurs
# CONFLICT (content): Merge conflict in src/api.py

# View conflict
git status
# both modified: src/api.py

# Resolve in editor
# Edit src/api.py, remove markers, keep desired changes

# Mark resolved
git add src/api.py
git rebase --continue

# Force push (after rebase)
git push --force-with-lease
```

## Integration with Other Skills

- **git-commit-workflow**: Branches are built from commits
- **git-security-checks**: Run security checks before PR
- **release-please-protection**: PRs trigger automated releases

## Quick Reference

```bash
# Start work
git checkout main && git pull
git checkout -b feature/name

# Before PR
git checkout main && git pull
git checkout feature/name && git rebase main
npm test                              # Run tests
git push -u origin feature/name
gh pr create

# Cleanup after merge
git checkout main && git pull
git branch -d feature/name
git fetch --prune
```

## References

- Related Skills: `git-commit-workflow`, `git-security-checks`
- GitHub CLI: https://cli.github.com/
- Git Branching: https://git-scm.com/book/en/v2/Git-Branching
- Replaces: `git-workflow` (branch and PR sections)
