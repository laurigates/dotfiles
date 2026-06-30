# Quitting the OrbStack GUI Orphans the Helper VM — Use `orb stop`

Closing the OrbStack **app** does not stop the OrbStack **VM**. The
`OrbStack Helper` process *is* the Linux VM, and it runs independently of
the GUI front-end. Quitting the window — or `osascript -e 'quit app
"OrbStack"'`, or even File→Quit — closes the UI and leaves the helper
running, reparented to launchd. It keeps consuming ~40–50% CPU and ~20%
RAM with **no visible app**, so a machine that feels hot "even though I
closed everything" is often this orphaned VM.

The failure is invisible: Activity Monitor shows no OrbStack *app*, yet
`OrbStack Helper` sits near the top of the CPU list. Quitting the GUI
again does nothing — there's no GUI left to quit.

## The tell

After "closing" OrbStack, the helper's parent PID is **1** (launchd) —
it was reparented when the GUI exited, but never told to stop:

```
ps -Ao pid,ppid,pcpu,comm | grep -i '[o]rb'
# 1531  1  47.1  /Applications/OrbStack.app/.../OrbStack Helper
#       ^-- PPID 1 = orphaned to launchd, still running
```

A running `OrbStack Helper` with `PPID 1` after the app is "closed" is
the signature.

## The fix

Stop the VM through the CLI, which actually shuts the Linux VM down
(clean flush, not a hard kill):

```
orb stop
```

The binary is `/opt/homebrew/bin/orb` (Homebrew install) — it may not be
on a non-interactive shell's PATH, so use the absolute path from scripts:
`/opt/homebrew/bin/orb stop`. Verify it worked:

```
ps -Aceo pid,comm -r | grep -i '[o]rb' || echo "OrbStack stopped"
```

`orb start` brings the VM back, so stopping is fully reversible — no
reason to hesitate. Prefer `orb stop` over `kill <pid>`: the kill skips
the VM's own shutdown and can leave container/volume state mid-write.

## When this bites

- Triaging a hot/loud Mac: OrbStack is a common top CPU+RAM consumer that
  survives "closing the app", so it reads as a phantom load.
- Any script or agent that tries to free resources by quitting the GUI
  (`osascript -e 'quit app "OrbStack"'`) — it won't stop the VM; call
  `orb stop` instead.

## Relationship to sibling rules

- `disk-full-recovery.md` — OrbStack's VM disk image is also a frequent
  space hog when the VM is left running; stopping it is the first step
  before reclaiming.

## Rationale

The GUI and the VM are separate processes, but the app's framing ("quit
OrbStack") implies quitting stops everything — it doesn't. One `orb stop`
halts the actual resource consumer; checking `PPID 1` on the helper is
the five-second diagnosis that distinguishes "orphaned VM" from "OrbStack
genuinely gone".
