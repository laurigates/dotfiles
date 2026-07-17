# Never Fabricate an Identifier You're About to Test Against

When probing a system — an API endpoint, a URL, a record id, a file path, a
ticket number — **obtain the identifier from the system itself. Never invent a
plausible-looking one.** A fabricated identifier turns every subsequent
observation into a two-variable experiment ("is the endpoint blocking me, or
does this thing simply not exist?"), and the two failure modes are routinely
indistinguishable in the response.

## The trap

The fabricated value *looks* real, so it never gets questioned. Its failure then
gets attributed to the hypothesis actually under test.

> Canonical break (2026-07, `research` repo): investigating whether Reddit's
> `.json` endpoint still worked, I made up a thread URL —
> `/r/LocalLLaMA/comments/1i6r9rp/deepseek_r1_is_now_available_on_azure` — a
> plausible id and slug, entirely invented. It returned `403 Blocked`, as did two
> further probes against the same fake thread. I reported the endpoint as
> IP-blocked. The user said "it works in my browser," and the *first* successful
> request revealed the truth: the endpoint returned a JSON **404** — the thread had
> never existed. The real discriminator was the client fingerprint, not the IP, and
> three "conclusive" probes had been testing a nonexistent resource.

The tell that should have fired: `403` and `404` mean very different things, and I
never established which I'd get for a *known-good* id.

## The rule

**Get a real identifier from the source before probing. List before you get.**

```
# Wrong — invent a plausible thread, then test against it
curl https://www.reddit.com/r/X/comments/<made-up-id>/<made-up-slug>.json

# Right — pull a real one out of the system first, then probe that
curl -s https://www.reddit.com/r/X/ | grep -o '/r/X/comments/[a-z0-9]*/[a-z0-9_]*/'
```

Generally: a listing/search call before an item call. `gh issue list` before
`gh issue view <n>`; `Glob`/`ls` before `Read`; a collection endpoint before an
item endpoint.

**Always run a known-good control.** When a probe fails, repeat it against an
identifier you *know* exists. Without a control you cannot separate "access
denied" from "not found" from "wrong shape" — and each implies a completely
different fix.

## When it bites

- Diagnosing whether an endpoint, credential, or permission works — exactly where a
  wrong conclusion triggers a redesign that was never needed.
- Writing tests or repro cases against "example" ids nobody verified exist.
- Citing an issue/PR/commit number from memory instead of looking it up. A
  plausible-but-wrong `#162` is worse than no number: it reads as researched.

## Relationship to sibling rules

- `verify-upstream-before-patching.md`, `verify-machine-facts-before-publishing.md` —
  same instinct (consult the authoritative source before acting). This rule covers
  the *inputs to your own diagnostics*, not the code you patch or the facts you
  publish.
- `tool-use-patterns.md` (Read on a missing path; the `rg -r` fabrication trap) —
  siblings in the same family: a confidently-wrong output that looks exactly like a
  real one.

## Rationale

An invented identifier is a silent confound. It costs one extra lookup to obtain a
real one, and one extra probe to run a control; skipping both bought a wrong root
cause, a confidently-reported non-finding, and a diagnosis that unravelled only
because a human said "but it works for me." The model will not catch this on its
own — in the transcript, a fabricated value looks exactly as legitimate as a real
one.
