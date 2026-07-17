# Delegating to Other Models — the Disagreement Is the Payload

When brainstorming a design with several models (PAL `chat`/`consensus` over
OpenCode Go, Gemini, GPT), the value is **not** the union of their answers. Two
competent models briefed identically will converge on the obvious 80% — the
module shape, the naming, the standard caveats — and that convergent part is
usually what you'd have written anyway. **The signal is where they split.** A
disagreement between two capable models is a precise pointer to the one decision
that is genuinely load-bearing and genuinely underdetermined by the prompt.

So the protocol inverts the naive one. Don't ask "which answer do I take?" Ask
"what did they disagree about, and *what in my codebase already decides it?*"

## The rule

1. **Brief every model with the *same* prompt.** Different prompts produce
   differences that are artifacts of the framing, not of the problem — and those
   are worthless, because you can't tell a real design tension from a wording
   accident. Identical briefs make a divergence meaningful.
2. **Don't show model A's answer to model B** (in the first round). You want
   independent draws, not an echo. Cross-critique is a *later*, deliberate step.
3. **Diff the answers and find the split.** Convergence → the safe default,
   adopt it and move on. Divergence → this is the actual decision, and it is
   now yours.
4. **Adjudicate against the code, not against taste.** This is the step that
   makes the whole exercise worth its tokens. Go read the thing the decision
   turns on. Very often the codebase has *already decided*, and the models
   couldn't know because they can't see it.
5. **Never adopt a proposal wholesale.** Even the "winner" carries ideas that
   are wrong for your repo. Graft the good parts from the runner-up; reject
   what doesn't fit and say why.

> Canonical case (gh-board priority grading, 2026-07): kimi-k2.7-code and
> glm-5.2 got identical briefs. They converged on the module shape, on
> config-first weights, and — usefully — both independently insisted on an
> itemized **contribution ledger** as the antidote to magic-number soup. They
> split on exactly one thing: does the triage *bucket* feed the priority score
> (kimi: bucket sets a 0–100 baseline) or sit above it (glm: bucket-neutral,
> score ranks only within a bucket)? Reading `src/app/filter.rs` settled it in
> one minute: `build_rows` already groups into bucket sections **after**
> sorting, so a bucket baseline would double-count the grouping and, within a
> group, be a constant that reorders nothing. GLM was right — but *the code*
> proved it, not a preference. Both models also proposed an A–F letter grade;
> **both were overruled**, because grade bands are a second independent set of
> magic thresholds stacked on the weights, quantizing away the fine ordering the
> score exists to produce.

The shape to notice: the models produced the *question*; the repo produced the
*answer*; and the one thing they agreed on that I kept (the ledger) was the one
thing I hadn't thought of. All three of those are the delegation paying off — and
none of them is "the model wrote my design."

## When it's worth the tokens

- **Yes**: an open design decision with a wide solution space and no obvious
  default (scoring models, architecture splits, API shape, migration strategy).
- **No**: anything with a conventional default, anything a lookup answers, or
  anything where you already know what you want and are seeking agreement. A
  model asked to validate will validate — you'll get confirmation, not
  information, and pay for the privilege.

## PAL mechanics that bite

- **`kimi-k2.7-code` 400s whenever `temperature` is sent** (OpenCode Go). The
  error is opaque — `Error from provider (Console Go): Upstream request failed` —
  and names neither the parameter nor the constraint, so it reads as flakiness or
  as "my prompt was too long." Prompt length, file attachments, and
  `thinking_mode` are all innocent; `glm-5.2` accepts `temperature` fine. Omit
  `temperature` for kimi. Tracked: `laurigates/pal-mcp-server#67`.
- **`model_used` in the response metadata can be wrong — verify independence
  via `provider_used`.** A `chat` call requesting `gpt-5.3-codex` returned
  `model_used: gemini-3.5-flash` with `provider_used: openai` (2026-07,
  softmax-rung consults) — an inconsistent triple. Since the whole point of
  a two-model consult is provably independent draws, check the *provider*
  field (and pick models on different providers to begin with); a
  same-model pair silently breaks the disagreement-is-the-payload logic.
  Tracked: `laurigates/pal-mcp-server#68`.
- **Registry models can be retired upstream** — `gemini-3-pro-preview`
  404'd ("no longer available") while still listed by `listmodels`. Have a
  same-provider fallback picked before dispatching (the registry's current
  frontier alias, e.g. `pro`/`flash`), and re-send the identical brief to
  the fallback — a reworded brief would break the identical-briefs
  invariant.
- **Isolate a model failure with controlled probes before believing your first
  theory.** The intuitive suspects (big prompt, file attachments) were both
  wrong here, twice, and a bug filed on either would have been a misleading
  report sending the maintainer down the wrong path. A two-word prompt plus the
  one suspect parameter settles it in one call.
- **`absolute_file_paths` beats pasting code into the prompt** — it's what the
  parameter is for, and the prompt-side copy risks truncation.
- **Use `listmodels` first** when the user names a model loosely ("kimi2.7",
  "glm5.2"). The registry IDs (`kimi-k2.7-code`, `glm-5.2`) and their aliases
  (`kimi`, `glm`) rarely match what anyone types from memory.

## Rationale

The failure mode this rule exists to prevent is treating delegated models as
*authorities* rather than as *idea generators*. Taking the majority answer, or
the more confident answer, launders a coin-flip into a decision that now looks
researched. The disagreement is the only part that couldn't have been produced by
one model alone — and resolving it against the code is the only step that uses
information the models structurally did not have.

## Related

- `agent-and-tool-selection.md` — subagent model policy (always Opus); this rule
  is about *external* models consulted for judgment, not delegates doing work.
- `verify-upstream-before-patching.md` / `read-issue-thread-before-contributing.md`
  — same instinct: go to the authoritative source before acting on a summary.
