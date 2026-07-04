# Quitting the OrbStack GUI Orphans the Helper VM — Use `orb stop`

Closing the OrbStack app (or `osascript quit`) closes only the UI; the
`OrbStack Helper` process **is** the Linux VM and keeps running reparented to
launchd — ~40–50% CPU with no visible app. The tell: after "closing"
OrbStack, `ps -Ao pid,ppid,pcpu,comm | grep -i '[o]rb'` shows the helper with
**PPID 1**.

Fix: `/opt/homebrew/bin/orb stop` (clean VM shutdown; fully reversible with
`orb start` — never `kill` the helper, which skips the VM's own shutdown).
Verify: `ps -Aceo pid,comm -r | grep -i '[o]rb' || echo stopped`.

For broader hot-Mac triage and OrbStack disk reclaim, use the
`macos-plugin:macos-performance-triage` / `macos-disk-usage` skills.
