---
reviewed: 2026-11-12
---

# Zsh Gotchas — Expansions That Rewrite the Command You Wrote

Promoted to a skill: invoke `tools-plugin:zsh-gotchas` when a zsh command —
including any one-liner run through the Bash tool — produces a result that does
not match what you wrote. The symptoms that should send you there:

| Symptom that should send you there | Mechanism |
|---|---|
| A URL or path built with `$var:` hits the wrong endpoint; a fast, empty 404 | `$VAR:x` is a history modifier (`:h`, `:t`, `:g`, …), not a literal colon |
| A later command in a `;` chain produced no output | an unquoted word starting with `=` is a command lookup, and a failed one aborts the whole line |
| `$2` is empty after `set -- $spec`; the tool prints its usage text | zsh does not word-split an unquoted parameter — use `${=var}` or named `read` vars |
| `command not found` for a tool that is installed | `path` is tied to `PATH`; using it as a loop variable destroys command lookup |
| A function prints hundreds of `NAME=value` lines before its real output | `local $names` with `names` empty is a bare `local`, which lists every parameter in scope, exported tokens included |

Three of the first four fail **silently or misattributed** — the command exits
and reports something that reads as a real answer about the world — so the
symptom column above is the trigger, not an error message naming the cause. Bash
has none of those four behaviours, which is why a snippet lifted from a
bash-tested doc breaks only here. The fifth is shared with bash for `typeset`,
`declare` and `export`; only the `local` form is zsh's own.

Writing the fifth is blocked at the source: hooks-plugin's
`bare-declaration-guard.sh` rejects an Edit or Write that adds such a line to a
shell file.

Sibling: `zsh-pattern-expansion-extended-glob.md` — zsh-vs-POSIX pattern
assumptions, scoped to `.zsh` / `zshrc` files rather than to every command.
