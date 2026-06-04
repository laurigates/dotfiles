# Colourising `column`-aligned fzf Picker Tables

**Scope**: building interactive `fzf` pickers in zsh — the `gh*` wrappers in
`dot_zshrc.tmpl`, or any `… | column -t | fzf --ansi` list that should be both
aligned *and* coloured. Skip for non-interactive output.

## The trap

You want a picker list that is BOTH column-aligned and colourised. The obvious
order — colour the fields first (in `jq`/`awk`), then `column -t` — breaks
alignment: `column -t` counts the raw ANSI escape bytes as visible width, so
coloured columns get padded wrong and the table comes out ragged. Both BSD
`column` (macOS) and GNU `column` miscount this way; there is no flag to fix it.

## The rule

Insert colour **after** `column -t`, never before. Compute the padding on plain
text, then add the escapes in a final `awk` pass. Under `fzf --ansi` the codes
render with zero width, so the alignment computed by `column` is preserved
exactly.

```
gh pr list --json … --jq '… | @tsv' | \
  column -t -s $'\t' | \
  _gh_paint | \
  fzf --ansi …
```

A reusable painter — it matches glyphs/tokens on the whole line (`$0`), never
splitting into fields, so it never rebuilds `$0` and collapses `column`'s
padding to single spaces:

```zsh
_gh_paint() {
  awk '{
    gsub(/✓[A-Za-z]*/, "\033[32m&\033[0m")   # success  → green
    gsub(/✗[A-Za-z]*/, "\033[31m&\033[0m")   # failure  → red
    gsub(/⏳[A-Za-z]*/, "\033[33m&\033[0m")  # pending  → yellow
    gsub(/#[0-9]+/,     "\033[36m&\033[0m")  # PR/issue → cyan
    gsub(/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/, "\033[2m&\033[0m")  # date → dim
    print
  }'
}
```

## Two facts that make this safe

1. **`fzf --ansi` strips the escapes for field extraction and for output.** A
   `{1}` placeholder in a `--preview` command, and the selected line returned on
   stdout, are the *plain* text — the colour codes are gone. So number-extraction
   logic (`awk '{print $1}'`) is unaffected by the colouring.
2. **`awk` interval regexes (`{4}`) are unreliable on macOS awk.** Spell them
   out — `[0-9][0-9][0-9][0-9]`, not `[0-9]{4}` — or the pattern silently fails
   to match. (`+` and `*` work fine.)

## Extraction caveat

After `column -t`, the field that can contain spaces (a PR/issue title) must be
the **last** column, and every fixed column before it must be a single token
(branch names have no spaces; status glyphs like `✓CI` / `draft` are one token).
Then this recovers the id and the title cleanly from a selected line:

```awk
{ num=$1; sub(/^#/,"",num); $1=$2=$3=$4=$5=""; sub(/^ +/,""); rest=$0 }
```

Prefixing the id column with `#` (e.g. `"#\(.number)"` in `jq`) lets the painter
colour it cyan, and previews still work without stripping — `gh pr view '#123'`
and `gh pr diff '#123'` both accept the `#` prefix.

## Verify

```
printf '#1\t✓CI\ttitle\n#22\t✗CI\tt2\n' | column -t -s $'\t' | _gh_paint | sed -n l
```

The two rows line up, and the `\033[…m` escapes sit *outside* the padded spans
(insert them before `column` instead and the second row's padding is visibly
short).

## When it bites

- Any `gh`/`fzf` picker that builds a `--json`/`--jq` table and wants colour:
  `ghi`, `ghpc`, `ghsq`/`ghrb`, `ghrp`, and the read-only `_gh_*_pick` helpers
  in `dot_zshrc.tmpl` all share the `column -t | _gh_paint | fzf --ansi` shape.
- Porting a coloured `column`-aligned table anywhere — logs, status dashboards,
  `task`/`kubectl` summaries piped through `fzf`.
