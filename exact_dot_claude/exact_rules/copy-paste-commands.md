---
reviewed: 2026-11-04
---

# Readable, Copy-Paste-Safe Shell Commands

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
- **Commands the user must run themselves** (interactive auth): hand them over
  single-line with the `!` prefix, e.g. `! gcloud auth login`. The `!` shell
  has no `/dev/tty`, so anything that opens the TTY directly (`kitty +kitten
  icat`) fails there too; show images through the `kitty-show-image` skill.
- **A prompt for hidden input gets nothing under `!`.** With no TTY, a command
  that would prompt for a value reads an empty stdin instead. It may succeed
  silently with an empty value: `! gh secret set NAME -R <repo>` with no
  `--body` stored an **empty** secret, and nothing failed until the workflow
  that read it did (2026-11-04). Hand such a command over for Lauri's own
  terminal, or give it the value explicitly: `--body-file <path>`, or stdin
  from a command that reads the secret store.
- **Several commands Lauri must run in sequence go in one `!` line**, chained
  with ` && `, never as separate `!` commands. Each `!` result reaches Claude
  on its own, and Claude starts answering the first before the rest have run.
  Keep the chain on one line. A `&& \` continuation hits the margin problem
  above.
- **A command that reads the clipboard runs once, in Lauri's own terminal.**
  When handing over `pbpaste | <cmd>` for a secret, say to run it there and
  not to paste the result back under `!`: a pasted block that starts with the
  command runs it again, and by then the clipboard holds the copied terminal
  text. `pbpaste | gh secret set PORTFOLIO_ACTIONS_READ` pasted back with its
  output replaced the token with that text, and the workflow reading it failed
  20 s later (2026-11-10). Ask for a one-word confirmation, then check the
  result with a call that does not read the clipboard.

```
# Don't — the continuation line arrives with leading spaces inside the command
  WINEPREFIX="$HOME/.wine" \
    wineserver -k

# Do
WINEPREFIX="$HOME/.wine" wineserver -k
```

## Commands Claude Runs — One Action per Call

The same reader reads the Bash tool calls Claude makes. Each call must say what
it does in one read:

- **One action per call**, with a plain `description` naming that action. Do
  not bundle file creation, a probe run and result printing into one command.
- **A one-liner is a single pipeline.** Multi-step, looping, or remote (`ssh`)
  work goes in a commented script written with the Write tool, with a
  `#!/usr/bin/env bash` shebang, and run by one command.
- zsh is the shell for the Bash tool and on remote hosts. A bash script runs
  outside it, so the expansions in `tools-plugin:zsh-gotchas` and zsh's
  `nomatch` abort do not apply inside it.

> Observed 2026-10-28: Lauri rejected a Bash call that created five test files,
> ran a heredoc into a Python probe and printed the results in one command —
> "that command was too complex to understand or even read". It was redone as
> one action per call plus a commented script run by one command. Later in the
> session compound one-liners hit zsh four times (`set -- $spec` and an unquoted
> `$cmd` not word-splitting, a bare `=====` taken as a command lookup, a glob
> with no matches aborting an `ls` under `nomatch`), `rg -rn` read `-r` as
> `--replace`, and a trailing `&` backgrounded a whole `&&` chain over ssh.
> Writing the multi-step and remote work as bash scripts avoided all of them.
