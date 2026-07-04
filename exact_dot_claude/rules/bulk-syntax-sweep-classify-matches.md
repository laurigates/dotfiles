# Classify Every Match Before a Bulk Syntax-Modernization Sweep

When modernizing a syntax across many files with a regex / `sed` / `perl`
pass — a command rename (`/ns:cmd` → `/ns-cmd`), a tool rename, a path or
import-style migration, an API-version bump in prose — the matched set is
**heterogeneous even though every hit looks textually identical**. A single
pattern catches genuine stale targets *and* several look-alikes that must NOT
be transformed. Blindly rewriting all matches corrupts the look-alikes
silently: the sweep reports success, and the damage surfaces far downstream
(a broken designed filename, a rewritten immutable record).

So before editing, **enumerate the matches and bucket each one** into one of
four categories — each needs different handling.

## The four categories

| Category | Handling | Canonical example (command-syntax sweep, 2026-06) |
|---|---|---|
| **1. Genuine stale target** | Transform | `/configure:mcp` → `/configure-mcp` in live docs |
| **2. False positive** — merely matches the pattern | Leave | `laurigates/dotfiles:latest` (docker tag); `redis://host:6379` (digit after `:`, not a command) |
| **3. Out-of-scope design** legitimately using the old form — esp. **delimiter embedded in designed filenames/paths** | Leave; transforming corrupts the design | `/sync:daily` PRD whose colon also appears in `sync:daily-state.json`, `.claude/commands/sync:daily.md` |
| **4. Immutable / historical record** matching the pattern | Supersede-/status-note, **do NOT rewrite the body** | Accepted ADRs documenting the old `/namespace:command` convention |

Category 3 is the sharpest trap: the delimiter you're replacing (`:`, `/`,
`.`, `-`) often also appears in **filenames, config keys, or URLs** that the
matched token participates in. Hyphenating `/sync:daily` to `/sync-daily` also
rewrites every `sync:daily-state.json` path in the same doc — silently
breaking a design.

## The verification is NOT "zero matches remain"

The naive success test — *"re-run the grep; it should return nothing"* — is
**wrong**, because categories 3 and 4 are *supposed* to keep matching. The
correct test is:

> **Zero matches remain *outside the intentionally-preserved set*.**

Enumerate the preserved buckets (which files/lines are categories 2–4) up
front, then verify the grep returns *only* those. A verification that demands
literal zero will either fail spuriously or — worse — pressure you into
corrupting a category-3 design or rewriting a category-4 record just to make
the count go to zero. (In the 2026-06 sweep the plan's near-zero expectation
silently omitted a whole category-3 file; classifying first caught it, the
grep count would not have.)

## Method

```sh
# 1. Enumerate every match, deduped, before touching anything
git grep -nhoE '/[a-z][a-z0-9-]*:[a-z][a-z0-9-]*' -- <scope> | sort -u

# 2. Tighten the pattern to drop obvious false positives at the source
#    (e.g. require [a-z] after the delimiter to skip ":6379" ports/URLs)

# 3. Bucket the remaining hits → categories 1–4 (read the surrounding line)

# 4. Scope the transform to category-1 files ONLY; hand-handle 3 & 4
perl -i -pe 's{/([a-z][a-z0-9-]*):([a-z][a-z0-9-]*)}{/$1-$2}g' <category-1 files>

# 5. Verify: grep returns ONLY the pre-identified category 2–4 lines
```

Drive the false-positive exclusion into the **pattern** where you can (a port
`:6379` is excluded by requiring a letter after the colon) so the sweep
mechanically can't touch them; reserve manual judgment for categories 3 and 4,
which look like real targets and can only be told apart by reading intent.

## When it bites

- Command-syntax migrations (`/ns:cmd` → `/ns-cmd`), tool/binary renames in
  docs, path or import-style migrations, API-version bumps in prose — any
  find-replace where the delimiter or token **also** appears in filenames,
  config keys, URLs, unrelated designs, or historical records.
- Docs trees that mix live guidance with **ADRs / changelogs / design PRDs** —
  the live docs are category 1, the records are category 4, a planned-feature
  PRD may be category 3, all matching the same regex.

## Relationship to sibling rules

- `verify-upstream-before-patching.md` / `read-issue-thread-before-contributing.md`
  — same instinct: establish the authoritative *intent* before acting, don't
  trust a surface signal.
- `git-hazards.md` — kin in spirit: an automated pass reporting success is
  not proof the *result* is correct; verify the content, not the exit code.
- ADR handling (category 4) follows the standard supersede-don't-rewrite
  convention — set `Status: Superseded` + a top-note, leave the body as a
  historical record.

## Rationale

The regex sees **text**; the transform needs **semantics**. The same surface
pattern spans genuine targets, false positives, live designs that legitimately
use the old form, and immutable records — and each demands different handling.
Classifying the match-set up front converts a silent corruption (a broken
designed filename, a rewritten ADR) — caught later, downstream, under
time pressure — into a five-minute bucketing pass with the intent fresh in
hand.
