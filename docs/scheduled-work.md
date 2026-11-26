# Scheduled Work — Keeping Claude Tasks Portable

Detail for the `prefer-claude-schedulers.md` rule
(`exact_dot_claude/exact_rules/`, rendered to `~/.claude/rules/`). The rule
holds the substrate ordering; this page holds each substrate's limits and how
to set a chosen task up.

## Substrate limits

Lauri aims for workflows that move between machines and operating systems, which
is why the rule ranks OS schedulers last. Numbers follow the rule's list.

| # | Substrate | Use when | Limits |
|---|---|---|---|
| 1 | **Routine, cloud environment** (`/schedule`, claude.ai/code/routines) | The job needs only the repos it clones, plus connectors, and should run with the machine off | Min interval 1 h. Reaches only the cloned repos: no cross-repo `gh`, no GraphQL. No local files |
| 2 | **Routine, bridge environment** (`/schedule`, environment kind `bridge`, e.g. `<host>:repos:<id>`) | The job needs local files, local tools, or `gh` across many repos, and Claude should create it | Runs on the bridged machine, so presumably only while it is awake and connected (unverified; first run 2026-11-24, `trig_01L4HWmQxsXr43jExQpiFkGQ`) |
| 3 | **Desktop local task** (Desktop > Routines > New > Local) | As 2, when Lauri prefers the Desktop app | Lauri creates it in the app: no agent tool creates one. Runs only while the app is open and the machine awake, with one catch-up run for a miss within 7 days. Desktop runs on macOS, Windows and Linux (beta) |
| 4 | **GitHub Actions `schedule:`** | Deterministic work with no judgment that needs only the GitHub API | Not a Claude scheduler, but versioned, OS-independent and runs no LLM |
| 5 | **OS scheduler** (LaunchAgent, systemd, cron) | Last resort. Use it only when the job must run without Claude and needs local state, e.g. pulling the config that Claude itself loads | Write down why 1–4 do not fit, next to the job |

## Creating a routine from the session

The `schedule` skill drives the deferred `RemoteTrigger` tool (load it with
`ToolSearch("select:RemoteTrigger")`). It creates, updates, lists and runs
routines, and lists the available environments, cloud and bridge, with their
ids. It cannot delete a routine; that is done at claude.ai/code/routines.

Evidence (2026-11-19): `context-diet` was created this way in a bridge
environment, after earlier sessions had told Lauri to create routines by hand.

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
no judgment goes to GitHub Actions `schedule:`, or stays where it is. Move it to
a cloud routine or Desktop local task only when the agent also acts on the
output: triaging it, filing issues, or cleaning up what the report found.

The comparison table and per-job notes for the `~/repos` portfolio are in
`~/repos/.routines/README.md` § "Choosing a scheduler".
