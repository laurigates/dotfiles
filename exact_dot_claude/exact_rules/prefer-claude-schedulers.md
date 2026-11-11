# Scheduled Work — Prefer Claude Code's Schedulers Over LaunchAgents

Lauri aims for workflows that move between machines and operating systems. A
macOS LaunchAgent (or a systemd timer, cron entry or Task Scheduler job) ties a
job to one OS and one machine, and nothing restores it on a new one. Before
adding a scheduled job, or when touching an existing OS-level one, pick the
first substrate in this list that can do the job:

| # | Substrate | Use when | Limits |
|---|---|---|---|
| 1 | **Cloud routine** (`/schedule`, claude.ai/code/routines) | The job needs only the repos it clones, plus connectors, and should run with the machine off | Min interval 1 h. Reaches only the cloned repos: no cross-repo `gh`, no GraphQL. No local files |
| 2 | **Desktop local task** (Desktop > Routines > New > Local) | The job needs local files, local tools, or `gh` across many repos | Runs only while the app is open and the machine awake, with one catch-up run for a miss within 7 days. Desktop runs on macOS, Windows and Linux (beta) |
| 3 | **GitHub Actions `schedule:`** | Deterministic work with no judgment that needs only the GitHub API | Not a Claude scheduler, but versioned, OS-independent and runs no LLM |
| 4 | **OS scheduler** (LaunchAgent, systemd, cron) | Last resort. Use it only when the job must run without Claude and needs local state, e.g. pulling the config that Claude itself loads | Write down why 1–3 do not fit, next to the job |

A job that does no judgment never moves to 1 or 2 for its own sake: every run
consumes subscription usage. Before setting up a Claude task, read
`~/.local/share/chezmoi/docs/scheduled-work.md` (versioned `PROMPT.md`,
worktree on, auto mode, durable output sink); the per-job portfolio notes are in
`~/repos/.routines/README.md` § "Choosing a scheduler".
