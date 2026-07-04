# Taskwarrior — Cross-Session Work Tracking

The local `task` CLI (Taskwarrior 3.x, data in `~/.local/share/task/`) is the
**persistent backlog across sessions**. The in-conversation TaskCreate/TaskList
tools die with the session; anything that must outlive it belongs in
taskwarrior. (Merged 2026-07 from `taskwarrior-tracking.md` +
`taskwarrior-cross-session.md`. Bulk/batch mechanics: see
`taskwarrior-bulk-operations.md`.)

## When to add a task

All of these true:

- **Concrete and actionable** (not "think about X someday" — those rot)
- **Won't finish this session**: pending user action (`sudo`, manual UI step),
  upstream PR/issue to watch, deferred decision, multi-session work
- **Not already tracked** somewhere durable (GitHub issue/PR, calendar) —
  annotate/link the existing tracker instead of duplicating

Do **not** add tasks for work completed in-session or routine in-flight steps.

## How to add

```sh
task rc.confirmation:no add project:<slug> +<tag> [priority:H|M|L] '<description>'
```

- **`project:`** — one short lowercase slug per long-running area, reused
  consistently (`dotfiles`, `claude-plugins`, `immeral`, `comfyui`,
  `fvh-<service>`; default: repo/directory name). Ask once when unsure, then
  stick to it.
- **Tags** — orthogonal facets: `+upstream` (waiting on third-party),
  `+blocked`, `+followup`, area tags (`+foundry`, `+wan22`, …).
- **`priority:`** — `H` only when genuinely time-sensitive (service down,
  gameplay-blocking); default `M`; `L` for monitoring/nice-to-have.
- **Description** — must make sense in 6 weeks with no other context: include
  PR numbers, file paths, decision criteria.
- **Annotate references**: `task <id> annotate "See: <url or path>"` so a
  future session picks it up without conversation history.
- **`due:`** only for real deadlines — it's a queue, not a calendar.

## How to inspect

```sh
task project:<slug> list                 # one project's backlog
task +upstream list                      # all upstream-tracking work
task rc.confirmation:no <id> done        # complete
```

For agent/bulk reads prefer `task <filter> export | jq` (always exit-0) over
`list` (exits 1 on empty).

## End-of-session checklist

When wrapping a session that produced durable follow-ups, do this proactively:

1. Skim `task project:<slug> list` first — `modify` near-duplicates rather
   than re-adding.
2. Add each surviving follow-up with project + tags + annotations
   (3–6 well-chosen tasks beat 20 noisy ones).
3. Mention what got logged in the closing summary so the user can adjust.

## What this is *not*

- Not a replacement for GitHub issues (project-owned) — taskwarrior is the
  personal cross-project queue.
- Not a replacement for in-session TaskCreate (tracks work *during* the
  conversation).

## Bootstrap

If `task` errors with "Cannot proceed without rc file":

```sh
mkdir -p ~/.local/share/task
echo "data.location=~/.local/share/task" > ~/.taskrc
```
