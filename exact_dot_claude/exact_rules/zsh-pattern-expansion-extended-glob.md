---
paths:
  - "**/*.zsh"
  - "**/*zshrc*"
  - "**/*zshenv*"
---

# Zsh Pattern Expansion Under `extended_glob`

**Scope**: applies when writing or editing zsh parameter expansions that
contain `#` in a pattern — in `dot_zshrc.tmpl` (chezmoi source), `~/.zshrc`
(target), or any `.zsh` file sourced into an interactive shell where
`extended_glob` may be set. Skip for POSIX `sh`/`bash` scripts.

## The trap

In zsh with `setopt extended_glob` (commonly enabled by frameworks,
plugins, or the user's own config), `#` is the **pattern repeat operator**
— `x#` means "zero or more `x`", like regex `x*`. This changes how `#` is
read inside *every* glob and parameter-expansion pattern, including the
`${var#pat}`, `${var##pat}`, `${var%pat}`, `${var%%pat}` family.

So an expansion that looks like it strips up to a literal `#`:

```zsh
issue_num="${${selection##*#}%% *}"   # intent: grab leading "#1157" → "1157"
```

aborts at parse time with:

```
bad pattern: *#
```

because `*#` is parsed as "repeat the `*`" — an invalid pattern. The error
fires regardless of the value of `$selection`; it's a property of the
pattern, not the data. It will not reproduce in a plain `zsh -c '...'`
test unless you `setopt extended_glob` first, which is why it can look
data-dependent when it isn't.

## Two distinct bugs, one symptom

A literal `#` in a parameter-expansion pattern hides two problems:

1. **`bad pattern` under `extended_glob`** — the `#` is read as the repeat
   operator. Fix: escape it as `\#`.
2. **Greedy strip picks the wrong token** — even with the `#` escaped,
   `##*\#` removes the *longest* prefix ending in `#`. If the data
   contains another `#` later (e.g. a GitHub issue title
   `Investigate hydration error #418`), the strip overshoots and extracts
   `418` instead of the leading `#1157`. Fix: strip only what you mean to.

The real-world break that motivated this rule: an `ghi` fzf wrapper parsed
`#1157  type:bug  …  Investigate hydration error #418 …` with
`${selection##*#}` and silently targeted issue **418** — until
`extended_glob` turned the same line into a `bad pattern` abort.

## The fix

Escape every literal `#` in a pattern, and prefer the **shortest** strip
that captures intent. When the token you want is the first column, strip
the single leading `#` and cut at the first space:

```zsh
# Wrong — bad pattern under extended_glob, and greedy on '#' in later columns
issue_num="${${selection##*#}%% *}"

# Right — escaped '#', single-char leading strip, first-token cut
issue_num="${${selection#\#}%% *}"
```

| Intent | Wrong | Right |
|---|---|---|
| Strip one leading `#` | `${v#*#}` | `${v#\#}` |
| Strip up to first literal `#` | `${v#*#}` | `${v#*\#}` |
| Strip up to last literal `#` | `${v##*#}` | `${v##*\#}` |
| Match anything ending in `#` | `*#` | `*\#` |

Other extended-glob metacharacters need the same care inside patterns:
`#`, `^`, and `~` are all special only under `extended_glob`. `[` and `(`
are special regardless. The `${1%%\[*}` form already used in the same gh
wrappers is correct precisely because the `[` is escaped.

## Verify

Reproduce the failure (and confirm the fix) by forcing the option on,
since the interactive shell's state isn't the default:

```zsh
zsh -c 'setopt extended_glob; selection="#1157  x #418"; issue_num="${${selection#\#}%% *}"; print -r -- "$issue_num"'
```

Prints `1157`. Swapping in the old `${selection##*#}` prints
`zsh:1: bad pattern: *#`.

## When it bites

- fzf / `gh` / `column -t` wrappers that re-parse a rendered display line
  to recover an ID, where the display can contain `#` (issue/PR numbers,
  hex colors, anchors, comment markers).
- Any expansion pattern authored under a non-extended-glob mental model
  (POSIX, bash) then sourced into an interactive zsh that has the option
  set by a plugin.
- Tests that pass under `zsh -c` (no `extended_glob`) but fail live.
