# Scheduled Work — Prefer Claude Code's Schedulers Over LaunchAgents

Lauri aims for workflows that move between machines and operating systems. A
macOS LaunchAgent (or a systemd timer, cron entry or Task Scheduler job) ties a
job to one OS and one machine, and nothing restores it on a new one. Before
adding a scheduled job, or when touching an existing OS-level one, pick the
first substrate in this list that can do the job:

| # | Substrate | Use when | Limits |
|---|---|---|---|
| 1 | **Routine, cloud environment** (`/schedule`, claude.ai/code/routines) | The job needs only the repos it clones, plus connectors, and should run with the machine off | Min interval 1 h. Reaches only the cloned repos: no cross-repo `gh`, no GraphQL. No local files |
| 1b | **Routine, bridge environment** (`/schedule`, environment kind `bridge`, e.g. `<host>:repos:<id>`) | The job needs local files, local tools, or `gh` across many repos, and Claude should create it | Runs on the bridged machine, so presumably only while it is awake and connected (unverified; first run 2026-11-24, `trig_01L4HWmQxsXr43jExQpiFkGQ`) |
| 2 | **Desktop local task** (Desktop > Routines > New > Local) | As 1b, when Lauri prefers the Desktop app | Lauri creates it in the app: no agent tool creates one. Runs only while the app is open and the machine awake, with one catch-up run for a miss within 7 days. Desktop runs on macOS, Windows and Linux (beta) |
| 3 | **GitHub Actions `schedule:`** | Deterministic work with no judgment that needs only the GitHub API | Not a Claude scheduler, but versioned, OS-independent and runs no LLM |
| 4 | **OS scheduler** (LaunchAgent, systemd, cron) | Last resort. Use it only when the job must run without Claude and needs local state, e.g. pulling the config that Claude itself loads | Write down why 1–3 do not fit, next to the job |

## Claude creates routines itself

Claude creates, updates, lists and runs routines from the session by invoking
the `schedule` skill, which drives the deferred `RemoteTrigger` tool (load it
with `ToolSearch("select:RemoteTrigger")`). When a task calls for scheduled
work, offer to create the routine and create it once Lauri approves. Do not
hand Lauri the steps or a claude.ai link to do by hand. The skill lists the
available environments, cloud and bridge, with their ids. The one thing it
cannot do is delete a routine; that is done at claude.ai/code/routines.
(2026-11-19: `context-diet` was created this way in a bridge environment,
after earlier sessions had told Lauri to create routines by hand.)

A job that does no judgment never moves to 1 or 2 for its own sake: every run
consumes subscription usage. Before setting up a Claude task, read
`~/.local/share/chezmoi/docs/scheduled-work.md` (versioned `PROMPT.md`,
worktree on, auto mode, durable output sink); the per-job portfolio notes are in
`~/repos/.routines/README.md` § "Choosing a scheduler".
