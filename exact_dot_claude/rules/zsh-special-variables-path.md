# `path` Is Not a Free Variable Name in Zsh

**Scope**: every zsh command, including one-liners run through the Bash
tool. Unlike `zsh-pattern-expansion-extended-glob.md` (which is scoped to
`.zsh` / `zshrc` files), this bites in ordinary interactive commands.

## The trap

Zsh **ties `path` to `PATH`**: `path` is the array view, `PATH` the
scalar view, and writing either rewrites the other. Assigning a string to
`path` therefore destroys the search path for the rest of the shell.

The usual way in is a loop variable chosen for readability:

```zsh
# Wrong — `path` is special; PATH is destroyed on the FIRST iteration
while IFS=$'\t' read -r key title labels path; do
  gh issue create --title "$title" --body-file "$path" ...
done < list.tsv
```

Observed 2026-09-02 (silverbucket-helper, filing eight issues): every
iteration printed `command not found: tail`, and **nothing was created**
— `gh` was already unreachable by the time the body ran.

Zsh's tied variables are a small set, and the rest are just as ordinary
looking: `path`, `cdpath`, `fpath`, `manpath`, `fignore`, `mailpath`,
`module_path`, `prompt`, `psvar`, `status`, `argv`. `path` and `fpath`
are the two a script is most likely to reach for by accident.

## The fix

Pick a name that is not tied. Any of `bodyfile`, `file`, `p`, `target`
works; the rename is the whole fix.

```zsh
# Right
while IFS=$'\t' read -r key title labels bodyfile; do
  gh issue create --title "$title" --body-file "$bodyfile" ...
done < list.tsv
```

`typeset` does not rescue you — `local path` inside a function still
shadows the tied parameter and still breaks command lookup for that
function's body.

## Check whether anything actually ran

The failure is loud but **misattributed**: zsh reports the missing
command, not the cause, so the obvious next move is to fix the "missing"
tool. Before retrying a loop that had side effects, establish whether the
side effects happened — a partially-completed run retried from the top
creates duplicates.

```zsh
gh issue list --state open --limit 30 --json number,createdAt   # did any land?
```

In the case above the answer was none, because `PATH` died on iteration
one before `gh` was reached. Had it died later, some issues would exist
and a blind retry would have double-filed them.

## When it bites

- `while read` loops over a TSV/CSV whose columns include a path.
- `for path in ...` over filenames — the most natural name for the thing.
- Any function taking a filesystem path as a positional it names `path`.

## Related

- `zsh-pattern-expansion-extended-glob.md` — the other zsh-vs-POSIX
  assumption that fails silently; same family, different mechanism.
- `tool-use-patterns.md` § *Results that lie* — the general law that a
  command's failure message names its symptom, not its cause.
