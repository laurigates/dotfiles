# Documentation: Link, Don't Duplicate

Write documentation that **points to the single source of truth** instead of
restating it. A fact copied into a second place is a fact that will drift — the
copy goes stale the moment the original changes, and nothing flags it. This is
DRY applied to prose.

## The principle

- **Link from where the reader starts.** Put a short pointer at the entry point
  someone actually lands on (CLAUDE.md, README, a top-level index) that links to
  the deep doc. Don't reproduce the deep doc at the entry point.
- **One canonical home per fact.** Each piece of information lives in exactly one
  authoritative place; everywhere else references it.
- **A runnable artifact is its own doc.** When a skill, playbook, justfile
  recipe, or script both *does* the thing and *explains* it, that artifact is the
  documentation. Link to it — do not write a parallel prose copy that has to be
  kept in sync by hand.
- **Reference the authoritative source, not a hand-copy.** When you must
  enumerate (repos, packages, endpoints, flags), point at the source that's
  already maintained — e.g. "the `comfy_registry = true` entries in
  `repositories.tf`" — rather than transcribing a list that silently falls out of
  date.

## When this bites

| Smell | Why it drifts | Do instead |
|---|---|---|
| A hand-maintained list mirroring config/code | The source changes; the list doesn't | Reference the source ("see the X entries in Y") |
| A command sequence copied into a doc *and* a script | One gets edited, the other rots | Keep it in the script; the doc links to it |
| The same workflow as prose *and* as a skill/playbook | Two copies, two truths | The skill is the doc; link to it |
| A config table duplicated across two READMEs | Updates land in one | One canonical doc; the other links |
| Re-explaining at the entry point what a deeper doc already covers | Entry point and deep doc disagree over time | Short pointer + link |

## When duplication is acceptable

- A one-line *summary* at the entry point (with a link to the full source) is a
  signpost, not duplication. Keep it to the gist, not the detail.
- Small, stable facts (a default value cited inline) can be repeated when
  restating is clearer than a link — but prefer the link if the fact can change.

## Litmus test before adding docs

Ask: *"Does this fact already live somewhere authoritative?"* If yes, link to it.
If you're about to type a second copy of something that exists elsewhere, stop
and reference the original. The best documentation edit is often a pointer, not a
paragraph.

## Rationale

Duplicated documentation doesn't just waste effort — it actively misleads,
because a stale copy still reads as authoritative. Linking from entry points
keeps docs discoverable without creating mirror copies that diverge. Referencing
the source-of-truth means the docs can't go stale relative to it, because there's
only one truth. This is the prose analogue of DRY (`code-quality.md`) and the
docs-side complement of `local-ci-parity.md` (one definition, consumed in many
places).
