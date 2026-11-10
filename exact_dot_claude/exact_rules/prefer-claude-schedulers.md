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

## Making a Claude task survive a machine change

The schedule, folder and permission mode live in app or account state, which
no file captures. Keep everything else versioned:

- The task's `SKILL.md` is one line pointing at a `PROMPT.md` in a repo. Run the
  task with **worktree on**, so the pointer resolves against a fresh
  `origin/main`. Use permission mode **auto**, so an unattended run does not
  wait for an approval.
- Record the task ID, cron, folder, worktree and permission mode next to the
  prompt, so the task can be re-created by hand.
- The run's output goes to a durable, OS-independent sink such as a log issue,
  not to a local log file.

## Do not move a deterministic job onto an LLM for its own sake

Every Desktop or cloud run consumes subscription usage. A `just` recipe that an
agent runs and pastes unchanged costs tokens and adds nothing. A job that does
no judgment goes to substrate 3, or stays where it is. Move it to 1 or 2 only
when the agent also acts on the output: triaging it, filing issues, or cleaning
up what the report found.

The comparison table and per-job notes for the `~/repos` portfolio are in
`~/repos/.routines/README.md` § "Choosing a scheduler".
