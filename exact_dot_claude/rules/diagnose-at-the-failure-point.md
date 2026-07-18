# Diagnose at the Failure Point — Sentinel Values and the Resource Reading

When a tool or library reports a failure, two surface features routinely
misdirect the diagnosis: the **named entity** in the error, and the **framing**
you inherited going in. Both are cheap to check against reality at the exact
point of failure, and doing so first collapses hours of theory. Two linked
habits:

## 1. A named entity in an error may be a sentinel/default, not a real object

An error that names something by a **low / zero / default identifier** —
`Memory page 0 doesn't exist`, `id 0`, an empty-string name, `index -1`,
`0.0.0.0`, a null UUID — is often reporting an **uninitialized or sentinel
default**, not a real entity that misbehaved. If you build a root-cause theory
on that entity ("why did page 0 get corrupted?"), you are chasing a value that
was never a real object.

**Before theorizing on the entity, verify its identifier came from a real
success** (a completed allocation / lookup / registration), not a fallback path.

> Canonical break (2026-07, cubecl CUDA): `couldn't find resource for that
> handle: Memory page 0 doesn't exist` was read — by a handoff issue, the
> upstream tracker, and me for many iterations — as a memory-pool *reclaim
> race* corrupting "page 0". It was `MemoryLocation::uninit() = {pool:0,page:0}`:
> a **failed allocation** left its handle unbound at the zero default, and every
> downstream lookup of an unbound handle reported "page 0." **Zero** pool
> reclaims had fired. The tell was mechanical: the count of distinct "missing"
> handles equalled the count of allocation failures **exactly**.

The tell is usually a **count or ratio that matches something upstream**
(missing-entity count == failure count) — look for it before accepting the
entity as real.

## 2. For any exhaustion symptom, read the actual resource at the failure point

`OOM` / `out of memory` / `can't allocate` / `ENOSPC` / `too many open files` /
`pool exhausted` are **symptoms with three different fixes** — genuine
exhaustion, fragmentation, or a manager/allocator bug — and one measurement at
the failure point discriminates them:

| Symptom | Read at the failure point | Genuine exhaustion iff |
|---|---|---|
| CUDA/GPU OOM | `cuMemGetInfo` (free, total) | free ≪ requested |
| `ENOSPC` | `df` on the target fs | free ≈ 0 |
| `EMFILE` / too many files | fd count vs `ulimit -n` | count ≈ limit |
| allocator/pool "full" | pool `in_use` vs `reserved` vs device total | in_use ≈ device total |

Instrument the *failing call site* to print this, don't infer it from a sampler
taken seconds earlier (peak may be between samples).

> Same case: `cuMemGetInfo` at the failing `malloc` showed **0.58 GB free of
> 25.2 GB** — genuinely full, not fragmented, not a pool bug. That one reading
> ended the allocator hunt: the working set simply exceeded the card. Every
> competing theory (reclaim race, cursor guard, sync-before-reclaim, a
> resolution "lever") had already died to a measurement, not an argument.

## The meta-principle

**Evidence at the failure point > the framing you were handed > a plausible
mechanism.** A confidently-written issue, a maintainer's stated root cause, and
an error's own wording are all *inputs to verify*, not conclusions. When a
theory and a measurement disagree, the measurement wins — re-diagnose, don't
patch the theory.

## When it bites

- Debugging a panic/error whose message names an entity by a suspicious
  round/zero/default value.
- Any "resource exhausted" failure where the fix depends on *why* (capacity vs
  fragmentation vs leak vs manager bug).
- Inheriting a handoff issue / upstream tracker that already asserts a root
  cause — the framing steers you past the measurement that would refute it.

## Relationship to sibling rules

- `never-fabricate-test-identifiers.md` — same family (a confidently-wrong value
  that looks real). There it's an id *you* invent; here it's a sentinel the
  *system's own output* hands you.
- `read-issue-thread-before-contributing.md`, `verify-upstream-before-patching.md`
  — don't trust the inherited framing; go to the authoritative source. This rule
  is the *runtime* analogue: the authoritative source is the failing call site.
- `tool-use-patterns.md` (the `rg -r` fabrication trap) — a well-formed output
  that silently doesn't match reality.

## Rationale

The two features that misdirect — a sentinel in the message and the framing you
walked in with — are both falsifiable in one cheap reading at the failure point.
Skipping that reading trades a five-second `cuMemGetInfo`/`df`/count for a
multi-iteration hunt down a mechanism that never occurred, and the wrong theory
keeps looking plausible because nothing on the surface contradicts it. Measure
the failure itself first; let the surface wording and the handoff be the last
things you trust.
