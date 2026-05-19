---
name: session-wrap
description: Wrap up a working session by capturing loose threads. Updates taskwarrior tasks for the current project (done / annotate / add) and appends genuine follow-ups to the FVH Obsidian daily note when the work is FVH-scoped. Filters aggressively for signal — only logs items that won't resurface on their own. Use when the user says "wrap up", "session wrap", "wrap the session", "I'm done for now", or invokes /session-wrap. May also be triggered by a Stop-hook nudge — when the user signals wind-down on an FVH-scoped session, the hook injects a one-time reminder to offer this skill.
created: 2026-05-12
modified: 2026-05-12
---

# /session-wrap

End-of-session capture for the things that **won't surface on their
own** the next time the user sits down. The default failure mode this
skill prevents: useful follow-up work gets agreed in conversation,
the session ends, and a week later the user can't remember what was
left hanging.

Three destinations, picked by context:

| Destination | When | What goes there |
|---|---|---|
| **taskwarrior** | Every wrap | Mark completed tasks done; annotate in-flight tasks with PR / blocker / current state; add new tasks for surfaced threads |
| **FVH Obsidian daily note** | Only when session is FVH-scoped | Narrative `## Log` entry; actionable `## Todo` items the user will want tomorrow |
| **GitHub issues** | Only when cwd is a git repo with a `github.com` origin AND a PR was merged this session (or is about to be) with post-merge follow-ups | One issue per follow-up, linked from the PR description (per `~/.claude/CLAUDE.md` — checklists in PR bodies vanish after merge) |

Non-FVH sessions (immeral, claude-plugins, dotfiles, personal projects)
get **only** the taskwarrior pass (plus GitHub issues if applicable) —
the FVH daily note stays clean. Sessions outside any git repo, or in a
repo without a github.com origin, skip the GitHub-issue pass entirely.

## Detecting FVH scope

The session is FVH-scoped if **any** of these are true:

- Taskwarrior project for the active work is `fvh.*` or `infrastructure*`
- Working directory path contains `ForumViriumHelsinki` or `repos/ForumVirium`
- The user explicitly says so ("this is FVH work", "log to FVH daily")
- The conversation referenced FVH repos, Podio items, simpl-eval,
  TFDS, Hetzner, GKE, fvh-cluster, fvh.fi, fvh.io, etc.

Default to **non-FVH** when in doubt — better to skip the daily note
than spam it. If you're not sure, ask the user once: "FVH-scoped?
(y/n)".

## The signal filter — what gets logged

This is the whole point of the skill. The user said explicitly: "not
for everything so i dont drown in signals."

### LOG IT — qualifies

- A PR is open and **waiting** (review, CI, merge gate not yet
  cleared) — capture the PR URL and the gate
- A task was started but **couldn't finish this session** — blocked
  on info, awaiting a reply, build broken, dependency missing
- A **manual follow-up** action is required outside Claude Code — UI
  step, person to message, deploy to trigger, infra change to apply,
  config to edit by hand
- A **decision was deferred** ("come back to this later", "we'll
  revisit X")
- A **loose thread surfaced** that wasn't already tracked — bug
  noticed in passing, refactor opportunity, doc to write, follow-up
  to a fix that didn't happen
- An **investigation found something** worth not losing — surprising
  discovery, half-explored hypothesis, file/line worth revisiting

### DO NOT LOG — drown-in-signals patterns

- Work that **finished cleanly this session** — commit landed, PR
  merged, task completed (mark the taskwarrior task done, but don't
  narrate it in the daily note)
- Anything **already tracked** as a GitHub issue, PR description, or
  existing taskwarrior task that didn't change state — duplicates
  add noise, not signal
- **Routine ops** the user does every day — running `just lint`,
  checking PRs, syncing dotfiles
- **Self-resolving items** — "CI is still running" usually doesn't
  need a follow-up unless it's been red for a meaningful reason
- **Conversational context** — what the user asked, what files were
  read, what the agent decided — that's all in the transcript
- **Speculation** — "we might want to refactor X someday"; that's a
  rot-magnet, not a follow-up

When in doubt, ask: *"If I don't write this down, will the user
notice the gap when they sit down tomorrow?"* If yes → log it. If no
→ skip it. 3-6 items per wrap is the right shape. 10+ means the
filter is too loose.

## The workflow

### 1. Survey

Quickly enumerate what the session touched. Look at:

- Recent commits on the active branch (`git log --oneline -20`)
- Open PRs on the active branch (`gh pr list --head $(git branch --show-current)`)
- Existing taskwarrior tasks for the inferred project
  (`task project:<name> status:pending export | jq '.[]'`)
- Any tasks marked `+ACTIVE` by the in-session work
- The conversation itself — what was kicked off but not finished,
  what was discussed but not done

### 2. Categorise

For each candidate item, classify as one of:

| Category | Action |
|---|---|
| Done this session | `task <id> done` (taskwarrior only — no daily note) |
| In-flight, well-tracked | Annotate the existing task with the new state |
| In-flight, untracked | Either add a new taskwarrior task **or** a daily-note Todo (not both) |
| Loose thread, FVH | Daily note `## Log` (narrative) or `## Todo` (action) |
| Loose thread, non-FVH | Taskwarrior only, with `project:<name>` |
| Post-merge follow-up (GitHub repo) | One `gh issue create` per follow-up; link each from the just-merged PR description. Skip if cwd has no github.com origin |
| Noise (per filter above) | Skip silently |

### 3. Preview

Show the user a compact preview before writing **anything**:

```
About to wrap:

  taskwarrior (project: fvh.cost-attribution)
    done:   #234 "Land #1778 GKE cost allocation"
    annot:  #237 "Cluster fallback rules" — PR #1774 waiting on review
    add:    "Ping Aapo re Hetzner db01-03 shutdown decision (Podio #838)"

  FVH daily 2026-05-12.md
    Log:    Pulled cost-attribution timeline for data-dev. Open thread:
            cluster fallback resolution rules (PR #1774, 7+ days stale).
    Todo:   - [ ] Confirm Hetzner db shutdown date with Aapo (#838)
            - [ ] Nudge production GKE Standard PR #1607 reviewers

Apply? (y/n)
```

Wait for the user to confirm. They may want to redact items or add
ones. Don't write the daily note silently — it's part of their
personal vault.

### 4. Apply

For taskwarrior:

```sh
# Mark done
task <id> done

# Annotate in-flight
task <id> annotate "PR #1774 awaiting review (data-dev), opened 2026-05-04"

# Add new
task add project:fvh.archival priority:M +follow-up \
  "Ping Aapo re Hetzner db01-03 shutdown decision (Podio #838)"
task <id> annotate "See: https://podio.com/fvh/iot-workspace/apps/datadev-kanban/items/838"
```

For the FVH daily note at `~/Documents/LakuVault/FVH/notes/YYYY-MM-DD.md`:

- If the file doesn't exist, create it from
  `~/Documents/LakuVault/Templates/FVH Daily.md` (preserves frontmatter
  and `## Scheduled tasks` dataview block)
- Append the narrative items under `## Log`
- Append the actionable items as `- [ ]` checkboxes under `## Todo`
- Use Obsidian-style `[[...]]` links for cross-references; full URLs
  for PRs/Podio/external

### 5. Report

One-paragraph summary of what was written and where, plus the count
of items skipped as noise so the user can sanity-check the filter
was tight.

## Project naming rules (taskwarrior)

Follow `~/.claude/rules/taskwarrior-cross-session.md`. Common
projects in this user's queue:

| Context | `project:` |
|---|---|
| FVH infrastructure work | `fvh.<area>` — `fvh.cost-attribution`, `fvh.renovate-cleanup`, `fvh.archival`, etc. |
| FVH simpl-eval | `infrastructure.simpl-eval` |
| FVH infrastructure (generic) | `infrastructure` |
| Personal claude-plugins work | `claude-plugins`, `claude-plugins.friction`, `claude-plugins.project-plugin` |
| Dotfiles / chezmoi | `dotfiles` |
| Immeral D&D vault | `immeral` |

If the active work doesn't match any existing project, list options
with `task _projects` and ask the user once.

## Templates

### FVH daily note — section append targets

The template (Templates/FVH Daily.md) has these sections in order:
`Log`, `Thoughts`, `Discoveries`, `Todo`, `Recurring reminders`,
`Links`, `Scheduled tasks`. Append to `## Log` and `## Todo` only.
Don't touch `Thoughts` / `Discoveries` (those are the user's own
voice) or `Recurring reminders` / `Links` / `Scheduled tasks`
(structural).

When appending under `## Todo`, place new items *before* the
`### Recurring reminders` subheading. The Todo section is a flat
list of `- [ ]` checkboxes.

### Log entry shape

Keep `## Log` entries short and contextual — one or two sentences
each, with a `[[wikilink]]` or URL for follow-through. Group by
topic if you have 3+ items.

```
- Cost-attribution: data-dev weekly talking points pulled; PR #1778 landed; #1774 still open after 7 days. See [[2026-05-12]] for the full list.
- Hetzner decom: confirmed db01-03 + dckr2/3 + geo.fvh.fi need owner pings before shutdown. Tracked in Podio #838/839/837.
```

### Todo entry shape

Each is a single `- [ ]` line with enough context to act without
re-reading the conversation:

```
- [ ] Nudge production GKE Standard PR #1607 reviewers (stale 7d, ADR-0024)
- [ ] Confirm Hetzner db01-03 shutdown date with Aapo (Podio #838)
- [ ] Decide on OpenCost re-evaluation date (ADR-0029 deferred)
```

## Edge cases

- **Multiple projects touched in one session** — wrap each project
  independently; show one preview block per project.
- **No active project detected** — ask the user which project to log
  under (or "skip taskwarrior pass").
- **Daily note already has entries from a prior wrap today** — append
  cleanly; don't deduplicate aggressively (the user can manually
  prune). Do skip exact-string duplicates.
- **User wants to skip the daily note** for an FVH session — honor
  it. The taskwarrior pass still runs.
- **User wants to log to daily note for a non-FVH session** — honor
  it (e.g. dotfiles work that wants narrative continuity). Default
  off, override on.

## Auto-surfacing via Stop hook

A Stop hook at `~/.claude/hooks/session-wrap-nudge.sh` watches for
session wind-down signals and injects a one-time reminder per session
to **offer** this skill. The hook fires only when **all** of these
hold:

- The session has ≥ 6 user turns (not a quick lookup)
- FVH context is detected (cwd, git remote, or active taskwarrior
  `fvh.*` / `infrastructure*` project)
- One of the last 3 user messages matches a wind-down phrase
  (`wrap up`, `done for the day`, `calling it`, `signing off`,
  `gotta go`, `end of day`, etc.)
- No prior nudge in the same session (state file in
  `~/.cache/claude-session-wrap-nudge/<session_id>`)

When triggered, the agent should briefly **offer** the wrap, not run
it. Run only after user confirmation. If the session has no genuine
follow-up-worthy threads, the right move is to acknowledge the wind-
down and end — drown-in-signals is the failure mode to avoid.

To disable temporarily: `touch ~/.cache/claude-session-wrap-nudge/<session_id>`
before the hook fires, or remove the Stop entry from
`~/.claude/settings.json`.

## Rationale

The taskwarrior-cross-session rule already says "log work that
outlives the session to taskwarrior". This skill **enforces** that
rule at the natural checkpoint (end of session) and adds a second
destination — the FVH daily note — for the narrative continuity that
taskwarrior alone can't provide. The signal filter is the whole
value: a wrap that captures 4 real loose threads beats a wrap that
mechanically lists everything the session touched.
