---
paths:
  - "**/*.rs"
  - "**/rustfmt.toml"
  - "**/Cargo.toml"
---

# Onboarding a `cargo fmt --check` Gate Onto a Never-Formatted Rust Repo

When you add a CI `fmt` job (`cargo fmt --all -- --check`) to a Rust repo
that was **never run through rustfmt**, the first `cargo fmt --all` reflows the
*entire* tree — often hundreds of lines across dozens of files — because the
code was hand-formatted denser than rustfmt's defaults. Default rustfmt's
`fn_call_width = 60` (60% of `max_width`) explodes multi-arg calls one-per-line,
so a tidy `foo(a, b, c, d)` becomes a four-line block. The gate is worth having,
but the blast radius fights the author's style and balloons the diff.

## The rule

Before applying `cargo fmt --all`, add a `rustfmt.toml` with:

```toml
use_small_heuristics = "Max"
```

This sets `fn_call_width`/`array_width`/`chain_width`/etc. to `max_width` (100),
so any call/array/chain under 100 cols stays on one line — preserving the dense
single-line style and collapsing churn to the genuinely-non-compliant spots
instead of a tree-wide explosion. In one real onboarding this turned a default
+803/−193 reflow into a net **−553** (denser) diff that mostly matched the
existing code.

## Sequence

1. Add `rustfmt.toml` (`use_small_heuristics = "Max"`) **first**.
2. `cargo fmt --all` — now a minimal reflow.
3. Commit the reformat as an **isolated `style:` commit** (separate from the CI
   commit), so it's reviewable and revertable on its own. It is a *prerequisite*
   for the fmt gate to pass, so it must land in the same PR as (or before) the
   CI `fmt` job — don't ship the gate against an unformatted tree (red CI on
   merge).
4. Verify the tree is clean: `cargo fmt --all -- --check` exits 0, tests green
   (the reflow is mechanical — tests are the proof semantics are unchanged).

## When this bites

- Any Rust repo gaining its first `fmt` CI gate or pre-commit hook.
- Inherited/ported repos where `cargo fmt` was never enforced.

If the author genuinely wants default rustfmt style, skip the toml — but that's
a deliberate style change to surface, not a silent side effect of "add CI".

## Rationale

The fmt gate is a real local↔CI-parity win (`local-ci-parity.md`), but bolting
it onto an unformatted repo silently imposes a formatting standard. `Max`
heuristics keeps the existing dense style compliant, so the gate enforces
consistency *going forward* without rewriting the past — minimal diff, no style
fight, and the `style:` commit stays a clean mechanical artifact.
