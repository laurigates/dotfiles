---
journal: obsidian
journal_path: ~/Documents/LakuVault/FVH/notes
journal_template: ~/Documents/LakuVault/Templates/FVH Daily.md
journal_log_heading: "## Log"
journal_todo_heading: "## Todo"
journal_todo_stop: "### Recurring reminders"
journal_scopes: [fvh, infrastructure]
---

# Scope detection

The session is in journal (FVH) scope if **any** of these are true:

- The taskwarrior project for the active work is `fvh.*` or `infrastructure*`
- The working directory path contains `ForumViriumHelsinki` or `repos/ForumVirium`
- The user explicitly says so ("this is FVH work", "log to FVH daily")
- The conversation referenced FVH repos, Podio items, simpl-eval, TFDS,
  Hetzner, GKE, fvh-cluster, fvh.fi, fvh.io, etc.

Default to **out-of-scope** when in doubt — better to skip the daily note
than spam it. If unsure, ask the user once: "FVH-scoped? (y/n)".

Non-FVH sessions (immeral, claude-plugins, dotfiles, personal projects)
get **only** the taskwarrior pass (plus GitHub issues if applicable) — the
FVH daily note stays clean.

# Project naming map

Follow `~/.claude/rules/taskwarrior-cross-session.md`. Common projects in
this user's queue:

| Context | `project:` |
|---|---|
| FVH infrastructure work | `fvh.<area>` — `fvh.cost-attribution`, `fvh.renovate-cleanup`, `fvh.archival`, etc. |
| FVH simpl-eval | `infrastructure.simpl-eval` |
| FVH infrastructure (generic) | `infrastructure` |
| Personal claude-plugins work | `claude-plugins`, `claude-plugins.friction`, `claude-plugins.project-plugin` |
| Dotfiles / chezmoi | `dotfiles` |
| Immeral D&D vault | `immeral` |

If the active work doesn't match any existing project, list options with
`task _projects` and ask the user once.

# FVH daily note — append targets

The template (`Templates/FVH Daily.md`) has these sections in order:
`Log`, `Thoughts`, `Discoveries`, `Todo`, `Recurring reminders`, `Links`,
`Scheduled tasks`. Append to `## Log` and `## Todo` only.

- Don't touch `Thoughts` / `Discoveries` (the user's own voice) or
  `Recurring reminders` / `Links` / `Scheduled tasks` (structural).
- When appending under `## Todo`, place new items *before* the
  `### Recurring reminders` subheading. The Todo section is a flat list of
  `- [ ]` checkboxes.
- Use Obsidian-style `[[...]]` links for cross-references; full URLs for
  PRs / Podio / external systems.
