# Verify the Licensing *Position*, Not Just the LICENSE File

A `LICENSE` reads complete and authoritative, so a restriction found in it gets
reported as settled fact. But for source-available models and dependencies the
vendor's *actual* position routinely lives in two other places **in the same
repo**: a licence FAQ, and the discussion tab. Read the licence, then go find
those, before telling anyone a licence blocks the work.

> Canonical break (2026-08, `MiniMaxAI/MiniMax-H3`): `LICENSE` §I.5 excludes the
> EU, UK, South Korea and USA from the "Applicable Territory", and §V.4 bars use
> — even distribution of *Outputs* — outside it. That was reported as a hard
> blocker in a public issue. The same repo's `docs/QA-about-License.md` frames
> the carve-out as regulatory caution, *"not yet, not ever"*, and links an
> application form; a maintainer in HF discussion #12 wrote **"apply will auto
> get access"** and told individuals to put `Personal/None` in the mandatory
> Company Name field. The blocker was a form. Corrected twice, publicly.

## The check

List the repo's own docs, then read the discussion:

```
curl -s https://huggingface.co/api/models/<owner>/<repo> | jq -r '.siblings[].rfilename' | grep -iE 'licen|faq|qa|terms'
```

```
curl -s https://huggingface.co/api/models/<owner>/<repo>/discussions/<n> | jq -r '.events[] | select(.type=="comment") | "=== \(.author.name)\n\(.data.latest.raw)\n"'
```

GitHub analogue: `gh api repos/<owner>/<repo>/contents` for a licence FAQ
alongside `LICENSE`, plus the issue/Discussions tabs.

## Who actually speaks for the vendor

**HuggingFace's `isOwner` is not the authority test** — it reads `false` for
every human commenter, staff included. Check **commit authorship**; write access
to the repo, especially authorship of the licence or FAQ commit itself, is the
signal:

```
curl -s https://huggingface.co/api/models/<owner>/<repo>/commits/main | jq -r '.[] | "\(.date)\t\(.authors[]?.user // "?")\t\(.title)"'
```

GitHub analogue: `author_association` (`MEMBER` / `OWNER`) — and note it is *not*
a field on `gh pr view --json`; read it from `gh api`.

## Read them — do not rely on them

In the same case the informal replies were **looser than the documents they
explained**: the QA doc said MiniMax *"may authorize"* after reviewing the
deployment, the maintainer said *"auto get access"*; and one reply ("you don't
need apply" to distribute Outputs into excluded regions) contradicts §V.4 on its
face. So:

- The rule is *go read the FAQ and the thread*, never *act on them*.
- Act on the **written grant**. A forum reply is evidence a path exists, not the
  path.
- Report the divergence rather than silently adopting the permissive reading.

## When it bites

- Evaluating an open-weights model or source-available dependency as a project
  target — exactly where a "we can't use this" verdict gates real work.
- **Geography or entity carve-outs specifically.** These are usually regulatory
  caution with an application path attached (AI Act, pending litigation), not
  prohibition. Treat "Excluded Territories" as "ask", not "no".
- Any licence conclusion about to be written into a public artifact. Being wrong
  here discourages work that was permitted all along, and the correction is
  public too.

Corollary: do not design around the restriction (jurisdiction shopping, hosting
in a non-excluded region) before checking whether the vendor simply grants
exceptions. The workaround is usually more effort *and* more risk than the form.

## Related

- `read-issue-thread-before-contributing.md` — same family: the primary artifact
  is a lossy view of the position; the thread carries the decision.
- `verify-upstream-before-patching.md` — consult the authoritative source before
  acting on a snapshot.
- `never-fabricate-test-identifiers.md` — a confidently-wrong reading that looks
  exactly like a correct one.
