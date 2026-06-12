---
name: repo-activity
description: Scan all git repositories under ~/repos and report recent activity — last commit age, branch, uncommitted changes — in age-bucketed tables. Use when the user asks for a repo activity overview, "what have I been working on", portfolio status, or which repos are active/dormant.
allowed-tools: Bash(fd *), Bash(git -C *), Glob, Read
---

# Repository Activity Overview

Scan all repositories in ~/repos/ and report recent activity.

## Workflow

### 1. Find All Git Repositories

```bash
fd -t d -H '^\.git$' ~/repos --max-depth 3 -x dirname {} | sort -u
```

### 2. Get Activity for Each Repo

For each repository, gather:

```bash
# Last commit date and message
git -C {repo} log -1 --format='%ar|%s' 2>/dev/null

# Uncommitted changes count
git -C {repo} status --porcelain | wc -l

# Current branch
git -C {repo} branch --show-current
```

Guard every substitution (`|| echo "?"`) — freshly-cloned repos with an
unborn HEAD exit 128 on `log`/`rev-parse` and must not abort the sweep.

### 3. Generate Activity Report

Create a sorted table showing:

| Repository | Last Commit | Age | Branch | Uncommitted |
|------------|-------------|-----|--------|-------------|
| repo-name  | commit msg  | 2d  | main   | 3 files     |

Sort by most recent activity first.

### 4. Highlight Active Projects

Flag repositories with:
- Commits in the last 7 days
- Uncommitted changes
- Non-main/master branches (active development)

## Output Format

```
## Active Repositories (last 7 days)

| Repository | Last Activity | Branch | Status |
|------------|---------------|--------|--------|

## Recently Active (7-30 days)

| Repository | Last Activity | Branch | Status |
|------------|---------------|--------|--------|

## Dormant (>30 days)

| Repository | Last Activity |
|------------|---------------|

## Summary
- X repositories scanned
- Y active in last 7 days
- Z with uncommitted changes
```

## Options

When invoking this skill, the user may specify:
- `--days N` - Change the "active" threshold (default: 7)
- `--uncommitted` - Only show repos with uncommitted changes

## Related

For cross-referencing active repos against Podio Kanban tickets (FVH org
work), chain into the `podio-ticket-updates` skill — it owns the ticket
matching workflow.
