# Read the Full Issue Thread Before Scoping a Contribution

Before building a PR (or even an approach) off a GitHub issue, **read every
comment in the thread** — not a fetched summary, not just the body. Issues that
look like simple feature requests are often where the maintainer has already
**converged on a specific design** with other experts. A summary compresses
exactly the part that matters: the decided mechanism, the agreed scope, and the
work someone has already volunteered to do.

## The trap

`WebFetch` (and any "summarize this issue" step) returns a *compressed* view. It
faithfully captures the issue **body** and headline asks, but silently drops the
back-and-forth in the comments where the real decisions live. You then design
against the body's framing, build a prototype, and discover — only if you go
back and read the comments — that:

- the maintainer picked a **different mechanism** than the obvious one,
- the **scope** (MUST / WANT / NICE / OUT) was explicitly bounded,
- a dependency was **already prototyped** by a collaborator (and may be
  unreleased, so half your plan isn't even buildable yet),
- your "open questions" were **already answered** in the thread — so asking them
  reads as not having done the homework.

> Canonical break (jnv #114 → PR #116, 2026-06): a WebFetch summary presented the
> issue as "extend completion beyond JSON paths." The actual 33-comment thread was
> a design discussion in which the maintainer and the jaq author had converged on
> **token-based segmentation** (jaq's `load::lex` token trees) plus a new `yield`
> filter (an *unmerged* jaq PR) for the in-paren case, with an explicit scope
> ladder. We built a byte-scanner PoC and a PR body that re-litigated settled
> questions — caught only when the user asked "did we check all the comments?"
> The PR had to be reframed before it was safe to surface.

## The rule

When an issue is the basis for a contribution, read the comments **first**:

```sh
gh issue view <n> --repo <owner>/<repo> --json title,body,author,comments \
  --jq '.body, (.comments[] | "--- " + .author.login + " ---\n" + .body)'
```

Specifically extract, before writing any code:

1. **Decided mechanism** — has the maintainer chosen an implementation approach?
   Build *that*, or explicitly propose an alternative knowing theirs exists.
2. **Scope ladder** — MUST / WANT / NICE / OUT. Don't attempt OUT; don't skip MUST.
3. **Dependencies in flight** — linked PRs/branches a collaborator is building.
   Check their state (`gh pr view` → merged? released?) before depending on them.
4. **Who's driving** — if the maintainer is mid-collaboration with another expert,
   a drive-by PR may duplicate their work. Ask whether a contribution is welcome
   *before* investing, and frame the PR as building on the thread, not restarting it.

If you only have a summary and a gap has passed, **re-read the live thread** before
acting — the discussion may have moved.

## When it bites

- Any external contribution scoped from an issue, especially a popular repo where
  maintainers discuss design in comments.
- Resuming work on an issue days later from a cached summary.
- Letting an early `WebFetch`/research step stand in for the primary source.

## Relationship to sibling rules

- `verify-upstream-before-patching.md` — same instinct (check the authoritative
  source before acting) for vendored code; this is the issue-thread analogue.
- `tool-use-patterns.md` (WebFetch) — a summary is lossy; for a decision that
  gates real work, go to the full source, not the fetched digest.

## Rationale

The cost asymmetry is stark: reading the thread is one `gh issue view` and a few
minutes; skipping it costs a misaligned prototype, a PR that signals you didn't
read the discussion, and a reframe-or-close under the maintainer's eye. The full
thread is the spec; the summary is a lossy proxy for it.
