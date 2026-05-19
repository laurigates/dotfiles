---
name: session-spinup
description: Spin up a working session by surfacing the project's open threads. Pulls the taskwarrior queue for the inferred project, the unchecked Todos from the most recent FVH daily note when work is FVH-scoped, and recent git state (current branch, uncommitted changes, unpushed commits, open PRs). Read-only — does not write to taskwarrior or the vault. Use when the user says "spin up", "session start", "pick up where I left off", "what was I doing", or invokes /session-spinup. May also be triggered by a SessionStart hook nudge — when an FVH-scoped session opens with pending threads, the hook injects a one-time reminder to offer this skill.
created: 2026-05-13
modified: 2026-05-13
---

# /session-spinup

Read-only orientation at session start. The inverse of `/session-wrap`:
where wrap writes loose threads, spinup reads them back. The default
failure mode this skill prevents: the user sits down, doesn't remember
what was open, and starts fresh on something else while yesterday's PR
sits stale and the daily-note Todo from yesterday rots unchecked.

Three sources, picked by context:

| Source | When | What comes from there |
|---|---|---|
| **taskwarrior** | Every spin-up | Pending tasks for the inferred project; `+ACTIVE` tasks (lock state); recently-annotated tasks |
| **FVH Obsidian daily note** | Only when FVH-scoped | Unchecked `- [ ]` items under `## Todo` from the most recent FVH daily note (up to 7 days back) |
| **git state** | Every spin-up | Current branch, uncommitted changes, unpushed commits, open PRs from this branch |

Non-FVH sessions (immeral, claude-plugins, dotfiles, personal projects)
get **only** the taskwarrior + git passes — the daily-note source stays
silent.

## Detecting FVH scope

The session is FVH-scoped if **any** of these are true:

- Taskwarrior project for the active work is `fvh.*` or `infrastructure*`
- Working directory path contains `ForumViriumHelsinki` or `repos/ForumVirium`
- The user explicitly says so ("this is FVH work", "FVH spinup")
- The conversation referenced FVH repos, Podio items, simpl-eval,
  TFDS, Hetzner, GKE, fvh-cluster, fvh.fi, fvh.io, etc.

Default to **non-FVH** when in doubt — better to skip the daily-note
read than to dredge through it for a non-FVH session.

## The signal filter — what gets surfaced

This is the whole point of the skill. Spinup is the mirror of wrap:
surface only what the user would otherwise miss when they sit down.

### SURFACE IT — qualifies

- An **open PR** from a recent branch, not yet merged — especially if
  it has been waiting on review/CI for a meaningful number of days
- A **`+ACTIVE` task** (work-in-progress lock state) — the user was
  in the middle of something
- An **unchecked Todo from yesterday** (or the most recent daily note
  within 7 days) under `## Todo`
- **Uncommitted changes** that aren't WIP-junk — actual in-flight
  edits the user paused on
- **Unpushed commits** on the current branch — work that hasn't
  reached the remote yet
- A **task annotated as "blocked on X"** where X may now be unblocked
  (e.g. PR landed, reviewer responded, deploy completed)

### DO NOT SURFACE — noise

- Tasks **completed yesterday** (`status:completed`) — they're done
- **Merged PRs** — no action required
- **Routine daily reminders** — the daily note's
  `### Recurring reminders` subsection is structural, not signal
- **Scheduled tasks** dataview block — Obsidian's own machinery
  surfaces those at render time
- The **conversational context** — there isn't one yet; this is a
  fresh session
- **Tasks pending for weeks with no recent annotation** — they're not
  this session's signal; let `/task-status` handle the cross-project
  rot sweep

Same 3-6 items target as wrap. 10+ means the filter is too loose —
trim to what the user would actually want to act on this session.

## The workflow

### 1. Detect

Infer the active project from:

- `cwd` — `repos/ForumViriumHelsinki/infrastructure` → `infrastructure`;
  `.local/share/chezmoi` → `dotfiles`; `repos/laurigates/claude-plugins`
  → `claude-plugins`
- `git remote get-url origin` — falls back to repo name when cwd is
  ambiguous
- Any taskwarrior task currently `+ACTIVE` — its `project:` wins over
  cwd-inferred name (the user was mid-task)

If multiple projects are detectable (monorepo, multi-package), survey
each in its own section.

### 2. Survey

Pull from the three sources in parallel-safe form:

```sh
# Taskwarrior — `export | jq` is exit-0 on empty (see rules/parallel-safe-queries.md)
task project:<name> '(status:pending or +ACTIVE)' export | jq '.[]'

# Git state
git -C "$cwd" status --porcelain
git -C "$cwd" log '@{u}..HEAD' --oneline
git -C "$cwd" branch --show-current

# Open PRs for the current branch
gh pr list --head "$(git -C "$cwd" branch --show-current)" \
  --json number,title,url,state,createdAt --jq '.[]'
```

For the daily-note source (FVH only), walk back from today:

```sh
for offset in 0 1 2 3 4 5 6 7; do
    day=$(date -v-"${offset}"d +%Y-%m-%d)  # macOS; GNU: date -d "-${offset} day"
    note="$HOME/Documents/LakuVault/FVH/notes/$day.md"
    [ -f "$note" ] || continue
    awk '
        /^## Todo[[:space:]]*$/ { in_todo = 1; next }
        in_todo && /^### Recurring reminders/ { in_todo = 0 }
        in_todo && /^## / { in_todo = 0 }
        in_todo && /^- \[ \]/ { print }
    ' "$note"
    break  # first note found wins
done
```

### 3. Present

Compact briefing, one section per source. No mutating actions in this
phase — spinup is read-only. Example:

```
Spin-up — project: fvh.cost-attribution (cwd: repos/ForumViriumHelsinki/infrastructure)

  taskwarrior (3 pending)
    +ACTIVE  #237 "Cluster fallback rules"
             annot: PR #1774 awaiting review (data-dev), opened 2026-05-04
             [11 days stale — reviewer may have responded; check]
    pending  #240 "Confirm Hetzner db01-03 shutdown date with Aapo (#838)"
    pending  #243 "OpenCost re-evaluation date (ADR-0029 deferred)"

  FVH daily 2026-05-12.md (yesterday)
    - [ ] Nudge production GKE Standard PR #1607 reviewers (stale 7d)
    - [ ] Decide on OpenCost re-evaluation date

  git state (branch: feat/cluster-fallback-rules)
    PR #1774 OPEN — 11d since open, 3 unpushed commits ahead of origin

Next moves:
  • Resume #237 — check PR #1774 review state
  • Tackle yesterday's Todo: nudge PR #1607 reviewers
  • Confirm Hetzner shutdown date (#240, blocks #838)
```

### 4. Offer next moves

Concrete, actionable options. Let the user pick — don't auto-resume
a task or start a workflow. The user may want to look at something
else entirely; the spin-up just makes the open threads visible.

## Project naming rules (taskwarrior)

Follow `~/.claude/rules/taskwarrior-cross-session.md`. Same projects
as wrap:

| Context | `project:` |
|---|---|
| FVH infrastructure work | `fvh.<area>` — `fvh.cost-attribution`, `fvh.renovate-cleanup`, `fvh.archival`, etc. |
| FVH simpl-eval | `infrastructure.simpl-eval` |
| FVH infrastructure (generic) | `infrastructure` |
| Personal claude-plugins work | `claude-plugins`, `claude-plugins.friction`, `claude-plugins.project-plugin` |
| Dotfiles / chezmoi | `dotfiles` |
| Immeral D&D vault | `immeral` |

When the cwd doesn't map cleanly to a known project, list options
with `task _projects` and ask the user once.

## Daily-note read shape

Parse the most recent `~/Documents/LakuVault/FVH/notes/YYYY-MM-DD.md`
(today first, then walk back up to 7 days; stop at the first match).
Extract unchecked `- [ ]` lines from the `## Todo` section.

Stop the extraction at the first of:

- `### Recurring reminders` subheading (those are structural reminders,
  not signal)
- The next `## ` heading (e.g. `## Links`, `## Scheduled tasks`)

Skip the dataview `## Scheduled tasks` block — Obsidian's own
machinery surfaces those when the user opens the vault. Spinup is
filling in what the terminal-only view can't see.

## Edge cases

- **No FVH daily note exists** for the last 7 days — silently skip
  the daily-note source. Still show taskwarrior + git state.
- **Multiple projects detectable** from cwd (monorepo, multi-package)
  — present each project's slice in its own section.
- **No taskwarrior tasks for the project** — say so explicitly
  (`nothing pending under project:<name>`) rather than emit an empty
  section that looks broken.
- **No open PRs and clean working tree** — say "git state: clean" in
  one line rather than omitting the section.
- **User in plan mode / interactive UI** — don't auto-run; just
  present the briefing.
- **All sources empty** — say so briefly ("nothing open under
  `project:<name>`; clean working tree; no recent FVH Todos"), then
  step out of the way. Spinup is informational; the user can take it
  from there.

## Auto-surfacing via SessionStart hook

A SessionStart hook at `~/.claude/hooks/session-spinup-nudge.sh`
watches for fresh session entries and injects a one-time reminder per
session to **offer** this skill. The hook fires only when **all** of
these hold:

- The SessionStart `source` is `startup` or `resume` (silent on
  `compact`/`clear` — those are mid-session continuations)
- FVH context is detected (cwd, git remote, or active taskwarrior
  `fvh.*` / `infrastructure*` project)
- At least **one** of these is non-empty:
  - Pending or `+ACTIVE` taskwarrior tasks under an FVH project
  - Unchecked `- [ ]` items in the most recent FVH daily note (7 days)
  - Uncommitted changes or unpushed commits on the current branch
- No prior nudge in the same session (state file in
  `~/.cache/claude-session-spinup-nudge/<session_id>`)

When triggered, the agent should briefly **offer** the spin-up, not
run it. Run only after user confirmation. If everything is clean
(taskwarrior empty, no FVH Todos, clean tree), the hook stays silent
— spinup doesn't nudge for nothing.

To disable temporarily: `touch ~/.cache/claude-session-spinup-nudge/<session_id>`
before the hook fires, or remove the SessionStart entry from
`~/.claude/settings.json`.

## Rationale

The taskwarrior-cross-session rule says "log work that outlives the
session". `/session-wrap` writes; this skill is the read-side at the
natural pickup checkpoint. Without it, the queue and the FVH daily
note become write-only: the user diligently logs follow-ups at end of
session, then never sees them when they sit down next. Spinup closes
that loop — at minimum the taskwarrior queue, plus the FVH daily
note's Todos and the git state, all visible in 30 seconds before the
user picks the next move.
