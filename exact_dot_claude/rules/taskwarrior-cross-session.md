# Cross-Session Work Tracking via Taskwarrior

The session-level `TaskCreate` / `TaskList` tools live and die with the conversation. When work emerges during a session that **won't complete in that session** — waiting on a PR to merge, a feature to land, a manual UI step, a verification against an external source, a future re-check — log it to **taskwarrior** so it survives the session boundary.

## When to add a taskwarrior task

Add one when **all** of these are true:

- The work is concrete and actionable (not "think about X someday")
- It can't be finished before the user ends the session
- It isn't already tracked somewhere durable (existing GitHub issue, PR, calendar event)

Don't add tasks for:

- Work the agent completed during the session (the in-session `TaskCreate` tool already captured that)
- Vague aspirations or "maybe someday" ideas — those rot in the queue
- Items that are *already* a GitHub issue / PR — annotate the existing one or link to it from a parent task, but don't duplicate

## Project naming convention

Always set `project:<descriptive-name>`. Use a single, consistent label per long-running area of work so `task project:<name>` filters cleanly.

| Context | `project:` |
|---|---|
| D&D campaign vault (Immeral) | `immeral` |
| Other long-running personal projects | match the repo / directory name |
| Cross-project chores (dotfiles, infra) | `dotfiles`, `infra`, etc. |

When unsure what to use for a new context, ask the user once and then stick to it.

## Annotate with references

Every task that links to something durable should carry an annotation pointing at it:

```sh
task <id> annotate "Doc: Pages/Immeral 2024 Migration Notes.md"
task <id> annotate "See: https://github.com/owner/repo/issues/123"
```

This lets a future agent (or the user) pick up the task with full context without scrolling the conversation history.

## Priority and tags

- `priority:H` — affects gameplay / blocks downstream work
- `priority:M` — improves quality but not blocking
- `priority:L` — nice-to-have, monitoring, follow-up
- Tags scope the work area: `+foundry`, `+dnd`, `+migration`, `+chezmoi`, etc.

Default to `priority:M` if unsure; the user can re-rank with `task <id> modify priority:H`.

## Workflow at session end

When wrapping up a session that produced ongoing work:

1. List the items that survived the session (manual sheet edits, audit follow-ups, blocked-on-tool tasks)
2. Add each to taskwarrior with the right project, tags, priority, and annotations
3. Briefly tell the user what got logged so they can adjust before context closes

Do this proactively when the work clearly outlives the session — don't wait for the user to ask. But also don't over-log: 3-6 well-chosen tasks beats 20 noisy ones.

## What this is *not*

- **Not** a replacement for GitHub issues. Issues belong to the project; taskwarrior is the user's personal cross-project queue.
- **Not** a replacement for in-session `TaskCreate`. That tool tracks active work *during* the conversation; taskwarrior tracks work *between* conversations.
- **Not** a calendar. Use `due:` only when there's an actual deadline.

## Rationale

The default failure mode without this rule: useful follow-up work — "fix the spell-slot consumption on the sheet", "verify the audit items against the PHB", "check if issue #142 has landed" — gets surfaced in conversation, agreed in principle, and then vanishes the moment the session ends. Taskwarrior is the personal queue that bridges sessions. Logging there at the natural checkpoint (end of a piece of work that generated follow-ups) keeps the queue honest and the user out of the "wait, what was I supposed to do next?" trap.
