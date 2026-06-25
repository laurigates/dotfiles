# repos/ - Project Portfolio Overview

This directory contains project repositories organized by owner/origin. Running Claude Code from here provides visibility across all projects for portfolio-level operations.

## Directory Structure

| Directory | Contents |
|-----------|----------|
| `ForumViriumHelsinki/` | Forum Virium Helsinki organization repos ([GitHub](https://github.com/ForumViriumHelsinki)) |
| `laurigates/` | Personal repos ([GitHub](https://github.com/laurigates)) |
| `external/` | Third-party clones and forks (bevy, esp-idf, llama.cpp, moodle, etc.) |
| `archive/` | Inactive/deprecated projects |

## Key Workflows

### Repository Activity

Run `/repo-activity` (user-global skill) to scan all repos and see recent activity: last commit info, active projects, uncommitted changes, and current branches.

### Scheduled Routines

Run `just routines` to list the portfolio's scheduled jobs (macOS LaunchAgents in `.routines/`) with live status — schedule, load state, run count, last exit, last run, and log path. The routines and how to choose a scheduler substrate (LaunchAgent vs cloud routine vs Desktop task) are documented in `.routines/README.md`. These are experimental/stop-gap; promote useful ones to a cloud routine or CI.

### Podio Ticket Management

See `ForumViriumHelsinki/CLAUDE.md` for Podio Kanban workflows; `/podio-ticket-updates` is an FVH-scoped skill (`ForumViriumHelsinki/.claude/skills/`).
