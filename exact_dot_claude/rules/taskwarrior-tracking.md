# Taskwarrior — Cross-Session Work Tracking

Promoted to skills. Invoke `taskwarrior-plugin:task-add` when filing a follow-up
that must outlive the session — it carries the project/tag/priority conventions,
the annotate-references habit, and the `project:` **prefix-match** trap (a
populated `task project:<slug> list` never proves the slug exists — read exact
values and counts via `task export | jq`). For the end-of-session sweep itself,
invoke `session-plugin:session-wrap` — it carries the log-it/skip-it filter and
the don't-duplicate-an-open-PR/issue rule. Bulk loops:
`taskwarrior-plugin:task-bulk-ops`.
