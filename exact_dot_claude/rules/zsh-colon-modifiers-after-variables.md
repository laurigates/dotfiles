# `$VAR:word` Is a Modifier in Zsh, Not a Colon After a Variable

**Scope**: every zsh command, including one-liners run through the Bash tool
— the same scope as `zsh-special-variables-path.md`.

## The trap

Zsh applies history-style **modifiers** directly to a bare parameter
expansion: `$f:h` (dirname), `$f:t` (basename), `$f:r`, `$f:e`, `$f:s/a/b/`,
`$f:g…`. So a URL that puts a variable straight before a colon is not the URL
you wrote:

```zsh
# Wrong — `:g` is read as the start of a global-substitution modifier
curl "https://…/v1beta/models/$MODEL:generateContent"
```

Observed 2026-09-05 (robocar-unified, probing a replacement Gemini model):
three requests came back `HTTP 404` in **60 ms with an empty body**, and were
nearly reported as "the new model does not support generateContent". The
empty body and the sub-100 ms turnaround were the tell — a real API 404 carries
a JSON error and takes a round trip. The same request with braces returned 200.

## The fix

Brace the expansion. Braces end the parameter name, so the colon is literal:

```zsh
curl "https://…/v1beta/models/${MODEL}:generateContent"
```

Double quotes do **not** protect you — modifiers apply inside them. Bash has no
such modifier syntax, which is why a snippet lifted from a bash-tested doc
breaks only here.

## When it bites

- Gemini-style `model:method` REST paths, `host:port`, `user:group`,
  `file:line`, `scp`/`rsync` `host:path` targets — any `$var:` with a letter
  after the colon.
- A modifier letter that zsh does not recognise errors loudly
  (`unrecognized modifier`); the recognised ones (`g`, `h`, `t`, `r`, `e`,
  `s`, `a`, `A`, `l`, `u`, `q`, `Q`, `x`, `c`, `P`) fail silently by
  rewriting the string.

## Related

- `zsh-special-variables-path.md` — the other bare-variable trap (`path` is
  tied to `PATH`); same family, different mechanism
- `zsh-pattern-expansion-extended-glob.md` — zsh-vs-POSIX assumptions that
  fail silently
- `tool-use-patterns.md` § *Results that lie* — a fast, empty negative is a
  broken probe, not a clean answer; control-test it against a known-good call
