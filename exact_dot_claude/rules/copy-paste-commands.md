# Copy-Paste-Safe Shell Commands

The Claude Code TUI renders every line of assistant output with a
two-column left margin. When the user selects a multi-line shell
command from the transcript and pastes it into a real shell, that
margin — plus any backslash-continuation indent added for readability —
travels with the paste. The result fails to run cleanly, and the user
has to hand-edit indentation across several lines before the shell
accepts it.

Emit commands so they survive a naive copy-paste.

## Default: single-line commands

A single-line command is paste-safe regardless of the TUI margin —
the leading whitespace at the *start* of the line is the only artifact,
and `bash`/`zsh` ignore leading whitespace on interactive input. No
mid-command line breaks means no continuation indentation to clean up.

```
# Do — single line, paste-safe
WINEPREFIX="$HOME/.local/share/skullcaps-native/wineprefix" ~/wine-engines/wine-10.0/wswine.bundle/bin/wineserver -k
```

```
# Don't — backslash continuation gets a two-space margin from the TUI;
# pasted command fails on the continuation indent
  WINEPREFIX="$HOME/.local/share/skullcaps-native/wineprefix" \
    ~/wine-engines/wine-10.0/wswine.bundle/bin/wineserver -k
```

The "Don't" form looks tidy in the transcript but is broken on paste:
the second line arrives with leading spaces *inside* the command, which
the shell does not strip.

## Chaining

Join commands inline — never with backslash-newline.

| Intent | Joiner |
|---|---|
| Fail-fast: stop on first non-zero exit | ` && ` |
| Run regardless: continue even if a step fails | ` ; ` |
| Pipe stdout of A into B | ` \| ` |

```
# Do
cd /tmp/build && cmake --build . && ./run-tests

# Do
rm -f /tmp/lock ; restart-service

# Don't — line continuation again
cd /tmp/build && \
  cmake --build . && \
  ./run-tests
```

## No leading whitespace inside the fence

Code fences containing copy-paste content should start each line
flush-left (no indentation beyond what the command itself requires).
The TUI already adds its own left margin; any extra indentation inside
the fence compounds the problem.

## When the command genuinely must span lines

Rare cases — a heredoc, a multi-line script, a deeply nested
`jq`/`awk` program. Do **not** paste these as inline commands. Save
them to a file and run the file:

```
# Do — write to a file, then run it
cat > /tmp/seed.sql <<'SQL'
INSERT INTO users (name) VALUES ('alice');
INSERT INTO users (name) VALUES ('bob');
SQL
psql -f /tmp/seed.sql
```

The user pastes each *single-line* command separately. The heredoc
body lives in a file, not in the transcript.

## `! <command>` for commands the user must run themselves

When the user genuinely needs to run something in their own shell —
interactive auth (`gcloud auth login`), graphics-protocol commands
(`kitty +kitten icat`), anything that needs their TTY — tell them to
prefix the command with `!` in the Claude Code prompt. The `!` prefix
runs the command in their actual shell and the output lands in the
conversation. Format it on a single line, same rules as above:

```
! gcloud auth login
```

```
! kitty +kitten icat /tmp/diagram.png
```

## Rationale

The failure mode is silent: the user pastes, runs, and either nothing
happens or the wrong thing happens. The 30-second cleanup ("which line
do I un-indent?") compounds across a session. Single-line commands are
the default that removes the foot-gun — they paste cleanly into any
shell, with or without the TUI margin, on any platform.
