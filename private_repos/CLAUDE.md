# repos/ - Project Portfolio Overview

This directory contains project repositories organized by owner/origin. Running Claude Code from here provides visibility across all projects for portfolio-level operations.

## Directory Structure

| Directory | Contents |
|-----------|----------|
| `ForumViriumHelsinki/` | Forum Virium Helsinki organization repos ([GitHub](https://github.com/ForumViriumHelsinki)) |
| `laurigates/` | Personal repos ([GitHub](https://github.com/laurigates)) |
| `external/` | Third-party clones and forks (bevy, esp-idf, llama.cpp, moodle, etc.) |
| `archive/` | Inactive/deprecated projects |

## Work in a Worktree

Make changes to **this** repo (its `.claude/` rules, scripts and skills) in a
Claude Code worktree, not in the main checkout — enter one before the first edit
of a change task. Reading and answering questions do not need one.

`EnterWorktree` acts on the session's current repo. From a nested checkout
(cwd under `~/repos/<org>/<repo>`) it silently creates a worktree of that
nested repo instead. There, run
`git -C /Users/lgates/repos fetch origin && git -C /Users/lgates/repos worktree add -b <branch> /Users/lgates/repos/.claude/worktrees/<name> origin/main`
and work on it by absolute path. The session can stay where it is; only the
main checkout has to stay clean.

This `CLAUDE.md` is not tracked here: chezmoi renders it from
`private_repos/CLAUDE.md` in the dotfiles source (`~/.local/share/chezmoi`), so
edit it there and run `chezmoi apply ~/repos/CLAUDE.md`.

The reason is mechanical, not stylistic: `.claude/scripts/repos-sync-nudge.sh`
auto-fast-forwards this checkout only when `git status --porcelain` is empty, so
uncommitted work sitting in the main checkout silently switches that freshness
auto-pull off — in the one repo whose whole job is to hand fresh rules to
everything underneath it. `worktree.baseRef` is `fresh`, so the branch starts
from `origin/main` rather than from wherever this checkout is sitting.

This does **not** extend to the nested project repos underneath: those are
separate checkouts with their own conventions, and `~/repos` deliberately
ignores them.

That ignore also hides them from search: `fd` and `rg` run from `~/repos`
respect `~/repos/.gitignore` and skip every nested checkout, so a search for a
repo by name finds nothing. Pass `-I` (`fd`) / `--no-ignore` (`rg`), or use the
path directly. (2026-11-24: `fd '^dust$' ~/repos` missed
`~/repos/external/dust`, and the session cloned dust into the scratchpad.)

## Key Workflows

### Repository Activity

Run `/repo-activity` (user-global skill) to scan all repos and see recent activity: last commit info, active projects, uncommitted changes, and current branches.

### Scheduled Routines

`.routines/README.md` inventories scheduled work (LaunchAgents in `.routines/`, Claude scheduled tasks in `~/.claude/scheduled-tasks/`), says where each keeps its schedule and run history, and has § Choosing a scheduler. `just routines` lists the LaunchAgents with live status; it does not cover the Claude tasks.

### Podio Ticket Management

See `ForumViriumHelsinki/CLAUDE.md` for Podio Kanban workflows; `/podio-ticket-updates` is an FVH-scoped skill (`ForumViriumHelsinki/.claude/skills/`).
