---
name: Git Commit Workflow
description: Commit message conventions, staging practices, and commit best practices. Conventional commits, explicit staging workflow, logical change grouping, and humble fact-based communication style.
allowed-tools: Bash, Read
---

# Git Commit Workflow

Expert guidance for commit message conventions, staging practices, and commit best practices using conventional commits and explicit staging workflows.

## Core Expertise

- **Conventional Commits**: Standardized format for automation and clarity
- **Explicit Staging**: Always stage files individually with clear visibility
- **Logical Grouping**: Group related changes into focused commits
- **Communication Style**: Humble, factual, concise commit messages
- **Pre-commit Integration**: Run checks before committing

## Conventional Commit Format

### Standard Format

```
type(scope): description

[optional body]

[optional footer(s)]
```

### Commit Types

- **feat**: New feature for the user
- **fix**: Bug fix for the user
- **docs**: Documentation changes
- **style**: Formatting, missing semicolons, etc (no code change)
- **refactor**: Code restructuring without changing behavior
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates, linter fixes
- **perf**: Performance improvements
- **ci**: CI/CD changes

### Examples

```bash
# Feature with scope
git commit -m "feat(auth): implement OAuth2 integration"

# Bug fix with body
git commit -m "fix(api): resolve null pointer in user service

Fixed race condition where user object could be null during
concurrent authentication requests."

# Documentation update
git commit -m "docs(readme): update installation instructions"

# Breaking change
git commit -m "feat(api)!: migrate to GraphQL endpoints

BREAKING CHANGE: REST endpoints removed in favor of GraphQL.
See migration guide at docs/migration.md"

# Multiple fixes
git commit -m "fix(auth): resolve login validation issues

- Handle empty email addresses
- Validate password strength requirements
- Add rate limiting to prevent brute force

Fixes #123, #124"
```

### Commit Message Best Practices

**DO:**
- Use imperative mood ("add feature" not "added feature")
- Keep first line under 72 characters
- Be concise and factual
- Reference issues with "Fixes #123" or "Closes #456"
- Use lowercase for type and scope
- Be humble and modest

**DON'T:**
- Use past tense ("added" or "fixed")
- Include unnecessary details in subject line
- Use vague descriptions ("update stuff", "fix bug")
- Forget to reference related issues

### Scope Guidelines

Common scopes by area:

```bash
# Feature areas
feat(auth): login system changes
feat(api): API endpoint changes
feat(ui): user interface changes
feat(db): database schema changes

# Component-specific
fix(header): navigation menu bug
fix(footer): copyright date
fix(sidebar): responsive layout

# Infrastructure
chore(deps): dependency updates
chore(ci): CI/CD configuration
chore(docker): container configuration
```

## Explicit Staging Workflow

### Always Stage Files Individually

```bash
# Show current status
git status --porcelain

# Stage files one by one for visibility
git add src/auth/login.ts
git add src/auth/oauth.ts
git status  # Verify what's staged

# Show what will be committed
git diff --cached --stat
git diff --cached  # Review actual changes

# Commit with conventional message
git commit -m "feat(auth): add OAuth2 support"
```

### Pre-commit Hook Integration

```bash
# Run pre-commit checks before staging
pre-commit run --all-files --show-diff-on-failure

# Stage files after fixes
git add fixed-file.ts
git status

# Show staged changes before commit
git diff --cached --name-only
git commit -m "style(code): apply linter fixes"
```

### Explicit Staging Best Practices

```bash
# ✅ Explicit staging with review
git status
git add src/feature/new-file.ts
git add tests/feature.test.ts
git diff --cached --stat
git commit -m "feat(feature): add new feature with tests"
```

## Logical Change Grouping

### Group Related Changes

```bash
# Example: Authentication feature with multiple files
# Group 1: Core implementation
git add src/auth/oauth.ts
git add src/auth/token.ts
git commit -m "feat(auth): implement OAuth2 token handling"

# Group 2: Tests
git add tests/auth/oauth.test.ts
git add tests/auth/token.test.ts
git commit -m "test(auth): add OAuth2 integration tests"

# Group 3: Documentation
git add docs/api/authentication.md
git add README.md
git commit -m "docs(auth): document OAuth2 flow"
```

### Separate Concerns

```bash
# Example: Mixed changes
# Separate linter fixes from feature work

# Group 1: Linter/formatting (chore commit)
git add src/**/*.ts  # (only formatting changes)
git add .eslintrc
git commit -m "chore(lint): apply ESLint fixes and update config"

# Group 2: Feature implementation (feat commit)
git add src/feature/implementation.ts
git add tests/feature.test.ts
git commit -m "feat(feature): add new user management feature"
```

### Change Classification

**Linter/Formatting Group:**
- Whitespace-only changes
- Lock files (package-lock.json, Cargo.lock)
- Auto-generated linter configs
- Commit type: `chore`

**Feature/Fix Groups:**
- Implementation code
- Related tests
- Relevant documentation
- Commit type: `feat`, `fix`, `refactor`

**Documentation Group:**
- README updates
- API documentation
- User guides
- Commit type: `docs`

## Communication Style

### Humble, Fact-Based Messages

```bash
# ✅ GOOD: Concise, factual, modest
git commit -m "fix(auth): handle edge case in token refresh"

git commit -m "feat(api): add pagination support

Implements cursor-based pagination for list endpoints.
Includes tests and documentation."

# ❌ BAD: Vague, verbose, or overly confident
git commit -m "fix stuff"
git commit -m "AMAZING new feature that revolutionizes everything!!!"
git commit -m "Updated some files to make things work better and faster"
```

### Focus on Facts

- **What changed**: Describe the change objectively
- **Why it changed**: Explain the reason if non-obvious
- **Impact**: Note breaking changes or important effects

```bash
# Example with context
git commit -m "perf(db): optimize user query with index

Added composite index on (user_id, created_at) to improve
query performance for user activity feeds.

Reduces query time from 800ms to 45ms for typical workloads."
```

## Workflow Examples

### Complete Staging and Commit Flow

```bash
# 1. Check current state
git status

# 2. Run pre-commit checks
pre-commit run --all-files

# 3. Stage files explicitly
git add src/feature.ts
git add tests/feature.test.ts

# 4. Review what's staged
git status
git diff --cached --stat

# 5. Commit with conventional message
git commit -m "feat(feature): add new capability

Implements X feature with Y functionality.
Includes unit tests and integration tests.

Closes #123"

# 6. Verify commit
git log -1 --stat
```

### Amending Commits

```bash
# Fix last commit (before pushing)
git add forgotten-file.ts
git commit --amend --no-edit

# Update commit message
git commit --amend -m "feat(auth): improved OAuth2 implementation"
```

### Interactive Staging

```bash
# Stage parts of a file
git add -p file.ts

# Review hunks and choose:
# y - stage this hunk
# n - do not stage
# s - split into smaller hunks
# e - manually edit hunk
```

## Best Practices

### Commit Frequency

- **Commit early and often**: Small, focused commits
- **One logical change per commit**: Easier to review and revert
- **Keep commits atomic**: Each commit should be a complete, working state

### Commit Message Length

```bash
# Subject line: ≤ 72 characters
feat(auth): add OAuth2 support

# Body: ≤ 72 characters per line (wrap)
# Use blank line between subject and body
```

### Issue References

```bash
# Link to issues
git commit -m "fix(api): handle timeout

Fixes #123"

# Multiple issues
git commit -m "feat(ui): redesign dashboard

Implements designs from #456
Closes #457, #458"

# Breaking changes
git commit -m "feat(api)!: change authentication

BREAKING CHANGE: API key format changed.
See migration guide: #789"
```

## Troubleshooting

### Accidentally Staged Wrong Files

```bash
# Unstage specific file
git restore --staged wrong-file.ts

# Unstage all
git restore --staged .
```

### Wrong Commit Message

```bash
# Amend last commit message (before push)
git commit --amend -m "corrected message"

# After push (prefer pre-push correction when possible)
git commit --amend -m "corrected message"
git push --force-with-lease origin branch-name
```

### Forgot to Add File to Last Commit

```bash
# Add file and amend
git add forgotten-file.ts
git commit --amend --no-edit
```

### Need to Split Last Commit

```bash
# Undo last commit but keep changes staged
git reset --soft HEAD~1

# Unstage all
git restore --staged .

# Stage and commit in groups
git add group1-file.ts
git commit -m "first logical group"

git add group2-file.ts
git commit -m "second logical group"
```
