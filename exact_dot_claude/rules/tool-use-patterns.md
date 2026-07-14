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

### Don't launch a large agent fan-out in one burst — serialize or wave it

Spawning many agents simultaneously — a `Workflow` `parallel()`/`pipeline()`
of N agents, or N `Agent` calls in one message — can trip a **server-side
burst rate limit** (`API Error: Server is temporarily limiting requests (not
your usage limit) · Rate limited`), distinct from your usage quota. When it
fires, the agents die after their retries and `parallel()` returns them as
`null` — **every agent's startup tokens wasted** (observed: 7 Opus auditors,
628 k tokens, all killed at 18 s).

Mitigations, in order of preference:

- **For deterministic / mechanical work** (parsing, counting, audits, link
  resolution, frontmatter scans), prefer a **single inline pass** — one
  `python3`/`rg` script — over an agent fan-out. It's cheaper, reproducible,
  and rate-limit-immune. Reserve agents for genuinely independent
  *reasoning-heavy* work (judgment, synthesis, review).
- **When you do fan out, serialize or small-wave it.** Run agents in a
  `for…await` loop (one at a time) or in waves of 2–3, not all N at once.
  Sequential execution keeps the request rate low and dodges the burst limit;
  the wall-clock cost is usually acceptable for non-latency-critical work.
- **Don't blind-retry the same wide fan-out** after a burst-limit kill — it
  re-trips. Re-issue serialized, or fall back to the inline pass.

### A usage-limit kill mid-run is recoverable — audit remote, then resume

The **session usage limit** ("You've hit your session limit · resets <time>")
kills in-flight subagents the same way the burst limit does: each agent dies
on a terminal API error at whatever stage it had reached — some after pushing
a branch and opening a PR, some mid-edit, some before starting. A `Workflow`
run reports them under `failures`; completed siblings' results survive in the
run's journal.

Recovery protocol (observed 2026-07: a 14-agent PR sweep lost 7 agents to the
limit and recovered fully):

1. **Wait out the reset** — the limit message names the reset time; nothing
   recovers before it.
2. **Audit remote state before resuming** — dead agents may have half-landed
   their work: `gh pr list --state open` plus `git ls-remote --heads origin`
   show which branches/PRs already exist. A re-run agent that pushes an
   already-pushed branch hits a non-fast-forward reject, and one that
   re-creates an existing PR duplicates it — brief agents to check first, or
   verify the remote is clean yourself.
3. **Resume, don't re-dispatch**: `Workflow({scriptPath, resumeFromRunId})`
   replays completed agents from cache (cache key: unchanged prompt + opts)
   at zero cost and re-runs only the dead ones. Re-dispatching from scratch
   re-pays every completed agent's tokens.

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

## WebFetch — do not retry the same failing URL

| Failure | Try |
|---|---|
| 404 on a docs page with `?ref=…` | Strip query string |
| 404 on a GitHub blob URL | Switch to `raw.githubusercontent.com` URL |
| 404 on a repo path | `gh api repos/<owner>/<repo>/contents/<path>` |
| 403 on a public docs page | Try once with a different UA or a search engine |
| 403 on a GitHub URL | Use `gh api` (authenticated) |
| Timeout | One retry, then fall back to context7 / WebSearch |

If two attempts both fail, surface the failure in the response — do
not loop.

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
