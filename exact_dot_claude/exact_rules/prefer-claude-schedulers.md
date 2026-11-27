# Scheduled Work — Prefer Claude Code's Schedulers Over LaunchAgents

A LaunchAgent, systemd timer, cron entry or Task Scheduler job ties a job to one
OS and one machine, and nothing restores it on a new one. Before adding a
scheduled job, or when touching an existing OS-level one, pick the first
substrate that can do the job:

1. **Routine, cloud environment** (`/schedule`): needs only the repos it
   clones plus connectors. No local files, no cross-repo `gh`.
2. **Routine, bridge environment** (`/schedule`, environment kind `bridge`):
   needs local files, local tools, or `gh` across many repos.
3. **Desktop local task**: as 2, when Lauri prefers the Desktop app. Lauri
   creates it in the app; no agent tool can.
4. **GitHub Actions `schedule:`**: deterministic work with no judgment that
   needs only the GitHub API.
5. **OS scheduler**: last resort, only when the job must run without Claude and
   needs local state. Write down why 1–4 do not fit, next to the job.

**Claude creates routines itself** by invoking the `schedule` skill (deferred
`RemoteTrigger` tool). Offer to create the routine and create it once Lauri
approves; do not hand Lauri the steps or a claude.ai link. Only deleting a
routine needs claude.ai/code/routines.

A job that does no judgment never moves to 1–3 for its own sake: every run
consumes subscription usage. Per-substrate limits and how to set a Claude task
up (versioned `PROMPT.md`, worktree on, auto mode, durable output sink):
`~/.local/share/chezmoi/docs/scheduled-work.md`.
