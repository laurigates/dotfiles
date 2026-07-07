# llmtrim Vetting & Validation Report

**Date**: 2026-07-06 · **Tool**: [fkiene/llmtrim](https://github.com/fkiene/llmtrim) v0.8.0 (audited at `342e1ab`, built from source)
**Question**: should we add llmtrim (local LLM-request-compressing proxy) for Claude Code and opencode?

## Verdict

**HOLD as a default; safe to trial deliberately.** The tool is technically excellent and
behaved exactly as documented under hands-on testing — but for *Claude Code on a
subscription plan* the economic benefit is small (prompt caching already covers the bulk,
and llmtrim correctly refuses to touch the cached prefix), while the trust surface is
large (a TLS-intercepting proxy from a single-maintainer, pre-1.0 project sits in front
of all LLM traffic including auth headers). The case is stronger for opencode with
per-token API billing. If trialed, integrate via chezmoi-managed env vars, not
`llmtrim setup`'s shell-profile edits.

## What llmtrim is

A Rust local proxy (~52k LoC workspace, MPL-2.0) that MITMs HTTPS traffic to known LLM
provider hosts, compresses request bodies (dedup, template-encoding of repetitive tool
output, JSON down-sampling, minification), and forwards them. Claims −31% input / −74%
output tokens across 112 live A/B cases. Installs via npm/brew/cargo/installer script;
`llmtrim setup` writes `HTTPS_PROXY` + `NODE_EXTRA_CA_CERTS` into the shell profile and
installs a local CA.

## Source audit (clean)

Audited the full source at `342e1ab`:

- **No telemetry.** The only outbound call besides forwarding requests is a version
  check against `api.github.com/repos/fkiene/llmtrim/releases/latest` (cached). The
  savings ledger is a local SQLite DB (`~/.local/share/llmtrim/tracking.db`) storing
  token *counts* only — no prompt content, matching the README's privacy claim.
- **MITM is scoped.** `should_intercept` forges certificates only for hosts in the
  `llm_providers` registry; all other CONNECT traffic is blind-tunneled, so the local CA
  is never used outside its purpose.
- **Fail-safe design.** The original request (with auth headers, held in memory only) is
  replayed verbatim if the provider rejects the compressed body; compression steps that
  don't save tokens after re-measurement are reverted.
- **Supply-chain hygiene is above average**: cargo-deny with deny-by-default licensing,
  SHA256-verified install scripts, npm delivery via per-platform `optionalDependencies`
  (no postinstall download), DCO + CI bench gate, ~830 tests, one `unsafe` block.
- **Honest benchmarks.** Methodology (`bench/BENCH_SPEC.md`) uses sha-pinned public
  corpora, bootstrap CIs, a cost-per-quality metric, and *excludes* the author's own
  synthetic corpus. Caveat: live quality scoring used `gpt-oss-20b`, not Claude in an
  agentic loop.
- **Risks**: single maintainer (71/76 commits by one person, 3 GitHub followers, project
  is months old, pre-1.0), 785 transitive crates, and the inherent sensitivity of a
  component that decrypts all provider traffic. Nothing malicious found; the risk is
  trust concentration and bus factor, not observed behavior.

## Hands-on validation (built from source; all checks passed)

Fixtures: realistic Claude Code-shaped Anthropic requests (system blocks, 4 tool
definitions, multi-turn history with verbose `ls`/grep/JSON/README tool results,
`cache_control` markers placed like Claude Code places them).

| Check | Result |
|---|---|
| Prompt-cache safety: messages/system before the last `cache_control` marker | **Byte-identical** in `auto` and `aggressive`; injected notes are appended *after* the breakpoint |
| Cross-turn simulation (marker moves forward at turn N+1) | Frozen zone untouched; only live-zone content compressed |
| Determinism (same input twice) | Byte-identical output |
| `safe` preset | Lossless (minification only, ~1% bytes) |
| `auto`, no cache markers | −48% bytes / ledger −19% tokens on mixed runs |
| `aggressive`, no cache markers | −52% bytes |
| Dedup honesty | 12× repeated paragraph → one copy + explicit `[×12]` marker; a system note tells the model arrays were down-sampled |
| Latency | ~15 ms/request for the CLI including process start (README claims ~5 ms in-proxy — plausible) |
| Streaming/`stream:true`, `model`, `max_tokens`, tool schema | Preserved |

**Lossiness that matters**: repetitive tool output (grep dumps, `ls` listings) is
*template-encoded* — `src/module_{}.py:{}: def handle_request_{}(...) [×80: (fills…)]` —
not deleted, but the model must reconstruct specific rows from positional fill lists.
Fine for summarization; a real (if benchmarked-neutral) risk when the agent needs one
exact line from a dump. Anthropic token counts in the ledger are calibrated estimates
(no public Claude tokenizer); real usage comes from API responses in proxy mode.

## What it would actually do for us

- **Claude Code (subscription/Max)**: not billed per token, so "savings" translate only
  into rate-limit headroom. With Claude Code's own `cache_control` in place, llmtrim
  compresses only the live zone (measured: ~8% of bytes on a mid-session turn — each tool
  result is trimmed once on arrival, then frozen). The headline −74% output figure comes
  from terse prose-shaping that llmtrim itself *skips* on tool-call-shaped requests, i.e.
  most Claude Code turns. In `auto` mode it does inject a ~50-token "batch your tool
  calls, don't repeat calls" directive on the first agent turn — a deliberate,
  A/B-tested-on-Claude-Code behavior nudge, but a behavior change nonetheless (`safe`
  preset avoids all of this).
- **opencode**: honors `HTTPS_PROXY`/`NODE_EXTRA_CA_CERTS` ([network docs](https://opencode.ai/docs/network/)),
  and API-key usage there is per-token billed — this is where llmtrim's input compression
  is real money, especially with providers/models where prompt caching is weaker.
- **Note**: `llmtrim mcp install` (MCP server mode) does **not** compress Claude Code's
  own traffic — it only exposes compress-a-payload tools to the agent. The proxy is the
  cost-saving path.

## If we adopt (trial plan)

1. Install via `brew install fkiene/tap/llmtrim` (add to `Brewfile` under the `dev`
   profile), pin the version.
2. **Do not let `llmtrim setup` edit the shell profile** — it writes a managed block into
   the rc file, which chezmoi would flag as drift and clobber on apply. Instead run
   `llmtrim ca` + `llmtrim setup --print` (or equivalent) and port the exports
   (`HTTPS_PROXY`, `NO_PROXY`, `NODE_EXTRA_CA_CERTS`) into `dot_zshrc.tmpl` guarded by
   `command -v llmtrim`, plus a service/autostart choice we control.
3. Start with `LLMTRIM_PRESET=auto`; use `safe` if any behavior change is unwanted;
   `LLMTRIM_EXCLUDE_PROVIDERS=anthropic` is the escape hatch that leaves Claude Code
   untouched while still compressing opencode's other providers.
4. Run for a week; judge with `llmtrim status` (it separates cache-excluded input savings
   and real cache reads) and watch for any tool-loop weirdness attributable to
   template-encoded tool output.
5. Re-evaluate at llmtrim 1.0 / broader adoption; record the adopt/reject decision as an
   ADR (`docs/adrs/`) when made.

## Why not "adopt now"

A TLS-intercepting proxy in front of every LLM call is the highest-trust component one
can add to this toolchain. The code passed a genuine audit and the engineering culture is
visibly rigorous, but a months-old single-maintainer project with ~150 stars hasn't had
enough eyes on it to justify default-on interception of authenticated Anthropic traffic —
and for our primary tool (Claude Code on subscription), the measurable benefit today is
rate-limit headroom, not dollars. The cost/benefit flips if/when: (a) per-token API usage
grows (opencode, CI agents), (b) the project matures past 1.0 with more contributors, or
(c) rate limits become a real constraint.
