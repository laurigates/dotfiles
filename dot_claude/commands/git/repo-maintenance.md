---
allowed-tools: Bash(git:*), Read, Write, Edit, Glob, TodoWrite
argument-hint: [--prune] [--gc] [--verify] [--branches] [--stash] [--all]
description: Perform repository maintenance and cleanup
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Local branches: !`git branch -vv`
- Stash list: !`git stash list`
- Repository size: !`du -sh .git 2>/dev/null || echo "N/A"`

## Parameters

Parse these parameters from the command (all optional):

- `--prune`: Remove unreachable objects and optimize repository
- `--gc`: Run git garbage collection (aggressive)
- `--verify`: Verify integrity of git objects
- `--branches`: Clean up merged branches only
- `--stash`: Clean up stashes only
- `--all`: Run all maintenance tasks (default if no flags specified)

## Your task

### 1. Check for accidentally committed files

- Scan for common files that shouldn't be in git:
  - Environment files: `.env`, `.env.local`, `*.env.*`
  - IDE files: `.DS_Store`, `Thumbs.db`, `*.swp`, `*.swo`
  - Dependency directories: `node_modules/`, `__pycache__/`, `.venv/`
  - Build artifacts: `dist/`, `build/`, `*.pyc`, `*.pyo`
  - Secret files: `*.key`, `*.pem`, `*.p12`, `credentials.json`
  - Large binary files (>10MB)

- If found, warn the user and suggest:
  - Add to `.gitignore`
  - Use `git rm --cached <file>` to unstage
  - Consider using `git filter-branch` or `BFG Repo-Cleaner` for history removal

### 2. Update .gitignore

- Read current `.gitignore`
- Suggest common patterns if missing:
  ```
  # OS files
  .DS_Store
  Thumbs.db

  # IDE
  .vscode/
  .idea/
  *.swp
  *.swo

  # Environment
  .env
  .env.local
  .env.*.local

  # Dependencies
  node_modules/
  __pycache__/
  .venv/

  # Build
  dist/
  build/
  *.pyc
  ```

- Offer to append missing patterns

### 3. Delete merged branches

Clean up branches that have been merged:

- List local branches: `git branch --merged`
- Identify branches merged via GitHub PR:
  - Fetch latest: `git fetch --prune origin`
  - Find remote-tracking branches gone from remote: `git branch -vv | grep ': gone]'`
  - Extract branch names and delete: `git branch -d <branch-name>`

- Protected branches (never delete):
  - `main`, `master`, `develop`, `staging`, `production`
  - Current branch

- For each merged branch:
  - Confirm it's fully merged: `git branch --merged | grep <branch>`
  - Delete local: `git branch -d <branch-name>`
  - Delete remote if exists: `git push origin --delete <branch-name>` (ask first)

### 4. Clean up redundant stashes

- List all stashes: `git stash list`
- For each stash, show:
  - Age: `git log -1 --format="%cr" <stash>`
  - Message and branch context

- Suggest cleanup for:
  - Stashes older than 30 days
  - Stashes from deleted branches
  - Duplicate stashes with same message

- Commands:
  - Drop specific stash: `git stash drop stash@{n}`
  - Clear all stashes (with confirmation): `git stash clear`

### 5. Repository optimization (if --prune or --gc or --all)

Execute maintenance commands:

1. **Prune unreachable objects**:
   ```bash
   git prune --dry-run  # Show what would be removed
   git prune            # Actually remove
   ```

2. **Garbage collection**:
   ```bash
   git gc --aggressive --prune=now
   ```

3. **Repack objects**:
   ```bash
   git repack -Ad      # Repack into single pack
   git prune-packed    # Remove redundant packs
   ```

4. **Show size improvement**:
   - Before: stored size
   - After: new size
   - Saved: difference

### 6. Verify repository integrity (if --verify or --all)

Run verification checks:

```bash
git fsck --full --strict
```

Report any:
- Dangling objects (harmless, can be cleaned)
- Missing objects (corruption, needs attention)
- Connectivity issues (serious, backup immediately)

### 7. Final summary

Display:
- ✓ Accidentally committed files checked
- ✓ `.gitignore` updated (if changed)
- ✓ X branches deleted (list them)
- ✓ X stashes cleaned (list them)
- ✓ Repository optimized (size before → after)
- ✓ Integrity verified (status)

## Execution

Execute all git commands directly with the Bash tool. Always show dry-run output before destructive operations and ask for confirmation. Show the user what's being done as you go.
