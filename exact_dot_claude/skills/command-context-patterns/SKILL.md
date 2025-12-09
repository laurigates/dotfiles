---
name: command-context-patterns
description: |
  Write safe context expressions in Claude Code slash command files. Covers
  backtick expressions, find vs ls patterns, and commands that always exit 0.
  Use when creating slash commands, writing context sections with backtick
  expressions, or debugging command execution failures.
---

# Command Context Patterns

Best practices for writing context expressions in Claude Code slash command files.

## Activation

Use this skill when:
- Creating or editing slash command files (`.claude/commands/**/*.md`)
- Writing context sections with backtick expressions (`!`...``)
- Debugging command execution failures related to bash expressions

## Safe Patterns

Context expressions must use commands that **always exit 0** regardless of results.

### File Existence Checks

**Use `find` instead of `ls` or `test`:**

```markdown
## Good - always succeeds
- Config file: !`find . -maxdepth 1 -name "config.yaml" -type f`

## Bad - fails if file doesn't exist
- Config file: !`ls config.yaml`
- Config file: !`test -f config.yaml && echo "found" || echo "not"`
```

### Multiple File Checks

**Use `find` with `-o` (or) operators:**

```markdown
## Good - returns found files, empty if none
- Package files: !`find . -maxdepth 1 \( -name "package.json" -o -name "pyproject.toml" -o -name "Cargo.toml" \) -type f`

## Bad - fails if any file missing
- Package files: !`ls package.json pyproject.toml Cargo.toml`
```

### Directory Contents

**Use `find` with directory path:**

```markdown
## Good - returns files or empty
- Workflows: !`find .github/workflows -maxdepth 1 -type f -name "*.yml"`

## Bad - fails if directory doesn't exist
- Workflows: !`ls .github/workflows/`
```

### Git Commands

**Most git commands are safe:**

```markdown
## Good - git commands typically succeed
- Branch: !`git branch --show-current`
- Status: !`git status --short`
- Log: !`git log --oneline -5`
- Diff: !`git diff --stat`
```

### GitHub CLI

**`gh` commands are generally safe:**

```markdown
## Good - returns JSON or empty
- Repo: !`gh repo view --json nameWithOwner`
- Issues: !`gh issue list --state open --json number,title`
```

## Patterns to Avoid

### Chained Operations

**Never use `&&`, `||`, or `;`:**

```markdown
## Bad - multiple operations
- Status: !`test -f file && echo "yes" || echo "no"`
- Build: !`npm install && npm build`
```

### Conditionals

**Never use `if/then/else`:**

```markdown
## Bad - shell conditional
- Config: !`if [ -f .env ]; then echo "present"; else echo "missing"; fi`
```

### Redirections

**Avoid stderr redirections:**

```markdown
## Bad - redirection may be blocked
- Files: !`ls *.txt 2>/dev/null`
- Search: !`grep pattern file 2>&1`
```

### Commands That Fail on Missing Items

**Avoid commands that exit non-zero:**

```markdown
## Bad - exit non-zero if not found
- Tool: !`which ruff`
- File: !`cat config.yaml`
- Dir: !`ls /path/to/maybe/missing`
```

## Quick Reference

| Need | Bad Pattern | Good Pattern |
|------|-------------|--------------|
| File exists | `ls file` | `find . -maxdepth 1 -name "file"` |
| Multiple files | `ls a b c` | `find . -maxdepth 1 \( -name "a" -o -name "b" \) -type f` |
| Dir contents | `ls dir/` | `find dir -maxdepth 1 -type f` |
| Conditional | `test -f x && echo y` | `find . -maxdepth 1 -name "x"` |
| Tool check | `which tool` | Remove or use separate detection logic |

## Validation

When reviewing command files, check each `!`...`` expression for:

1. **Single operation** - no `&&`, `||`, `;`
2. **No conditionals** - no `if/then/else`
3. **No redirections** - no `2>/dev/null`, `2>&1`
4. **Always succeeds** - `find` instead of `ls`/`test`/`which`

## Examples

### Complete Context Section

```markdown
## Context

- Package files: !`find . -maxdepth 1 \( -name "package.json" -o -name "pyproject.toml" \) -type f`
- Lock files: !`find . -maxdepth 1 \( -name "package-lock.json" -o -name "uv.lock" \) -type f`
- Pre-commit: !`find . -maxdepth 1 -name ".pre-commit-config.yaml" -type f`
- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Recent commits: !`git log --oneline -5`
```

This pattern ensures all context expressions succeed regardless of project state.
