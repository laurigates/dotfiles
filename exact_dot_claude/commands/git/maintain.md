---
allowed-tools: Task, TodoWrite
argument-hint: [--prune] [--gc] [--verify] [--branches] [--stash] [--all]
description: Perform repository maintenance and cleanup
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Local branches: !`git branch -vv`
- Stash list: !`git stash list`
- Repository size: !`du -sh .git`

## Parameters

Parse these parameters from the command (all optional):

- `--prune`: Remove unreachable objects and optimize repository
- `--gc`: Run git garbage collection (aggressive)
- `--verify`: Verify integrity of git objects
- `--branches`: Clean up merged branches only
- `--stash`: Clean up stashes only
- `--all`: Run all maintenance tasks (default if no flags specified)

## Your task

**Delegate this task to the `git-operations` agent.**

Use the Task tool with `subagent_type: git-operations` to perform repository maintenance and cleanup. Pass all the context gathered above and the parsed parameters to the agent.

The git-operations agent should:

1. **Check for accidentally committed files**:
   - Environment files, IDE files, dependencies, build artifacts, secrets
   - Suggest adding to `.gitignore` and removing with `git rm --cached`

2. **Update .gitignore**:
   - Suggest common patterns if missing
   - Offer to append missing patterns

3. **Delete merged branches** (if --branches or --all):
   - List and clean branches merged via GitHub PR
   - Protect main, master, develop, staging, production
   - Delete local branches safely with `git branch -d`

4. **Clean up redundant stashes** (if --stash or --all):
   - Show stash ages and context
   - Suggest cleanup for old stashes (>30 days)
   - Drop stashes from deleted branches

5. **Repository optimization** (if --prune, --gc, or --all):
   - Prune unreachable objects
   - Run garbage collection
   - Repack objects
   - Show size improvement

6. **Verify repository integrity** (if --verify or --all):
   - Run `git fsck --full --strict`
   - Report any issues

7. **Final summary**:
   - Report all actions taken
   - Show before/after metrics

Provide the agent with:
- All context from the section above
- The parsed parameters
- Whether to run in dry-run mode first for destructive operations

The agent has expertise in:
- Git repository maintenance
- Branch cleanup strategies
- Stash management
- Repository optimization
- Integrity verification
