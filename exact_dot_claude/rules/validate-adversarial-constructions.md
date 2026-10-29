---
paths:
  - "**/tests/**"
  - "**/*_test.*"
  - "**/*.test.*"
  - "**/test_*.py"
  - "**/docs/adrs/**"
  - "**/benches/**"
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
  retyping hazard as `agent-patterns-plugin:probe-input-integrity` § *extract
  the code, don't retype it*.
- **When a bypass is unavoidable, name the old behaviour and reproduce it
  exactly** — including what the removed call returned on the failure path.
  Short-circuiting a conditional leaves every binding it fed in a state the
  original code never had.
- **Read *which* tests fail, never just the count.** The set is the evidence;
  a total that matches expectation can still be the wrong tests.
- **A pass during a teeth-check is a finding, not a relief.** Diagnose it
  before touching the test.
- **A faithful bypass can still land in the wrong place.** When the mutation is
  applied by a whole-file regex, it can hit an **earlier occurrence** than the
  one under test: the edit succeeds, the run is green, and it reads as "no
  teeth" though the assertion was never touched. `grep -c` the pattern before
  substituting — more than one hit means the regex cannot express the edit —
  then `grep -n` the inserted marker to confirm where it landed. The same check
  applies to the restore afterwards.

  > Observed 2026-09 (R4C-Cesium-Viewer #960). A `perl -0pi` teeth-check
  > inserted a CDP `Network.clearBrowserCache` before the **first** of three
  > `await page.reload()` in the file — inside an unrelated load-time test. The
  > cache assertion still passed, which read as a weak assertion. Re-targeted to
  > the real site it failed at once: `expected +0 to be 42`. The gate was fine;
  > the mutation had missed.
- **Rebuild after the restore, not just after the mutation.** Restoring the
  original with `cp` usually lands in the same second as the mutated build,
  and make/CMake compare one-second mtimes, so the object built from the
  mutant still counts as current. The next run reports the mutant's
  failure against restored source, which reads as a broken fix. `touch` the
  restored file (or `cmp` it and force the target) before rebuilding.

  > Observed 2026-10-22 (skullcaps-native, three times): after restoring
  > `objs_mesh.c`, `paint_list.c` and `renderer.c` from `cp` snapshots, the
  > tests still showed the mutation's failure until the file was touched.

## A comparison harness pinned to a moving baseline stops discriminating

A before/after harness — `git show <ref>:<file>` and diff, golden-vs-production,
"compare against last release" — is only an oracle while its baseline is
**different from the thing under test**. Point it at a moving reference and it
converges on the subject, then reports PASS having compared nothing. Two failure
modes, with opposite symptoms:

| | What happens | What it reports |
|---|---|---|
| **Baseline becomes identical** | the ref advances to include the change | PASS, comparing nothing |
| **Baseline cannot run** | the old file needs something the ref lacks | a *content difference* |

> Observed 2026-08 (claude-plugins #2536): an acceptance gate proving a
> refactor's output was byte-identical defaulted to `BASE_REF=origin/main`. The
> moment the PR merged, baseline and subject were the same bytes and every
> re-run reported `PASSED=7 STATUS=OK` having compared a file with itself. Its
> header anticipated the ref *ageing out of the clone*; identity arrives first,
> on merge, and silently. The same harness extracted only the analyzer and not
> the module it now imported, so the baseline died with `ModuleNotFoundError`
> — exit 1, which is also the analyzer's normal "found warnings" code — and the
> harness attributed the empty output to the change, printing the whole report
> as newly added.

Both are cheap to close, and neither is caught by running the harness today:

- **Assert the baseline differs from the subject**, and treat identity as a
  harness error rather than a pass. `cmp -s "$BEFORE" "$AFTER" && harness_fail`.
- **Assert the baseline actually ran.** Non-empty stderr, or empty stdout from a
  command that prints unconditionally, is a *dead oracle* — never a content
  difference. Give it a third outcome and its own exit code, so "the baseline
  produced nothing" cannot be read as "the output changed".
- **Name the states the harness can be in**, in its own header: older-with-an-
  intentional-change FAILs and that is correct; identical is a harness error;
  only a genuinely comparable ref can pass.

This applies to any harness whose reference point can advance or disappear
without the harness noticing: a `git show <ref>` diff, a golden file regenerated
from the current build, a drift check against `main`, a snapshot compared to
production.

## A benchmark control is only a control until something touches it

The same convergence happens in performance measurement, through two other
routes: the fixture step edits the control, or the timing harness is itself a
variable.

**Deriving test data can mutate the control.** A step that builds a fixture
*from* the control data set can change the control's own state: reflinks, hard
links, `chmod`, atime, warmed caches. The control then measures the condition
it was meant to exclude, and nothing in the result says so.

- Time the control **before** deriving anything from it, or derive from a copy.
- Record in the results how each data set was produced, including every step
  that read or copied it.

> Observed 2026-10 (dust `--shared-blocks`, XFS). The "shared" set was built
> with `cp -a --reflink=always ~/.rustup/toolchains` before timing, which turned
> the "unshared" control `~/.rustup` (198,319 files) into reflinked inodes. It
> was reported as "nothing shared": `--shared-blocks` 769.4 ms vs master
> 96.6 ms (8.0x). A never-reflinked tree, `/usr/share` (128,365 files),
> measured 126.3 vs 66.0 ms (1.9x), and the PR's numbers were corrected.
> Unverified: whether XFS keeps an inode's reflink flag after the copies are
> deleted.

**Two timing harnesses that disagree are both suspect.** Before trusting either
number:

- Alternate the two harnesses back to back on the same command, then repeat on
  a non-blocking control. A gap that appears only on one workload belongs to
  the interaction between harness and workload, not to the code change under
  test.
- Use the same harness and flags on every machine being compared.
- Name the harness next to every number it produced.

> Observed 2026-10 (dust, Linux desktop, kernel 6.17, cpufreq governor
> `powersave`). `hyperfine -N` measured the lock-bound case at ~740 ms; a plain
> bash loop timing the same command measured ~520 ms, consistently when the two
> alternated. Single `/usr/bin/time` runs agreed with the loop (0.49–0.60 s).
> On the non-blocking baseline the methods were within ~6%, and on macOS within
> ~2% for every case. Cause not established; scheduling sensitivity of a lock
> convoy is an unproven hypothesis.

## Related

- `offload-to-deterministic-substrate.md` — the parent law: the simulation is
  the deterministic substrate for the correctness of the *test design itself*.
- `never-fabricate-test-identifiers.md` — sibling instinct: don't trust an
  input you invented until the system confirms it does what you assume.
- `prefer-diy-over-heavy-dependency.md` § diff-test — the same move applied to
  verifying reimplementations.
