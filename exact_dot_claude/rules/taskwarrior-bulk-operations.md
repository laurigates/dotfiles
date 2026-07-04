# Taskwarrior Bulk Operations

When triaging or closing many tasks in one pass (queue cleanup, PR sweep, project wrap-up), the obvious CLI shape — `for id in 1 2 3; do task $id done; done` — silently breaks in two ways. This rule documents the two foot-guns and the patterns that avoid them.

Companion to `taskwarrior-tracking.md` (which covers **when** to add tasks). This rule covers **how** to operate on tasks at scale.

## Foot-gun 1: numeric IDs renumber after every `task done`

Taskwarrior numeric IDs are a display index over **pending** tasks. The moment you complete one task, every higher ID shifts down by one. A loop like:

```sh
# WRONG — IDs shift mid-loop, you close the wrong tasks
for id in 35 36 37 38 39; do
  task "$id" done
done
```

closes task 35 correctly, then "36" now points at what was originally 37, and so on. After the first close you are targeting the wrong tasks.

**Fix: always use UUIDs for loops over multiple tasks.** UUIDs are immutable.

```sh
# Correct — UUIDs don't shift
UUIDS=$(task status:pending project:foo export | jq -r '.[] | .uuid')
for u in $UUIDS; do
  task "$u" done </dev/null    # (see foot-gun 2 below)
done
```

The same applies to `task <id> annotate`, `task <id> modify`, `task <id> delete` — any state-changing op iterated over a set must reference UUIDs.

### The loop is the obvious case — the gap is the subtle one

The renumbering hazard is **not** loop-specific. A numeric ID is a display index over the *current* pending set, so it is stale across **any** gap between reading it and acting on it — a later conversation turn, a new session, or just elapsed time during which *anything* (an agent in another session, a `task done` you ran for an unrelated task) mutated the pending set. The IDs shift even though you never ran a loop.

```sh
# WRONG — read IDs now, act on them later
# turn 1: `task export` shows promote-task = 169, cleanup-task = 167
# ...several turns later, an unrelated `task done` has shifted the set...
task 169 done          # 169 now points at a DIFFERENT task — closes the wrong one
```

This is exactly how a wrap-up session closed an unrelated note-taking task instead of the intended one: the numeric IDs were read from an early `export`, then used two turns later after the pending set had changed underneath them.

**Fix: resolve to the UUID at read time, the moment you know you'll act later.** Never carry a numeric ID across a turn, a tool-call gap, or a session boundary.

```sh
# Capture the immutable UUID up front, use it for every later op
PROMOTE=$(task _get 169.uuid)        # 169 is valid *right now*, at read time
CLEANUP=$(task _get 167.uuid)
# ...any number of turns / unrelated task closes later...
task "$PROMOTE" done </dev/null      # still the right task
task "$CLEANUP" annotate "..." </dev/null
```

If you only have a numeric ID and a gap has passed, **re-derive it** (re-run the `export`/`list` and re-match on description) before acting — do not trust the cached number.

### `_get` is a DOM accessor, not a filter — `task +LATEST _get uuid` returns empty

To capture the UUID of the task you just added, the obvious-looking
`task +LATEST _get uuid` **silently returns empty** (exit 0) and captures
nothing. `_get` takes a **DOM reference** of the form `<id>.<attribute>`
(`task _get 169.uuid`) — it does **not** accept a `<filter> _get <attribute>`
shape, so a tag filter like `+LATEST` resolves to nothing. The failure is
invisible: no error, exit 0, an empty UUID, and the next `task <empty> done`
no-ops or hits the wrong task. Verified on taskwarrior 3.4.2.

```sh
# Wrong — _get given a tag filter returns empty
task +LATEST _get uuid        # → '' (exit 0), captures nothing

# Right — the +LATEST-aware accessor, or a DOM ref, or export+jq
task +LATEST uuids                              # → <uuid> of the just-added task
task _get 169.uuid                              # DOM ref: <id>.<attribute>
task +LATEST export | jq -r '.[0].uuid'         # always exit-0, parallel-safe
```

| Intent | Wrong | Right |
|---|---|---|
| UUID of the just-added task | `task +LATEST _get uuid` | `task +LATEST uuids` |
| UUID of a known numeric id | `task <id> _get uuid` | `task _get <id>.uuid` |

## Foot-gun 2: `task done` consumes loop stdin

`task done` reads from stdin (for confirmation prompts and similar). In a shell `for` loop, the loop's input is *also* stdin. When `task done` runs inside the loop body, it eats subsequent iterations from stdin and the loop exits early — usually after one or two iterations — with no error.

Symptom: you set up a loop over 15 UUIDs, the script reports "processed 15" but only 1 task actually closed.

**Two fixes:**

```sh
# Fix A — redirect stdin per inner command
for u in $UUIDS; do
  task "$u" annotate "..." </dev/null
  task "$u" rc.confirmation=no done </dev/null
done

# Fix B — use xargs instead of a for loop (preferred for one-liners)
echo "$UUIDS" | xargs -I {} sh -c 'task rc.confirmation=no {} done'
```

`xargs -I {}` runs each command in its own subshell with no stdin link to the source — cleaner and harder to misuse.

## Always pass `rc.confirmation=no` for batch `task done`

Without it, taskwarrior may prompt "this task is blocked by N other tasks, complete anyway? (yes/no)" per task, hanging the loop. `rc.confirmation=no` makes batch closes deterministic.

## `task config` also needs `rc.confirmation=no` — or it silently no-ops

The confirmation hazard is not limited to `task done`. **`task config <name> <value>` prompts to confirm by default**, and in a non-interactive context (a script, an agent's Bash tool, a hook, `chezmoi`) the un-answered prompt makes the command **exit 0 without writing the value**. The config change silently does not persist — no error, exit status 0, looks like success.

The bite is worst when **declaring UDAs**. A setup script that runs:

```sh
# WRONG — exits 0 but the UDA is NOT written non-interactively
task config uda.ghid.type numeric
```

reports success, yet `task _udas` still lacks `ghid`. The next `task add foo ghid:1417` then treats `ghid:` as an unknown attribute and **appends the literal `ghid:1417` to the description** instead of setting the UDA — so every downstream `task ghid:1417 export` / reconcile query finds nothing. The failure is invisible until you notice the field landed in the description text.

```sh
# Right — rc.confirmation=no makes the write actually happen; </dev/null
# guards against any residual prompt eating the caller's stdin
task rc.confirmation=no config uda.ghid.type numeric </dev/null
task rc.confirmation=no config uda.ghid.label "GH Issue" </dev/null
```

Verify the write took effect rather than trusting the exit code:

```sh
task _udas | grep -qx ghid && echo "declared" || echo "MISSING — config did not persist"
```

The same applies to any scripted `task config` (urgency coefficients, report definitions, `data.location`): pass `rc.confirmation=no` and confirm the value landed. (Discovered 2026-06 building taskwarrior-plugin's `ensure-udas.sh`: the inline `task config` install blocks worked interactively — the agent answered the prompt — but silently no-op'd in a fresh non-interactive store.)

## Filter caveats when finding tasks

- `task project: status:pending list` (empty `project:` value as first filter) errors with `Unable to find report`. Use `task status:pending project: list` or sidestep the CLI filter by exporting and filtering with `jq`:

  ```sh
  task status:pending export | jq -r '.[] | select(.project == null) | .uuid'
  ```

- For tag-style markers that live in the **description text** (e.g. `+upstream-issue` as a literal substring, not a real tag), filter with `jq`'s `test()` and remember to escape the `+`:

  ```sh
  task status:pending export | jq -r '.[] | select(.description | test("\\+upstream-issue")) | .uuid'
  ```

- Real taskwarrior tags (set via `+tagname` at task creation, listed in `.tags`) should be filtered through the CLI: `task +upstream-issue status:pending export`.

## Why annotate before `done`, not after

Once a task is `completed`, its `id` becomes 0 and `task <id>` no longer addresses it (you must use the UUID). Adding annotations *before* closing keeps the UUID-or-ID workflow uniform and ensures the annotation lands in the pending-state task that still shows in `task <id> info`.

## Rationale

The default shape of "I'll just loop and close these" wastes 5–30 minutes the first time someone hits it: the loop runs, the count reports success, but the tasks are still pending and now scattered across unexpected IDs. The fix is mechanical — UUIDs + stdin discipline — but invisible until you've been burned. Codifying it removes the burn.
