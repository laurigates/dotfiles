# Prefer a Transparent DIY Reimplementation Over a Heavy Single-Purpose Dependency

Before reaching for an existing single-purpose tool — especially one with a
GUI, a bundled runtime, an unaudited binary, or that only runs on one
platform — **evaluate whether the underlying operation is simple and
well-documented enough to reimplement directly**, in code that can be read
start to finish. This is not a mandate to always DIY — most of the time the
existing tool is still the right call — but the *evaluation* itself should
always happen before defaulting to "just install the tool that does this."

## The trigger

Run this evaluation whenever a task is about to pull in a tool that is:

- **Single-purpose** — does exactly one narrow thing for this project, not a
  general-purpose runtime/library reused elsewhere too.
- **A GUI wrapping something mechanical** — the "app" is a UI on top of a
  well-defined operation (e.g. "point this at a file and click a button").
- **Not cross-platform**, or otherwise poorly maintained, one-off, or
  distributed as an opaque bundled binary that can't easily be audited.
- **Heavier than the job warrants** — bundles a runtime (Electron, Qt,
  PyInstaller) or drags in a chain of transient dependencies just to perform
  one well-scoped operation.

## When DIY is likely the right call

- The underlying protocol/algorithm/format is **documented, or has an
  authoritative open-source reference implementation** to verify against —
  not something to be guessed at from scratch.
- The reimplementation is **bounded** — tens to a few hundred lines, not a
  multi-week undertaking re-deriving something genuinely hard.
- What results is **auditable**: one file, or a small readable set, that a
  future session (or the same person in six months) can read top to bottom
  and trust, instead of a black-box binary.
- It removes a **disproportionate dependency chain** relative to the value
  (a GUI app + its bundled runtime + a mount step, vs. one script + one
  well-known library).

## When NOT to DIY

- The tool encapsulates **real, hard-to-verify complexity** — cryptographic
  correctness, hardware timing, safety-critical logic — where a subtle bug
  in a reimplementation is a worse outcome than keeping the dependency.
- **No authoritative reference exists** to verify a reimplementation
  against; the result would be unverified guesswork shipped with confidence
  it hasn't earned.
- The dependency is already **cheap and well-audited** — a single
  well-known CLI installable via `mise`/`uv`/`brew` per this file's Tool
  Installation Priority. Don't reimplement `curl`.
- The existing tool is actively maintained and the switching cost (in time,
  or in correctness risk) clearly exceeds the dependency it removes.

## If DIYing: verify against an authoritative source, don't trust memory

A reimplementation is only as good as its verification. Before trusting a
from-scratch port of a protocol or algorithm:

1. **Find an authoritative reference** — the original implementation, a
   spec, an RFC, or (for reverse-engineered protocols) two or more
   independent, converging open-source implementations.
2. **Cross-check constants and structure directly from source**, not from
   memory or a summarized web result — same instinct as
   `verify-upstream-before-patching.md`.
3. **Write a diff test**: run the new implementation and the reference
   implementation's core logic side by side on the same inputs — including
   edge cases and boundary conditions — and assert byte-for-byte /
   result-for-result equality. This is `offload-to-deterministic-substrate.md`
   applied to correctness itself: don't eyeball two implementations and
   declare them equivalent, make a script prove it.
4. **Attribute and license correctly.** Vendoring or closely porting
   someone else's documented algorithm still carries their attribution and
   license terms — a reimplementation that quietly drops credit isn't
   actually more transparent than the binary it replaced.

## Worked example (2026-07, nintendo-switch-cfw)

A Switch CFW project depended on `CrystalRCM.app` — a mounted, unaudited
macOS GUI binary — just to perform one operation: inject a fusée-gelée
payload over USB into a console in RCM mode. The exploit's memory layout and
USB protocol are fixed and well-documented (CVE-2018-6242), with
byte-identical reference implementations across multiple independent
open-source forks going back to 2018.

Replaced it with a ~215-line, single-file, `uv run`-executable script (PEP
723 inline deps: just `pyusb`) that any future session can read start to
finish. Before trusting it:

- Cross-checked every constant and the full algorithm against two
  independent forks' actual source (not a summary), plus the assembly
  source for the one binary blob that had to stay vendored (a 124-byte
  relocator stub, verified byte-identical across forks).
- Wrote a diff test comparing the new implementation's output against a
  verbatim port of the reference algorithm across six cases (empty, tiny, a
  real downloaded payload, and the exact overflow boundary) — caught one
  subtle behavioral divergence at the boundary case before it shipped.
- Smoke-tested the live CLI path (arg parsing, error paths, USB device
  enumeration) as far as possible without physical hardware.

Net result: one dependency chain (a mounted GUI app of unknown provenance)
replaced by one auditable script plus `pyusb`/`libusb` — both well-known,
independently useful libraries, not another single-purpose black box.

## Relationship to sibling rules

- `code-quality.md` (YAGNI) — DIY only when the win is real; don't
  reimplement speculatively, or for a tool that isn't actually being
  removed as a dependency.
- This file's Tool Installation Priority — governs *which* installer to use
  once a tool dependency is warranted; this rule governs the *prior*
  question of whether to depend on the tool at all.
- `verify-upstream-before-patching.md`, `development-process.md`
  ("documentation-first") — the same "go to the authoritative source, don't
  work from memory" instinct, applied here to verifying a from-scratch
  reimplementation rather than a patch.
- `offload-to-deterministic-substrate.md` — the diff-test step is this
  principle applied to correctness verification itself.

## Rationale

Single-purpose GUI tools accumulate silently: each one is individually
"just one dependency," but across a portfolio of projects they add up to a
pile of differently-built, non-cross-platform, unaudited binaries with no
shared conventions — the opposite of the consistency and simplicity this
portfolio otherwise optimizes for. The fix isn't "never use existing tools"
— most of the time they're still the right call — it's making the
evaluation a habit: before installing the app, ask whether the actual
operation is simple and documented enough to own directly, verify it
properly if so, and only fall back to the heavy dependency when the
evaluation says it's genuinely warranted.
