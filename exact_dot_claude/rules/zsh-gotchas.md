# Zsh Gotchas — Expansions That Rewrite the Command You Wrote

Promoted to a skill: invoke `tools-plugin:zsh-gotchas` when a zsh command —
including any one-liner run through the Bash tool — produces a result that does
not match what you wrote. It carries all four mechanisms in full, with the
observed break and the fix for each:

| Symptom that should send you there | Mechanism |
|---|---|
| A URL or path built with `$var:` hits the wrong endpoint; a fast, empty 404 | `$VAR:x` is a history modifier (`:h`, `:t`, `:g`, …), not a literal colon |
| A later command in a `;` chain produced no output | an unquoted word starting with `=` is a command lookup, and a failed one aborts the whole line |
| `$2` is empty after `set -- $spec`; the tool prints its usage text | zsh does not word-split an unquoted parameter — use `${=var}` or named `read` vars |
| `command not found` for a tool that is installed | `path` is tied to `PATH`; using it as a loop variable destroys command lookup |

Three of the four fail **silently or misattributed** — the command exits and
reports something that reads as a real answer about the world — so the symptom
column above is the trigger, not an error message naming the cause. Bash has none
of these behaviours, which is why a snippet lifted from a bash-tested doc breaks
only here.

Sibling: `zsh-pattern-expansion-extended-glob.md` — zsh-vs-POSIX pattern
assumptions, scoped to `.zsh` / `zshrc` files rather than to every command.
