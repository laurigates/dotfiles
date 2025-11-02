# Git Security Checks

## Description

Security validation and pre-commit checks for safe commits. Ensures no secrets, API keys, or sensitive data are committed through detect-secrets scanning and pre-commit hooks.

## When to Use

Automatically apply this skill when:
- Before every commit
- Setting up new projects
- During security audits
- Configuring pre-commit hooks
- Reviewing repository security

## Core Principles

**Security First**:
- Scan for secrets before EVERY commit
- Run pre-commit hooks automatically
- Never commit sensitive data
- Use environment variables for secrets
- Properly configure `.gitignore`

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

## Secret Scanning with detect-secrets

### Basic Usage

```bash
# Scan for new secrets (run before EVERY commit)
detect-secrets scan --baseline .secrets.baseline

# Review flagged items
detect-secrets audit .secrets.baseline

# Update baseline after review
detect-secrets scan --baseline .secrets.baseline --update
```

### What detect-secrets Finds

Scans for:
- API keys and tokens
- Private keys and certificates
- Passwords and credentials
- AWS/GCP/Azure secrets
- Database connection strings
- JWT tokens
- OAuth tokens

### Handling Detected Secrets

**If secrets are found**:
```bash
# 1. Review the finding
detect-secrets audit .secrets.baseline

# 2. If true positive (real secret):
#    - Remove from code
#    - Add to environment variables
#    - Update code to use env vars
#    - Never commit the secret

# 3. If false positive (not a secret):
#    - Mark as allowed in audit
#    - Update baseline
```

### Setting Up detect-secrets

```bash
# Initialize baseline
detect-secrets scan --baseline .secrets.baseline

# Add to pre-commit hooks
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

## Pre-Commit Hooks

### Running Pre-Commit Checks

```bash
# Run all hooks
pre-commit run --all-files

# Run specific hook
pre-commit run detect-secrets
pre-commit run trailing-whitespace

# Run on staged files only
pre-commit run
```

### Common Pre-Commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

### Installing Pre-Commit

```bash
# Install pre-commit
pip install pre-commit
# or
brew install pre-commit

# Install hooks in repository
pre-commit install

# Now hooks run automatically on git commit
```

## Security Checklist

**Before Every Commit**:
- [ ] Run `detect-secrets scan --baseline .secrets.baseline`
- [ ] No API keys, passwords, or tokens in code
- [ ] No `.env` files with real secrets
- [ ] No private keys or certificates
- [ ] Environment variables used for sensitive data
- [ ] `.gitignore` properly configured
- [ ] Pre-commit hooks passed

## Language-Specific Security Checks

### Python

```bash
# Security linting
bandit -r src/                    # Security issues
safety check                      # Vulnerable dependencies

# Code quality
ruff check --fix .
ruff format .

# Type checking
mypy src/
```

### JavaScript/TypeScript

```bash
# Security audit
npm audit                         # Vulnerable dependencies
npm audit fix                     # Auto-fix vulnerabilities

# Linting
npm run lint:fix
eslint --fix .

# Type checking
tsc --noEmit
```

### Rust

```bash
# Security audit
cargo audit                       # Vulnerable dependencies

# Linting and formatting
cargo fmt
cargo clippy -- -D warnings
```

## Handling Committed Secrets

**If you accidentally commit a secret**:

### Remove from Latest Commit (Not Pushed)

```bash
# Remove file from commit
git reset HEAD^ path/to/secret-file
git commit --amend --no-edit

# Or completely redo commit
git reset --soft HEAD^
# Remove secret, stage clean files
git commit -m "original message"
```

### Remove from Git History (Already Pushed)

```bash
# WARNING: This rewrites history
# Coordinate with team before running

# Using git-filter-repo (recommended)
git filter-repo --path path/to/secret-file --invert-paths

# Or using BFG Repo-Cleaner
bfg --delete-files secret-file.env

# Force push (dangerous, coordinate with team)
git push --force-with-lease
```

### Rotate Compromised Secrets

**If secret was pushed**:
1. **Immediately rotate** the compromised secret
2. Remove from git history
3. Update all environments with new secret
4. Verify old secret is revoked
5. Document incident

## Scan Git History for Secrets

```bash
# Scan entire git history
trufflehog git file://. --only-verified

# Scan specific branch
trufflehog git file://. --branch main

# Scan since specific commit
trufflehog git file://. --since-commit <commit-sha>
```

## Environment Variables for Secrets

### Using .env Files Safely

```bash
# .gitignore (ALWAYS ignore .env files)
.env
.env.local
.env.*.local
*.key
*.pem
credentials.json

# .env.example (commit this - no real secrets)
API_KEY=your_api_key_here
DATABASE_URL=postgresql://user:password@localhost/db
```

### Loading Environment Variables

**Python**:
```python
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv('API_KEY')
```

**JavaScript**:
```javascript
require('dotenv').config();
const apiKey = process.env.API_KEY;
```

**Rust**:
```rust
use std::env;
use dotenv::dotenv;

dotenv().ok();
let api_key = env::var("API_KEY").expect("API_KEY not set");
```

## .gitignore Configuration

**Essential entries**:
```gitignore
# Secrets and credentials
.env
.env.*
!.env.example
*.key
*.pem
*.p12
credentials.json
secrets.yaml

# API tokens
.api_tokens
.tokens

# Cloud provider credentials
.aws/credentials
.gcp/credentials.json
.azure/credentials

# SSH keys
id_rsa
id_ed25519
*.ppk
```

## Best Practices

1. **Always scan before commit** - Make it muscle memory
2. **Use pre-commit hooks** - Automate security checks
3. **Rotate immediately if leaked** - Assume compromised
4. **Use environment variables** - Never hardcode secrets
5. **Review .gitignore** - Ensure all secret patterns covered
6. **Educate team** - Everyone must follow security practices
7. **Audit regularly** - Run trufflehog on entire history periodically

## Common Pitfalls

- ❌ Skipping secret scan "just this once"
- ❌ Committing `.env` files with real secrets
- ❌ Hardcoding API keys "temporarily"
- ❌ Not rotating leaked secrets immediately
- ❌ Ignoring pre-commit hook failures
- ❌ Committing cloud provider credentials
- ❌ Using weak `.gitignore` patterns

## Examples

### Example 1: Proper Pre-Commit Workflow

```bash
# Make changes
# Edit files...

# 1. Scan for secrets (FIRST)
detect-secrets scan --baseline .secrets.baseline
# ✅ No new secrets found

# 2. Run pre-commit hooks
pre-commit run --all-files
# ✅ All hooks passed

# 3. Run tests
pytest
# ✅ All tests passed

# 4. Review and stage
git add src/api.py tests/test_api.py
git diff --cached

# 5. Commit
git commit -m "feat: add API endpoint"
```

### Example 2: Handling Found Secret

```bash
# Attempt to commit
git add src/config.py

# Scan for secrets
detect-secrets scan --baseline .secrets.baseline
# ❌ Found: API_KEY = "sk_live_abc123..."

# Fix: Remove hardcoded secret
# Edit src/config.py:
# - API_KEY = "sk_live_abc123..."
# + API_KEY = os.getenv("API_KEY")

# Add to .env (NOT committed)
echo 'API_KEY=sk_live_abc123...' >> .env

# Ensure .env is ignored
echo '.env' >> .gitignore

# Re-scan
detect-secrets scan --baseline .secrets.baseline
# ✅ No secrets found

# Commit clean code
git add src/config.py .gitignore
git commit -m "refactor: use environment variables for API key"
```

### Example 3: Setting Up New Project

```bash
# 1. Initialize detect-secrets
detect-secrets scan --baseline .secrets.baseline

# 2. Create .gitignore
cat > .gitignore <<EOF
.env
.env.*
!.env.example
*.key
*.pem
credentials.json
EOF

# 3. Create .env.example
cat > .env.example <<EOF
API_KEY=your_api_key_here
DATABASE_URL=postgresql://user:password@localhost/db
EOF

# 4. Install pre-commit
pre-commit install

# 5. Commit setup
git add .secrets.baseline .gitignore .env.example .pre-commit-config.yaml
git commit -m "chore: set up security scanning and pre-commit hooks"
```

## Integration with Other Skills

- **git-commit-workflow**: Run security checks as part of commit workflow
- **git-branch-pr-workflow**: Ensure security checks pass before PR creation
- **release-please-protection**: Security scanning prevents secret leaks in releases

## Quick Reference

```bash
# Essential security workflow
detect-secrets scan --baseline .secrets.baseline  # ALWAYS FIRST
pre-commit run --all-files                         # Run hooks
# Run tests                                         # Language-specific
git add files                                      # Stage explicitly
git commit -m "message"                            # Commit

# Setup commands
pre-commit install                                 # Install hooks
detect-secrets scan --baseline .secrets.baseline   # Initialize

# Audit commands
detect-secrets audit .secrets.baseline             # Review findings
trufflehog git file://. --only-verified           # Scan history
```

## References

- Related Skills: `git-commit-workflow`, `git-branch-pr-workflow`
- detect-secrets: https://github.com/Yelp/detect-secrets
- pre-commit: https://pre-commit.com/
- trufflehog: https://github.com/trufflesecurity/trufflehog
- Replaces: `git-workflow` (security sections)
