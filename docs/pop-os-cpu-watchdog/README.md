# Pop!_OS CPU watchdog for `pop-upgrade`

System-level fix for the Pop!_OS workstation (`pop-os`). These files install
into `/etc` and `/usr/local/sbin`, outside chezmoi's `$HOME` scope; `docs/` is
in `.chezmoiignore`, so they are kept here as source only and never applied.

## Problem

`pop-upgrade daemon` (`/usr/bin/pop-upgrade`, root, D-Bus-activated) goes into
a busy loop and pins one core at 100% until someone notices. This has happened
more than once. It usually shows up as a warmer room, not as an alert.

Observed 2026-09-23: PID 291331, started 2026-08-15. Its last log line was on
2026-08-20 13:11 (`release_api.rs:63: checking for build 24.04 in channel
generic`), and it logged nothing afterwards. The main thread was spinning while
all 25 tokio workers sat idle. It had used ~816 CPU-hours (`systemctl status`:
`CPU: 1month 3d 13h`).

Diagnose:

```
top -b -n1 -o %CPU | head -15
systemctl status pop-upgrade --no-pager
journalctl -u pop-upgrade -n 20 --no-pager
```

Manual fix: `sudo systemctl stop pop-upgrade`. The next D-Bus request starts
it again.

## Why not a systemd limit

- `CPUQuota=` only throttles, and it throttles the cgroup, so a real release
  upgrade's `apt`/`dpkg` children would slow down too.
- `RuntimeMaxSec=` kills on elapsed time, so it could stop a real upgrade
  partway through. The unit also has `Restart=on-failure`, which would restart
  it straight away.

## Watchdog

`cpu-watchdog UNIT [LIMIT]` reads utime+stime from `/proc/<MainPID>/stat`. That
covers the daemon's own process only, never its children. It saves the value
in `/run/cpu-watchdog/UNIT`, and on the next run it stops the unit if the
average since the previous check is ≥ LIMIT% (default 50) of one core. It skips
the check when the PID has changed (the service restarted between checks).

| File | Installed to |
|---|---|
| `cpu-watchdog` | `/usr/local/sbin/cpu-watchdog` |
| `cpu-watchdog@.service` | `/etc/systemd/system/` (oneshot, limit 50%) |
| `cpu-watchdog@.timer` | `/etc/systemd/system/` (every 15 min) |
| `install.sh` | installs the above and enables `cpu-watchdog@pop-upgrade.timer` |

Install: `sudo ./install.sh`. To watch another service:
`sudo systemctl enable --now cpu-watchdog@<unit>.timer`.

Check that it runs, and whether it has stopped anything:

```
systemctl list-timers 'cpu-watchdog@*' --no-pager
journalctl -u 'cpu-watchdog@*' | grep stopping
```

Tested by setting `SYSTEMCTL="systemctl --user"` and `STATE_DIR=./state` and
running it against a `systemd-run --user` busy loop and an idle `sleep`. The
busy loop was stopped (`averaged 100% CPU over 6s`) and the idle unit stayed
active. Installed on `pop-os` 2026-09-23.

## Related cleanup, same session

- **Warp removed**: `apt purge warp-terminal`, plus deleting
  `/etc/apt/sources.list.d/warpdotdev.list` and
  `/etc/apt/trusted.gpg.d/warpdotdev.gpg`. The repo's signing key had expired
  (`EXPKEYSIG 31F4254AFE49E02E`), which broke every `apt update`, including the
  ones pop-upgrade runs. `~/.config/warp-terminal` and
  `~/.local/state/warp-terminal` were left in place.
- **`execsnoop-bpfcc` (root, long-running) is expected.** The System76
  Scheduler (`com.system76.Scheduler.service`) starts it to see new processes
  and assign them a priority. That is also why pop-upgrade runs at nice 12.
