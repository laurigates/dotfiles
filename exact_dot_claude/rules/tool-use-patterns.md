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

## Parallel tool calls

### Do not parallel-batch a tool whose siblings can exit non-zero

When one call in a parallel batch exits non-zero, **every sibling is
marked cancelled** and wasted. Specific offenders to avoid in a batch:

- `task <filter> list` — exits 1 on empty result; use
  `task <filter> export | jq '.[]'` (always exit-0) instead.
- `tar -xzf <archive>` — fails on missing archive; verify path first.
- `ls <glob>` — fails on no-match; verify or use Glob.
- `jq` on possibly-empty pipelines.
- `Read` on a possibly-missing path (see above).

Pattern: when a batch's siblings depend on existence, do a single
existence-check call first (`Glob`, `ls -1`), then issue the parallel
batch over confirmed-present paths.

### Agent fan-out rate limits and mid-run kills

Promoted to a skill: see `agent-patterns-plugin:parallel-agent-dispatch`
(§ Concurrent Rate-Limit Risk → `references/failure-recovery.md`) before
fanning out more than ~3 heavy agents, and after any wave dies mid-run — it
carries the server burst limit vs session usage limit discrimination, safe
starting concurrency per agent profile, serialize-or-wave mitigation, the
audit-remote-before-resume protocol (`gh pr list`, `git ls-remote --heads`),
and why `resumeFromRunId` re-runs already-succeeded worktree agents.

For mechanical work (parsing, counting, audits) prefer one inline `python3`/`rg`
pass over an agent fan-out — see `offload-to-deterministic-substrate.md`.

## Grep / rg — `-r` is `--replace`, not a bundled short flag

`rg`'s `-r` takes an argument: it **rewrites every match in the output**. Bundling
it into a short-flag cluster silently consumes the next letter as the replacement
string, so the tool prints *fabricated* lines that look like real file contents.

```
# Wrong — reads as "recursive + line numbers"; actually means --replace=n
rg -rn "yolo" .
./conf/cli_clients/gemini.json:    "--n"      ← the file says "--yolo"; rg rewrote it

# Right
rg -n "yolo" .
./conf/cli_clients/gemini.json:    "--yolo"
```

The failure is **silent and confident**: no error, no warning, and the output is
well-formed — it just doesn't match the file on disk. Observed 2026-07 building a
false picture of a config file that was then nearly acted on; caught only because
the doctored line contradicted an earlier direct `Read` of the same file.

- **`rg` is recursive by default** — there is no `-r` to add. The instinct is
  imported from `grep -r`, and that's the trap.
- **Never bundle `-r` into a cluster.** If an `rg` result contradicts something you
  read directly, suspect the flags before you suspect the file.
- **Prefer the Grep tool** over `rg` in Bash: it has no `--replace` surface, so
  this class of error cannot occur.

## A rejected flag looks exactly like "no results"

Any `cmd … | jq/grep` whose **non-zero exit** yields empty stdout masquerades as
a legitimate empty result. Worst case is a **dedup step**: you conclude nobody
reported the bug and file a duplicate.

Live instance: `gh search issues --state all` is invalid (that flag takes only
`{open|closed}`; `all` belongs to `gh issue list`). It prints usage to stderr,
so a `--jq` pipeline emits nothing — six consecutive false "no duplicate"
verdicts. Use `gh api --paginate "repos/O/R/issues?state=all"` + `grep` instead
(it returns PRs too; discriminate on `.pull_request`).

**Control-test every negative that gates an action.** Re-run the same command
shape against a term you know is present; if the control also returns nothing,
the tool is broken, not the result empty. One control run caught all six above.
This is `never-fabricate-test-identifiers.md`'s known-good control, applied to
search.

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
