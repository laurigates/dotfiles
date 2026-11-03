# Taskwarrior — Cross-Session Work Tracking

Promoted to skills. Invoke `taskwarrior-plugin:task-add` when filing a follow-up
that must outlive the session. `project:` is a **prefix match**: a populated
`task project:<slug> list` never proves the slug exists, so read exact values
and counts via `task export | jq`. For the end-of-session sweep itself, invoke
`session-plugin:session-wrap`. Bulk loops:
`taskwarrior-plugin:task-bulk-ops`.
