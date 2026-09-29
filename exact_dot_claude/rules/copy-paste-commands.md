# Copy-Paste-Safe Shell Commands

The Claude Code TUI renders assistant output with a two-column left margin, and
that margin — plus any continuation indent — travels with a pasted multi-line
command, which then fails in a real shell. Emit commands that survive a naive
copy-paste:

- **Default to single-line commands.** Leading whitespace at the start of a line
  is harmless; whitespace inside a backslash continuation is not.
- **Chain inline, never with backslash-newline:** ` && ` (stop on first
  failure), ` ; ` (continue regardless), ` | ` (pipe).
- **No indentation inside the code fence** beyond what the command requires.
- **Genuinely multi-line content** (heredoc body, long script, nested
  `jq`/`awk`): write it to a file with one command, run the file with another.
- **Commands the user must run in their own TTY** (interactive auth,
  `kitty +kitten icat`): hand them over single-line with the `!` prefix, e.g.
  `! gcloud auth login`.

```
# Don't — the continuation line arrives with leading spaces inside the command
  WINEPREFIX="$HOME/.wine" \
    wineserver -k

# Do
WINEPREFIX="$HOME/.wine" wineserver -k
```
