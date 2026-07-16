# `set -o pipefail` + Early-Closing Reader = False Pipeline Failure

**Scope**: writing or reviewing bash/sh that combines `set -o pipefail` (or
`set -euo pipefail`) with a pipeline whose **reader exits before consuming all
input** — `grep -q`, `grep -m1`, `head`, `sed q`, `tail` with early quit, a
`while read` that `break`s. Skip for pipelines whose reader drains stdin
(`grep` without `-q`, `wc`, `jq`, `awk` to EOF, `sort`).

## The trap

`grep -q` (and friends) close their stdin the instant they have an answer —
`grep -q` on the **first match**, `head -n1` after the first line. The upstream
writer is then still writing, gets **SIGPIPE**, and exits with status 141. Under
`set -o pipefail` the pipeline's exit status is the *last non-zero* — so the
pipeline reports **failure (141) even though grep matched**:

```bash
set -o pipefail
printf '%s\n' "$big_listing" | grep -qE 'main\.js$' \
  && echo "found" || echo "missing"     # prints "missing" — WRONG, it matched
```

The bug is **size-dependent and therefore intermittent**: if the writer's whole
output fits in the 64 KiB pipe buffer it finishes (exit 0) *before* grep closes
the pipe, so small inputs pass and large inputs fail. A check that works on a
short string silently breaks on a long one (`unzip -l` of a big archive,
`docker logs` of a long-running container, a 2000-line file). It will not
reproduce in an interactive shell that lacks `pipefail`.

## The fix

Feed the reader without a pipe, so there is no upstream writer to receive
SIGPIPE. A **here-string** is the direct replacement:

```bash
grep -qE 'main\.js$' <<<"$big_listing"   && echo found   # correct
grep -q 'dist/'      <<<"$listing"       || die "no dist/"
```

| Wrong (pipe + early-closing reader) | Right |
|---|---|
| `printf '%s' "$v" \| grep -q PAT` | `grep -q PAT <<<"$v"` |
| `cmd \| grep -q PAT` (cmd output capturable) | `out="$(cmd)"; grep -q PAT <<<"$out"` |
| `cmd \| head -1` where cmd's exit matters | capture first, or accept the 141 explicitly |

When the source is a command (not a variable), capture it first
(`out="$(cmd)"`) then here-string the reader. If you must keep the pipe,
isolate it from `pipefail` — `{ cmd | grep -q PAT; } || true` then test
separately, or `set +o pipefail` around just that line — but the here-string is
cleaner and conveys intent.

## Don't "fix" it by dropping pipefail

`pipefail` is load-bearing everywhere else in the script (it's why
`a | b | c` fails when `a` dies). Removing it to silence this one false failure
trades a localized cosmetic bug for a class of *silent* ones. Fix the single
pipeline, keep the option.

## Verify

Reproduce the failure and confirm the fix by forcing a large writer so SIGPIPE
actually fires (a small input won't show it):

```bash
bash -c 'set -o pipefail; seq 1 100000 | grep -q "^5$"; echo "pipe exit=$?"'   # 141 (false fail)
bash -c 'set -o pipefail; grep -q "^5$" <<<"$(seq 1 100000)"; echo "hs exit=$?"' # 0   (correct)
```

## When it bites

- A validity gate that greps a long listing: `unzip -l "$zip" | grep -q …`,
  `tar -tf "$f" | grep -q …`, `find … | grep -q …`.
- Health checks scanning `docker logs <long-running-container> | grep -q …`.
- Any `printf "$big" | grep -q` / `… | head -1` where the result drives a
  `&&`/`||`/`if` and the script runs under `set -euo pipefail`.

Bit twice in one session writing the FoundryVTT upgrade toolkit
(`swap-core.sh` Node-build detection on a ~2700-entry `unzip -l`; `verify.sh`
boot-banner scan of `docker logs`) — both passed on small fixtures and failed
on real data until switched to here-strings.
