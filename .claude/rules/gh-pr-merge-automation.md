# gh PR Merge Automation — `mergeable` ≠ Draft State

**Scope**: writing or reviewing `gh pr merge` automation — the `ghsq` /
`ghrb` / `ghrp` wrappers and their `_gh_poll_merge` engine in
`dot_zshrc.tmpl`, or any script that polls a PR's mergeability before
merging. Skip for one-off interactive `gh pr merge` calls.

## The trap

GitHub's `mergeable` field (GraphQL `PullRequest.mergeable`, exposed as
`gh pr view --json mergeable`) tracks **merge-conflict state only** —
`MERGEABLE` / `CONFLICTING` / `UNKNOWN`. It says **nothing** about whether
the PR is a **draft**. A draft PR reports `mergeable == MERGEABLE`, so a
poll loop that gates solely on that field sails straight through and hands
the PR to `gh pr merge`, which GitHub then **rejects** — draft PRs cannot
be merged. The symptom is a late, generic "merge failed" with no hint that
draftness was the cause.

```zsh
# Wrong — poll gates on mergeable only; a draft passes, then merge fails
state=$(gh pr view "$num" --json mergeable --jq '.mergeable')
[[ "$state" == MERGEABLE ]] && gh pr merge "$num" --squash   # ✗ fails on drafts
```

## The rule

Check `isDraft` **separately and up front**, before the mergeability poll
(marking a draft ready changes its mergeability, so the order matters).
Decide the draft's fate explicitly — skip, prompt, or `gh pr ready` then
merge — rather than letting `gh pr merge` fail:

```zsh
if [[ $(gh pr view "$num" --json isDraft --jq '.isDraft') == true ]]; then
  # skip · prompt · or `gh pr ready "$num"` then fall through to merge
fi
# only now poll `mergeable` and merge
```

`isDraft` and `mergeable` are orthogonal facets of "can I merge this" —
query both. (The interactive pickers should also *surface* draft state so
a `^a` select-all doesn't silently sweep drafts into the batch; see
`_gh_paint` colouring the `draft`/`ready` column.)

## Related session-mates (same gh wrappers)

- **Compact PR-picker preview without an extra API call**: `gh pr diff`
  has no `--stat` flag, but its patch output piped through
  `git apply --stat` renders a diffstat locally — no repo, no extra tool,
  and the **same** single `gh pr diff` fetch you already made. Prefer it
  over dumping `gh pr diff | head -100` in an fzf `--preview` that reruns
  on every cursor move.
- **Colouring a fixed-column word without false positives**: matching a
  bare word (`gsub(/ready/, …)`) also paints it inside a title word like
  *already*. macOS awk has no `\<`/`\>` word boundaries, so guard with
  surrounding spaces — `gsub(/ ready /, " …ready… ")` — since `column -t`
  always pads the token on both sides.

## When it bites

- Any batch/sequential merge tool over "all open PRs" — the list includes
  drafts, and a select-all is one keystroke.
- Migrating merge automation between repos: the `mergeable`-only gate
  works until the first draft in the queue.
