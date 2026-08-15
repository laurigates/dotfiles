---
paths:
  - "**/tests/**"
  - "**/*_test.*"
  - "**/*.test.*"
  - "**/test_*.py"
  - "**/docs/adrs/**"
---

# Simulation-Validate Adversarial Constructions Before Freezing Them

An adversarial test construction — a discriminator input, a stress case, an
accuracy gate, any "this case catches that bug" claim — is **unverified until a
deterministic simulation of the exact mechanism under test shows it decisively
separates broken from correct, on every seed**. Asserted-by-construction is a
hypothesis, not a property: the construction encodes the author's noise model,
and the noise model is exactly the thing most likely to be wrong.

## The rule

Before an adversarial case ships in a spec, ADR, or test suite:

1. **Simulate the charged mechanism** (not a sketch of it — the same
   quantization/rounding/precision path the real system takes) with the
   defect present *and* absent.
2. **Require decisive separation**: the broken variant must fail the gate
   with margin on **every** seed; the correct variant must pass with margin.
   A construction that separates on most seeds is a flaky gate, not a gate.
3. **Encode the validation as a meta-test** that runs forever after — one
   test proving the case still kills the broken variant (the gate has
   teeth), one proving the correct variant still passes (the gate is
   achievable, not aspirational). The meta-tests keep the case lethal as
   magnitudes and code evolve.
4. When the simulation and the construction disagree, **the simulation
   wins** — re-derive the construction, and record the refuted version and
   why it failed (the failure mode is usually a reusable lesson).

## Why (measured, 2026-07, attention-engine ADR-0011)

One protocol-design session fired this rule three times, each catch invisible
to review-by-reading:

- The first-draft smoothing discriminator was **refuted by simulation** — an
  unsmoothed kernel passed it with ~25× margin, because unbiased rounding
  dithers mean logit gaps through and a token-constant bias's quantization
  error is softmax-shift-invariant. Plausible construction, zero teeth.
- The redesigned construction was dead at implementation time for a different
  reason: the drafting simulation had **omitted the `1/√d` score scale** the
  real attention applies. Caught only by re-simulating with the real
  mechanism (`Q ≡ 2` → measurably dead; `Q ≡ 16` → designed separation
  restored exactly).
- The pre-freeze calibration then caught the **noise model itself** being
  wrong ~23×: near-uniform attention averages dense per-logit noise by
  ~`1/√N`, so predicted output error was dominated by a floor the model
  had ignored.

Three independent designers and a four-lens adversarial review all missed the
first defect; a 60-line NumPy simulation found it in seconds.

## The bypass must reproduce the old behaviour, not merely disable the new

Step 3's "prove the gate has teeth" is normally done by reverting the fix and
watching the test fail. The trap is that the quickest way to *disable* a guard
is rarely the same thing as *restoring the pre-fix state* — and when it isn't,
the run tells you nothing while looking like a clean verification.

The tell is a **test that passes when you expected it to fail**. That reads as
"weak assertion" and invites deleting the test; the real cause is usually that
the bypass introduced a *different* failure which the test caught by accident.

> Observed 2026-08 (thelma, funding-analysis). Adding a Zod `safeParse` after
> `JSON.parse`, the teeth-check short-circuited the throw:
> `if (false && !validated.success)`. Four of five tests failed as designed —
> but `safeParse` returns **no `.data` on failure**, so `parsed` became
> `undefined` and `parsed.dimensions` threw a `TypeError`. The fifth test
> ("a failed parse is not cached") passed on that TypeError, not on the
> behaviour it asserts. Re-run against a faithful stand-in —
> `const validated = { success: true, data: raw }`, which is exactly what the
> old unvalidated code did — and all five failed. The gate was fine; the
> bypass was lying.

- **Prefer deleting the new code to neutering it.** `git stash`, or check out
  the pre-fix file, and run against that. A hand-written bypass is the same
  retyping hazard as `never-fabricate-test-identifiers.md` § *extract the code,
  don't retype it*.
- **When a bypass is unavoidable, name the old behaviour and reproduce it
  exactly** — including what the removed call returned on the failure path.
  Short-circuiting a conditional leaves every binding it fed in a state the
  original code never had.
- **Read *which* tests fail, never just the count.** The set is the evidence;
  a total that matches expectation can still be the wrong tests.
- **A pass during a teeth-check is a finding, not a relief.** Diagnose it
  before touching the test.

## Related

- `offload-to-deterministic-substrate.md` — the parent law: the simulation is
  the deterministic substrate for the correctness of the *test design itself*.
- `never-fabricate-test-identifiers.md` — sibling instinct: don't trust an
  input you invented until the system confirms it does what you assume.
- `prefer-diy-over-heavy-dependency.md` § diff-test — the same move applied to
  verifying reimplementations.
