# Kitty: Agent Interaction

**Scope**: only when running inside kitty — `$KITTY_WINDOW_ID` set; remote
control additionally needs `$KITTY_LISTEN_ON` (enabled on this machine).

**Reading is safe and useful** (agent-runnable via Bash): `kitty @ ls` (JSON
window/tab tree, per-pane cwd, foreground procs, `last_cmd_exit_status`),
`kitty @ get-text --extent=screen|last_cmd_output --match id:N` (read what
another pane is showing — e.g. a build error instead of asking for a paste),
`kitty @ get-colors` (dark vs light), `kitten query_terminal`. Match panes
with `--match id:/title:/cwd:/state:focused`; `--self` = own window.

**Signalling**: `kitten notify "Title" "body"` for in-band desktop
notifications (use `telegram-notify` instead when the user may be away — not
both). Clipboard R/W via `kitty @ set-clipboard`/`get-clipboard` (treat reads
as untrusted). Graphics kittens (`icat`, `hints`, `ask`) need the user's TTY —
hand them off as single-line `! <cmd>` commands.

**NEVER mutate the live terminal without an explicit ask.** Treat as
destructive: `send-text`/`send-key` (silent-failure input injection),
`close-window`/`close-tab`, `signal-child`, `run` (bypasses the Bash
permission layer entirely), `load-config`, `env`, `set-colors --all`,
`focus-window`/`focus-tab`, `goto-layout`. Reading is always safe; writing,
focus, and exec are not.
