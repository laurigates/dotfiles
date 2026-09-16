# Zsh Does Not Word-Split an Unquoted Parameter

**Scope**: every zsh command, including one-liners run through the Bash tool —
the same scope as `zsh-special-variables-path.md`.

## The trap

Bash splits an unquoted `$var` on `IFS`; zsh does not, because `SH_WORD_SPLIT`
is off by default. The whole string stays one word, so `$1` is everything and
`$2` is empty:

```zsh
# Wrong — $2 is empty, so gh runs without a PR number
for spec in "ForumViriumHelsinki/infrastructure 2379" "ForumViriumHelsinki/.github 127"; do
  set -- $spec
  gh pr view "$2" -R "$1" --json state
done
```

Observed 2026-09-16 (verifying three PRs after a merge): the loop printed gh's
usage text three times — *"argument required when using the --repo flag"* — and
verified nothing. The message names a **flag**, so it reads as a wrong
invocation rather than an empty variable, and the obvious next move is to
rewrite the `gh` call that was already correct.

## The fix

Force splitting with `${=var}`, or read into named variables:

```zsh
for spec in "ForumViriumHelsinki/infrastructure 2379"; do read -r repo num <<< "$spec"; gh pr view "$num" -R "$repo" --json state; done
```

Named variables are the better habit: they survive a copy into a bash script,
and they say what each field is.

## When it bites

- `set -- $line` / `set -- $spec` over a list of space-separated records — the
  natural way to unpack "repo number" or "host port" pairs.
- `cmd $args` where `args` holds several flags. Zsh passes them as **one**
  argument; the tool reports an unknown option containing spaces.
- Splitting on something other than whitespace: `${(s:,:)csv}` in zsh, not
  `IFS=, read`.

## The failure looks like a clean result, not an error

Both halves of this session's evidence were silent. The `gh` loop printed usage
text, and a malformed taskwarrior query minutes later (`task export
status:pending` — taskwarrior wants the filter **before** the command) returned
three empty lists that read exactly like an empty queue. A control re-run with
the correct order returned 457 tasks. Control-test any negative that gates an
action; see `tool-use-patterns.md` § *Results that lie*.

## Related

- `zsh-special-variables-path.md` — `path` is tied to `PATH`; same family,
  different mechanism
- `zsh-colon-modifiers-after-variables.md` — `$var:x` is a history modifier
- `zsh-pattern-expansion-extended-glob.md` — zsh-vs-POSIX assumptions that fail
  silently
