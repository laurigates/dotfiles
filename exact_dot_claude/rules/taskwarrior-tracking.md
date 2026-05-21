# Taskwarrior — Tracking Durable Follow-ups

Use the local `task` CLI (Taskwarrior 3.x, data in
`~/.local/share/task/`) as the **persistent backlog across sessions**.
The in-conversation TaskCreate/TaskList tools are for *this* session;
once the session ends they're gone. Anything that needs to outlive
the session — a pending external action, an upstream PR to watch, a
follow-up decision — belongs in Taskwarrior.

## When to populate

Add a Taskwarrior task when the work produced one of these:

- **Pending user action** the agent can't perform itself
  (`sudo systemctl restart`, `gcloud auth login`, manual review).
- **Upstream tracking** that spans days/weeks (PR review, issue
  monitoring, "re-apply patch after next upgrade").
- **Decisions deferred** out of the current session
  ("decide whether to switch from Mode A to Mode B next week").
- **Multi-session work** where the next step happens after the user
  comes back ("finish migrating remaining 3 services").

Do **not** add a task for work that completed cleanly inside the
session, or for routine in-flight steps (those belong in
TaskCreate/TaskList only).

## How to add

The CLI accepts task descriptions with `+tags`, `project:foo`, and
`priority:H|M|L`. Use `rc.confirmation:no` so the agent doesn't get
stuck on a confirmation prompt:

```sh
task rc.confirmation:no add project:<repo-or-area> +<tag> [+<tag>...] \
  [priority:H] '<description>'
```

Conventions:

- **`project:`** — short slug naming the area (`comfyui`, `dotfiles`,
  `claude-plugins`, `fvh-<service>`). One word, lowercase.
- **Tags** — orthogonal facets. Common ones:
  `+upstream` (waiting on a third-party repo),
  `+remix`/`+wan22`/`<feature>` (sub-area within the project),
  `+followup` (deferred decision),
  `+blocked` (waiting on something external).
- **`priority:H`** only when the task is genuinely time-sensitive
  (service is down, deploy is broken). Default unset.
- **Description** — write so it makes sense in 6 weeks with no
  other context. Reference PR numbers, file paths, decision criteria
  in the description itself.

## How to inspect

```sh
task project:<slug> list                   # backlog for one project
task +upstream list                        # all upstream-tracking work
task rc.confirmation:no <id> done          # complete a task
task rc.confirmation:no <id> modify +urgent priority:H   # bump
```

For any agent-friendly bulk read, use `export | jq` (always exit-0)
rather than `list` (exits 1 on empty), per
`parallel-safe-queries.md`.

## End-of-session checklist

When wrapping a session that produced durable follow-ups:

1. Add a task for each one, with project + tags.
2. Mention the additions in the closing summary so the user knows
   they're recorded.
3. Don't duplicate: skim `task project:<slug> list` first; update
   an existing task with `modify` rather than adding a near-duplicate.

## Bootstrap

If `task` errors with "Cannot proceed without rc file":

```sh
mkdir -p ~/.local/share/task
echo "data.location=~/.local/share/task" > ~/.taskrc
```

Taskwarrior 3.x then auto-creates the SQLite store on first write.
