---
reviewed: 2026-10-30
---

# Disk-Full Recovery — When Bash Stops Working

When root (`/`) fills up, the harness can't write Bash output files: **every**
Bash call fails instantly with
`ENOSPC: no space left on device, open '/tmp/claude-.../tasks/<id>.output'`
— regardless of the command. This is a hard stop the agent cannot fix itself.

**The invariants:**

1. Recognize the signature (ENOSPC on the harness's own output path, every
   call) — do **not** retry Bash commands; they fail identically until space
   is freed.
2. Hand the user recovery commands with the `! <cmd>` prefix so output lands
   in the conversation: start with `! df -h /` and
   `! du -shx ~/.cache/* 2>/dev/null | sort -h | tail -10`.
3. Prefer tools' own cleanup commands over `rm -rf`, and redirect caches
   afterwards so it does not recur (`HF_HOME`: `tools-plugin:hf-downloads`).
   The Skill tool still works with Bash down, so load the platform skill for
   the cleanup commands to hand over.

For the full space-hunt playbook, pick by platform:

- **macOS** — the `macos-plugin:macos-disk-usage` skill (APFS snapshots,
  OrbStack images, offender tables).
- **Linux** — the `linux-plugin:linux-disk-usage` skill (every mount, the
  suspects scan, runner workspaces, swapfile beside zram, model stores on a
  data drive, archive-verify-delete onto another disk).

On either platform, `just -g reclaim-dry` / `reclaim` run the scripted sweep
of build artifacts and package caches. The weekly unattended run is a
launchd job, so it exists on macOS only.
