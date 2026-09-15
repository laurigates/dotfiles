# A Word Starting With `=` Is a Command Lookup in Zsh

**Scope**: every zsh command, including one-liners run through the Bash tool
— the same scope as `zsh-colon-modifiers-after-variables.md`.

## The trap

With `EQUALS` set (the zsh default), an unquoted word that begins with `=` is
replaced by the path of the command named after it: `=ls` becomes `/bin/ls`.
When no such command exists, the expansion is a **fatal error that aborts the
rest of the command line**, not just that word, and `;` does not contain it:

```zsh
zsh -fc 'echo a; echo ======; echo b'
# a
# zsh:1: ===== not found        ← `echo b` never runs, exit 1
```

Observed 2026-09-15 (claude-plugins, session-end): `survey.sh …; echo ======;
distill-survey.sh …` printed the survey, then `(eval):1: ===== not found`, and
the second collector silently never ran. The error names the word minus its
leading `=`, which reads like a missing command rather than a separator.

## The fix

Quote the word (`echo '======'`), or use a separator that does not start with
`=` (`echo ---`). `setopt noequals` also works but changes the shell for
everything after it. Bash has no such expansion, so a bash-tested snippet
breaks only here.

## When it bites

- Section separators in chained diagnostics (`echo =====`, `print ==== x`).
- Arguments that start with `=`: `--flag =value`, `git log =main`, a jq or
  awk program passed unquoted.
- Mid-chain placement: everything after the bad word is lost, so the symptom
  is missing output from a later command, not an error at the one you wrote.

## Related

- `zsh-colon-modifiers-after-variables.md`, `zsh-special-variables-path.md` —
  the other always-on zsh traps; same family, different mechanism
- `tool-use-patterns.md` § *Results that lie* — missing output from a later
  command is a broken probe, not a clean answer
