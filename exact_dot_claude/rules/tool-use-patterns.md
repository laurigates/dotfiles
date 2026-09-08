# Tool Use Patterns

Durable patterns distilled from weekly friction-learner reports. The
loud `bash-antipatterns` / `branch-protection` / `agent-coworker-detection`
hooks already enforce most of W16's findings (git `&&` chains, `find`
vs Glob, `cat`/`head`/`tail`, sleep-chains, etc.); the patterns below
are the failure modes those hooks don't catch.

## Read tool

### Verify the path before calling Read

Read on a missing path is the dominant Read-side failure. The cause is
almost always an **assumed cwd**: the session's working directory moved
(worktree switch, prior `cd`, agent thread reset) and the cached path
no longer resolves.

```
# Wrong — three Reads against guessed paths
Read("/abs/a"); Read("/abs/b"); Read("/abs/c")

# Correct — one Glob tells you which exist
Glob(pattern="/abs/*")
```

**Agent threads always reset cwd between Bash calls.** Always pass
absolute paths from an agent prompt; never assume the cwd is preserved.

### Read is for files, not directories

`Read` on a directory errors with `EISDIR: illegal operation on a
directory`. The error message doesn't suggest the alternative.

```
# Wrong
Read(file_path="/abs/path/to/dir")     # → EISDIR

# Correct
Glob(pattern="/abs/path/to/dir/**/*.md")
Bash("ls -1 /abs/path/to/dir")
```

### Read refuses files >25 000 tokens

```
File content (164 836 tokens) exceeds maximum allowed tokens (25 000).
```

Common offenders: vendored JSON dumps, generated schemas, lockfiles,
transcripts, large generated docs. **Locate the section with Grep first,
then page Read with `offset`/`limit`.**

```
Grep(pattern="needle", path="/abs/path", output_mode="content", -n=true)
Read(file_path="/abs/path", offset=420, limit=80)
```

## Edit / Write tool

### Read in the current session before Edit / Write

The harness tracks file-read state **per session**. Reading the file in
a previous Claude Code session does not satisfy the requirement. Error
signature:

> File has not been read yet. Read it first before writing to it.

At the start of an editing turn, batch-Read every file you intend to
touch. Then do the Edits. Do not interleave a Read-immediately-before-
Edit while having already batched Edits for other files.

### Re-Read after a formatter, hook, or coworker may have run

Distinct from "Edit before Read." The file *was* read this session,
but a formatter (`prettier`, `stylua`, `ruff format`), pre-commit hook,
build watcher, or concurrent coworker agent rewrote it between your
`Read` and your `Edit`. Error signature:

> File has been modified since read, either by the user or by a linter.

Re-trigger triggers:

| After this happens… | Re-Read before next Edit |
|---|---|
| `pre-commit run` | All staged files |
| Format command (`prettier --write`, `stylua`, `ruff format`) | Files in scope |
| `git commit` (commit hooks may rewrite) | Files just committed |
| Coworker agent detected | All in-flight files |
| A long background Bash ran while you were editing | The files it wrote |

Do not retry the Edit blindly — issue a fresh Read first, then re-craft
the Edit against the new line numbers.

### Edit surgically; don't rewrite the file

Prefer `Edit` with the smallest unique `old_string` over `Write`-ing the
whole file. A rewrite regenerates untouched lines from memory, so content
silently drifts and the diff is unreviewable. `Write` is for new files.

Programmatic rewrites count too: a `json.load` → `json.dumps` round-trip drifts
no values and still reformats untouched siblings — rewriting one `.mcp.json`
entry collapsed inline `args` across six unrelated servers, nearly shipping
that churn in ten PRs. Splice the target span in the raw text instead.

### Find references with the sharpest instrument

`Edit` refuses on a file unread this session, so "read it first" is already a
harness invariant — adding it as a rule buys nothing. The **uncovered** half is
checking what *else* depends on what you're changing, and the reflex there is
`grep`, which cannot tell a call from a comment, a definition from a mention,
or `foo()` from `"foo"` in a string. Measured across 282 local sessions:
~2,400 code-symbol searches went through `grep`/`rg`, against **6** `ast-grep`
calls and **6** `LSP` calls.

Ladder, sharpest first. Falling back down it is normal; starting at the bottom
for a code symbol is the miss.

| Reach for | When |
|---|---|
| `LSP` — `findReferences`, `incomingCalls`, `goToDefinition` | A language server is running for that filetype. Exact: no comment/string hits, and it follows imports and re-exports that no text pattern can. |
| `ast-grep -p '$FN($$$ARGS)'` | No LSP, or the target is a *shape* rather than a name — a call with a given arity, a decorator, an un-awaited async call. Cross-language, bash included; see `code-quality-plugin:ast-grep-search`. |
| `rg` | Non-code: markdown rules, chezmoi templates, config keys, justfile recipes, workflow YAML. The right tool there, not a fallback — most of a dotfiles or plugins repo is prose. |

Two things that make the middle rung less automatic than it looks. A **bare
identifier pattern matches the definition too** (`ast-grep --lang bash -p 'foo'`
returns `foo() { … }` alongside every call), so an unshaped pattern is just
`grep` with extra syntax. And a language server has to be **on `PATH`**, not
merely installed — `bash-language-server` sitting in `~/.local/share/nvim/mason/bin`
is invisible to the `LSP` tool, which silently drops shell to the middle rung.

Structural tools carry their own empty-result trap: an `ast-grep` pattern that
fails to parse returns no matches and exit 0, indistinguishable from a clean
tree. The control test in *Results that lie* applies unchanged — and control it
against a term you know is present, in the tool you are actually using.

## WebFetch — do not retry the same failing URL

Promoted to a skill: invoke `documentation-plugin:docs-fetch-fallbacks` when a
WebFetch returns 404, 403, or a timeout — it carries the failure→fallback table
(strip the query string, `raw.githubusercontent.com`, `gh api
repos/<o>/<r>/contents/<path>`, alternate UA, context7/WebSearch), the
two-attempt ceiling, and the rule to surface the failure rather than loop.

## Bash permission denials are terminal

When a Bash call returns:

> Permission to use Bash has been denied

the denial is **final for that command**. Do not retry with cosmetic
variations (different quoting, prepended `env`, etc.) — it will be
denied again. Either:

1. Use the alternative tool suggested in the denial message.
2. Hand the exact command to the user with `! <cmd>` for them to run.

See `handling-blocked-hooks.md` (in claude-plugins) for the user-handoff
template.


## Results that lie — promoted to a skill

Promoted to a skill: invoke `agent-patterns-plugin:tool-result-traps` when an
empty or negative tool result is about to gate an action or be reported as
done — a dedup that concludes nobody filed it, a sweep declared complete, a
verification that reports nothing was lost. It carries the `rg -r` silent
rewrite (`-r` is `--replace`, not a bundled short flag), `git grep -E`
dropping `\b` so the pattern matches nothing, a rejected flag looking exactly
like "no results" (and its worse variants on a *write* and on an *accepted*
flag that takes your stdin marker literally), the worktree-shell `cd` wedge
and the vacuous path-scoped verification that shares its cause, `Workflow`
`args` arriving JSON-encoded, and the parallel-batch rule for tools whose
siblings can exit non-zero.

One line of it stays inline, because it applies to every negative above and
there is no earlier moment to invoke a skill: **control-test any negative that
gates an action** — re-run the same command shape against a term you know is
present. If the control is also empty, the tool is broken, not the tree clean.

The control must exercise the part of the pattern that can fail, not just
the command name. Observed 2026-09-02: `git grep -nE 'parseFloat\([^)]*\)\s*\|\|'`
returned nothing and was "confirmed" by a control counting bare `parseFloat`
— which tests neither the `[^)]*` (it cannot span the nested parens in
`parseFloat((e.target as HTMLInputElement).value)`) nor the `|| fallback`.
The bug was live at four sites and was reported to the user as fixed. A
second attempt returned empty *including its control*, which is what finally
named the tool rather than the tree; `rg` with the same pattern found all four.
Two lessons: negated character classes cannot span nested delimiters, and
`git grep -E` and `rg` do not agree on every regex — when a negative matters,
confirm it with the other tool.

For mechanical work (parsing, counting, audits) prefer one inline
`python3`/`rg` pass over an agent fan-out — see
`offload-to-deterministic-substrate.md`.
