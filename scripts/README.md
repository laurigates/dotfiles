# Secret Detection Scripts

Non-interactive scripts for managing detect-secrets baseline auditing in Claude Code environments.

## Problem

The `detect-secrets audit` command is interactive and incompatible with automated workflows and AI assistants like Claude Code. These scripts provide programmatic alternatives using the detect-secrets Python API.

## Scripts

### audit-secrets-baseline.py

**Purpose**: Mark all unverified secrets in the baseline as audited (verified).

**Usage**:
```bash
# Run with uv (recommended - handles dependencies automatically)
uv run --with detect-secrets python3 scripts/audit-secrets-baseline.py

# Or install detect-secrets and run directly
pip install detect-secrets
python3 scripts/audit-secrets-baseline.py
```

**Output**:
```
📖 Loading baseline from .secrets.baseline...
💾 Saving updated baseline to .secrets.baseline...

✅ Audit complete!
   Newly verified: 73
   Already verified: 0
   Total secrets: 73

📊 Classification:
   True secrets: 0
   False positives: 73
```

**When to use**: After reviewing the baseline file manually and confirming all detections are false positives.

**Warning**: This marks ALL secrets as verified without discrimination. Use cautiously.

### audit-secrets-selective.py

**Purpose**: Selectively audit secrets based on file patterns, allowing category-based verification.

**Usage**:
```bash
# Mark all secrets in test files as false positives
uv run --with detect-secrets python3 scripts/audit-secrets-selective.py \
  --pattern "test_.*\\.py" \
  --false-positive

# Mark secrets in .env.example files as false positives
uv run --with detect-secrets python3 scripts/audit-secrets-selective.py \
  --pattern "\\.env\\.example" \
  --false-positive

# Interactive review of secrets in config files
uv run --with detect-secrets python3 scripts/audit-secrets-selective.py \
  --pattern "config/.*" \
  --interactive

# Mark secrets in credential files as true secrets
uv run --with detect-secrets python3 scripts/audit-secrets-selective.py \
  --pattern "\\.env$" \
  --true-secret
```

**Arguments**:
- `--pattern REGEX`: Regex pattern to match filenames (required)
- `--false-positive`: Mark matched secrets as false positives
- `--true-secret`: Mark matched secrets as true secrets
- `--interactive`: Prompt for each secret (requires user input)
- `--baseline PATH`: Path to baseline file (default: `.secrets.baseline`)

**Output**:
```
📖 Loading baseline from .secrets.baseline...

💾 Saving updated baseline to .secrets.baseline...

✅ Audit complete!
   Pattern: test_.*\.py
   Matched files: 5
   Verified: 12
   Skipped: 61
   Classification: false positives

📋 Matched files:
   - test_auth.py
   - test_api.py
   - test_database.py
```

**When to use**: When you want to audit categories of files systematically without reviewing each secret individually.

## Workflow

### Initial Setup

1. **Generate baseline**:
   ```bash
   detect-secrets scan --baseline .secrets.baseline
   ```

2. **Review the baseline file** to understand what was detected:
   ```bash
   jq -r '.results | to_entries[] | "\(.key):\n  \(.value | length) secrets"' .secrets.baseline
   ```

3. **Update exclusion filters** in `.secrets.baseline` for known false positive patterns:
   ```json
   {
     "path": "detect_secrets.filters.regex.should_exclude_file",
     "pattern": [
       "lazy-lock\\.json|\\.claude/skills/.*/SKILL\\.md"
     ]
   }
   ```

4. **Rescan with updated filters**:
   ```bash
   uv run --with detect-secrets detect-secrets scan --baseline .secrets.baseline
   ```

### Ongoing Auditing

**Option A: Pattern-based auditing (recommended)**

Audit by file categories:
```bash
# Documentation and example files
uv run --with detect-secrets python3 scripts/audit-secrets-selective.py \
  --pattern ".*\\.md|.*\\.example" \
  --false-positive

# Test files with example credentials
uv run --with detect-secrets python3 scripts/audit-secrets-selective.py \
  --pattern "test_.*|.*_test\\.py" \
  --false-positive
```

**Option B: Manual verification with exclusions**

Prefer adding exclusion patterns to `.secrets.baseline` for repeatable categories:
```bash
# Edit .secrets.baseline to add patterns
# Then rescan
uv run --with detect-secrets detect-secrets scan --baseline .secrets.baseline
```

**Option C: Bulk auditing (use with caution)**

Only after careful review:
```bash
uv run --with detect-secrets python3 scripts/audit-secrets-baseline.py
```

### Pre-commit Hook

The `.pre-commit-config.yaml` includes detect-secrets:

```yaml
- repo: https://github.com/Yelp/detect-secrets
  rev: v1.5.0
  hooks:
    - id: detect-secrets
      args: ['--baseline', '.secrets.baseline']
      exclude: (package\.lock\.json|lazy-lock\.json)
```

**Pre-commit workflow**:
1. Make changes
2. Run `pre-commit run --all-files` (or let it run on commit)
3. If new secrets detected, review them
4. Either exclude the file pattern or audit individually
5. Commit the updated `.secrets.baseline`

## Best Practices

### 1. Prefer Exclusion Over Auditing

Add patterns to `.secrets.baseline` for systematic exclusions:
- Lock files: `lazy-lock\.json`, `package-lock\.json`
- Documentation: `.*\.md`, `.*REFERENCE\.md`
- Example configs: `.*\.example`, `.*\.sample`

### 2. Audit by Category

Use `audit-secrets-selective.py` to verify categories:
- Test files together
- Documentation files together
- Configuration examples together

### 3. Never Blindly Approve All

Review at least the file list before running bulk audit:
```bash
# See what would be audited
jq -r '.results | keys[]' .secrets.baseline
```

### 4. Track True Secrets

For actual secrets in example/template files, mark them explicitly:
```bash
uv run --with detect-secrets python3 scripts/audit-secrets-selective.py \
  --pattern "\\.env\\.template" \
  --true-secret
```

This documents that yes, these are secrets, but they're in safe files.

### 5. Regular Rescans

After adding exclusion patterns, always rescan:
```bash
uv run --with detect-secrets detect-secrets scan --baseline .secrets.baseline
```

## Troubleshooting

### "No module named 'detect_secrets'"

Use `uv run --with detect-secrets` prefix:
```bash
uv run --with detect-secrets python3 scripts/audit-secrets-baseline.py
```

### Pre-commit hook fails with new secrets

1. Check what was detected:
   ```bash
   uv run --with detect-secrets detect-secrets scan --baseline .secrets.baseline
   git diff .secrets.baseline
   ```

2. Review the new detections:
   ```bash
   jq '.results' .secrets.baseline
   ```

3. Either audit or exclude:
   ```bash
   # Option 1: Audit the new detections
   uv run --with detect-secrets python3 scripts/audit-secrets-selective.py \
     --pattern "path/to/new/file" \
     --false-positive

   # Option 2: Add exclusion pattern and rescan
   # Edit .secrets.baseline, then:
   uv run --with detect-secrets detect-secrets scan --baseline .secrets.baseline
   ```

### Baseline has many false positives

Review and add exclusion patterns:
```bash
# See all detected files
jq -r '.results | keys[]' .secrets.baseline

# Add patterns to filters_used in .secrets.baseline
# Then rescan
uv run --with detect-secrets detect-secrets scan --baseline .secrets.baseline
```

## Current Exclusions

This repository excludes:
- `private_dot_config/private_atuin/.*` - Private Atuin config
- `macos-settings.toml` - macOS settings
- `\.claude/commands/.*` - Claude Code commands
- `\.claude/skills/.*/SKILL\.md` - Claude Code skill documentation
- `\.claude/skills/.*/REFERENCE\.md` - Claude Code skill references
- `\.claude/docs/.*` - Claude Code documentation
- `lazy-lock\.json` - Neovim plugin lock file (git commit hashes)

See `.secrets.baseline` line 115-117 for the current exclusion pattern.
