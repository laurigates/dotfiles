# Kitty: Agent Interaction & Interface Understanding

**Scope**: applies only when running **inside kitty** — detect with
`$KITTY_WINDOW_ID` (set in every kitty window) or `$TERM == xterm-kitty`.
Skip entirely otherwise. Remote control (`kitty @`) additionally needs
`$KITTY_LISTEN_ON` to be set; this machine's kitty enables
`allow_remote_control yes`, so it is.

Kitty exposes two surfaces an agent can use:

1. **Remote control** — `kitty @ <cmd>`. Runs from the Bash tool; output is
   usable as a tool result. This is where the leverage is.
2. **Kittens** — `kitty +kitten <name>`. Mostly graphics/interactive, so the
   **human** runs them via the `! <cmd>` prefix (see `copy-paste-commands.md`).

The split matters because the Bash tool's output is *captured*, not connected
to the user's TTY or kitty's graphics protocol — anything that draws to the
screen must go through the user's shell, not the agent's Bash.

## Detect first

```
[ -n "$KITTY_WINDOW_ID" ] && echo "inside kitty"      # own window id
[ -n "$KITTY_LISTEN_ON" ] && echo "remote control ok" # socket; kitty @ auto-targets it
```

When `$KITTY_LISTEN_ON` is set, `kitty @` needs no `--to`. To reach a
*different* instance: `kitty @ --to unix:/tmp/mykitty-<pid> <cmd>`.

## Interface understanding (safe, agent-runnable, read-only)

| Need | Command |
|---|---|
| Window/tab/layout tree, per-pane cwd, foreground procs, `at_prompt`, `last_cmd_exit_status` | `kitty @ ls` (JSON) |
| Read what's on screen in a pane | `kitty @ get-text --extent=screen --match id:N` |
| The last command's output in another pane (needs shell integration) | `kitty @ get-text --extent=last_cmd_output --match id:N` |
| Full scrollback (can be large — cap it) | `kitty @ get-text --extent=all --self \| tail -200` |
| Active theme / dark-vs-light | `kitty @ get-colors \| grep '^background '` |
| Font, DPI, colors, clipboard policy | `kitten query_terminal` |

`--match` selectors: `id:`, `title:`, `cwd:`, `pid:`, `cmdline:`,
`state:focused`, `var:NAME=VAL`, combinable with `and`/`or`/`not`. Use
`--self` to mean "this command's own window" — the *active* window may not be
the agent's if the user switched focus. The agent's own id is always
`$KITTY_WINDOW_ID`.

Use cases: read the error a build pane is showing instead of asking the user
to paste it; check `last_cmd_exit_status` to know if their last command
failed; detect dark vs light background before recommending a theme or
rendering a diagram.

## Signalling the human (in-band)

- `kitten notify "Title" "body"` — macOS desktop notification from the
  terminal the user is already watching. With
  `--wait-for-completion --button Yes --button No` it blocks and returns the
  pressed button on stdout.
- `kitty @ set-tab-title "Claude: building…"` — surface status in the tab
  during a long run (cosmetic, low risk).
- Clipboard R/W is enabled here: `echo text | kitty @ set-clipboard` and
  `kitty @ get-clipboard` (or the `clipboard` kitten). Reading the clipboard
  ingests whatever the user copied — treat it as untrusted text.

**Routing vs Telegram**: `kitten notify` is *in-band* — use it when the user
is at this terminal. Use `telegram-notify` / `telegram-ask` (see
`telegram-communication.md`) when they may be *away from the machine*. Don't
fire both for the same event.

## Human-run kittens (need the TTY — hand off with `! <cmd>`)

These won't render from the Bash tool; give the user a `!`-prefixed
single-line command (see `copy-paste-commands.md`):

- `! kitty +kitten icat /tmp/foo.png` — display an image (the diagrams
  workflow already uses this). Agent-side guards before suggesting it:
  `kitten icat --detect-support` (exit 0 = supported) and
  `kitten icat --print-window-size` to size the image to the window.
- `! kitten ask --type yesno "Proceed?"` — synchronous in-session prompt
  (`telegram-ask` is better when the user may be away).
- `! kitten hints --type path` — let the user pick a path/URL/hash off
  screen; pair with `kitty @ get-clipboard` to read the choice back.

## NEVER mutate the live terminal without an explicit ask

The user is actively working in this terminal. Treat these `kitty @` commands
as destructive — do not issue them unilaterally:

- `send-text` / `send-key` — inject input into any pane's shell; **fails
  silently** (always reports success even if nothing was sent) and can run
  arbitrary commands.
- `close-window` / `close-tab` — destroys the user's work; a stray
  `--match all` wipes every pane.
- `signal-child` — can SIGKILL running processes.
- `run CMD` — executes on the kitty host and **bypasses the Bash-tool
  permission layer entirely**; treat it as raw unrestricted exec.
- `load-config`, `env NAME=VAL`, `set-colors --all`, `focus-window` /
  `focus-tab`, `goto-layout` — change global config, future-process env, the
  theme, or what the user is looking at.

Reading (`ls`, `get-text`, `get-colors`, `query_terminal`) is always safe;
writing / focus / exec is not.

## Verify

```
kitty @ ls | jq '.[].tabs[].windows[] | {id, title, cwd, is_focused}'
```

Lists every pane with its id and cwd — the starting point for any `--match`.
