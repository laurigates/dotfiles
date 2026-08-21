---
paths:
  - "**/LaunchAgents/*.plist"
  - "**/*.plist"
  - "**/justfile"
  - "**/Justfile"
  - "**/*.just"
  - "**/crontab"
  - "**/Documents/LakuVault/**"
---

# A CLI Shipped With a GUI App May Be a *Client* of It — Probe Before Automating

A desktop app that also ships a `cli` binary invites the assumption that the CLI
is a standalone, scriptable implementation of the app. Often it is not: it is a
**remote control that talks to the running GUI process**, and every command fails
when the app is closed. Automation built on it — a LaunchAgent, a cron job, a
headless CI step, a background agent session — then works whenever a human
happens to have the app open and fails silently the rest of the time.

The tell is absent by construction: `--help` documents the *commands*, never the
requirement that the app be running. You only learn it by closing the app.

## The check — one probe, read the exit code

Run the cheapest read-only subcommand **with the app closed**:

```
obsidian sync:status ; echo "rc=$?"
```

A non-zero exit with a message naming the app is the answer. Do this *before*
designing anything around the CLI, not after wiring the schedule.

## `pgrep -f <AppName>` is not a liveness check

The instinct on getting that error is to check whether the app is running, and
`pgrep -f` is the wrong instrument: `-f` matches the **whole command line**,
including the environment, so any process whose `PATH` contains the app's bundle
matches. A confident, well-formed hit for an app that is not running.

```
pgrep -fl Obsidian     # matched an MCP server whose PATH held
                       # /Applications/Obsidian.app/Contents/MacOS
```

Probe the **interface** (the CLI's own exit code), never the process table. Same
family as `tool-use-patterns.md`'s rejected-flag trap: output that is well-formed
and confident while not meaning what it appears to.

## Evidence

> 2026-08-09. Asked whether the `obsidian` CLI could drive Obsidian Sync
> headlessly — it has `sync`, `sync:status`, `sync:history`, `sync:restore`,
> `sync:deleted`, which reads as a scriptable surface. With the app quit:
> `The CLI is unable to find Obsidian. Please make sure Obsidian is running`
> (rc=1). No headless path exists at all, so the narrower question that prompted
> it (does `sync off` + `sync on` force a sync pass?) was moot for automation.
> The `pgrep` check run alongside it returned a false positive from `PATH`.

## Consequences

- **Scoped conclusion, not a global one.** "No headless sync" does not mean "no
  automation" — it means the trigger must come from elsewhere: the app's own
  logs, file mtimes, the service's web API, or accepting that the app is
  normally open. Say which.
- **Do not report a capability from `--help` alone.** A command list is a claim
  about vocabulary, not about whether it runs unattended.
- For this machine's vault specifics (Obsidian Sync vs. the local autocommit
  LaunchAgent, and the reload trap), see `LakuVault/CLAUDE.md` §
  *Backup and Version Control*.
