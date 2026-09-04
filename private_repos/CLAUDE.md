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

Make changes to **this** repo (its `CLAUDE.md`, `.claude/` rules, scripts and
skills) in a Claude Code worktree, not in the main checkout — enter one before
the first edit of a change task. Reading and answering questions do not need one.

The reason is mechanical, not stylistic: `.claude/scripts/repos-sync-nudge.sh`
auto-fast-forwards this checkout only when `git status --porcelain` is empty, so
uncommitted work sitting in the main checkout silently switches that freshness
auto-pull off — in the one repo whose whole job is to hand fresh rules to
everything underneath it. `worktree.baseRef` is `fresh`, so the branch starts
from `origin/main` rather than from wherever this checkout is sitting.

This does **not** extend to the nested project repos underneath: those are
separate checkouts with their own conventions, and `~/repos` deliberately
ignores them.

## Key Workflows

### Repository Activity

Run `/repo-activity` (user-global skill) to scan all repos and see recent activity: last commit info, active projects, uncommitted changes, and current branches.

### Scheduled Routines

Scheduled work runs on two substrates: **macOS LaunchAgents** defined in `.routines/`, and **Claude scheduled tasks** defined user-globally in `~/.claude/scheduled-tasks/`. `.routines/README.md` inventories both, and documents how to choose a substrate (LaunchAgent vs cloud routine vs Desktop task).

`just routines` lists the LaunchAgents with live status — schedule, load state, run count, last exit, last run, log path. It does not cover the Claude scheduled tasks; their schedule and run history live at claude.ai/code/routines. These are experimental/stop-gap; promote useful ones to a cloud routine or CI.

### Podio Ticket Management

See `ForumViriumHelsinki/CLAUDE.md` for Podio Kanban workflows; `/podio-ticket-updates` is an FVH-scoped skill (`ForumViriumHelsinki/.claude/skills/`).
