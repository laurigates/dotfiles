# A Textual Auto-Merge Silently Duplicates an Identical Addition Both Branches Made

`git merge` resolves line-by-line, not semantically. When **two branches each
add the same logical thing independently** — the same helper function, the same
`use` import, the same enum arm, the same config key — and the additions land in
**non-adjacent regions** of the file, git sees no overlapping hunk, declares
`Automatic merge went well`, and **keeps both copies**. The result is a
duplicate definition that does not compile (or a double import / double key the
compiler or linter rejects), produced by a merge that reported success.

The failure is invisible at merge time: there is no conflict, no marker, no
prompt. `git status` is clean, the merge commit is ready, and only a build
surfaces it — `the name ... is defined multiple times`, `duplicate definition`,
`E0428`, a redeclaration error, etc.

## The trap (real: jnv dogfood integration, 2026-06)

Two feature branches each needed a cursor primitive and each added the **same**
`set_cursor` helper to `query_editor.rs`:

- `feat/context-aware-completion` added `fn set_cursor` near its
  `replace_text_at`.
- `feat/vi-editing` added an identical `fn set_cursor` in its vi block.

Merging the second into the combined branch:

```
$ git merge --no-commit --no-ff feat/context-aware-completion
Auto-merging src/query_editor.rs
Automatic merge went well; stopped before committing as requested
```

…yet the merged file held **two** `fn set_cursor` definitions (the additions
were ~20 lines apart, so no hunk overlapped). `cargo build` then failed with a
duplicate-definition error. The merge "succeeding" is exactly what makes this
bite — you trust the green message and commit a tree that cannot compile.

## The rule

- **Verify every non-trivial merge by building/testing, not by the merge
  message.** `Automatic merge went well` means "no overlapping line hunks," not
  "the result is correct." Run the compiler / `cargo build` / `cargo test` /
  the linter on the merged tree before committing the merge.
- **When two branches are known to add overlapping helpers** (the same util, the
  same import, the same enum variant — common when sibling feature branches
  solve related problems), **don't trust the auto-merge**: grep the merged file
  for duplicates and hand-resolve to a single combined version.

```sh
# After a merge of branches that may both add the same symbol:
git merge --no-commit --no-ff <branch>
cargo build 2>&1 | grep -iE 'defined multiple times|duplicate'   # or your toolchain's check
grep -c 'fn set_cursor' src/query_editor.rs                      # expect 1, not 2
```

If a duplicate is present, replace the file with the intended **single**
combined version (keep one definition; merge the surrounding feature-specific
code by hand) rather than accepting git's two-copy output.

## When it bites

- Integrating sibling feature branches that independently grew the same helper /
  import / arm — especially a long-lived integration branch (a `dogfood` build)
  merging several `feat/*` branches that each touched a shared file.
- Cherry-picking or rebasing where the same fix was applied on two lines that
  don't textually collide.
- Any language where a duplicate symbol is a hard error (Rust, Go, C/C++,
  TypeScript with `noRedeclare`); in looser languages the second copy silently
  shadows the first instead — worse, because nothing errors at all.

## Relationship to sibling rules

Same instinct as the other merge-hazard rules — *a merge that reports success is
not proof the result is correct*:

- `squash-merge-orphans-post-merge-commits.md` — "PR merged" ≠ "all the branch's
  commits are in main."
- `stacked-pr-merge-order.md` — a stacked child auto-closes (not retargets) when
  its base branch is deleted.
- `shared-checkout-branch-isolation.md` — a commit can land on the wrong branch
  with no error.

This one is the *content*-level analogue: a clean merge can still produce a
broken tree. The check is one build (or one `grep -c`) on the merged result
before committing.

## Rationale

The green `merge went well` reads as a verdict on correctness; it is only a
verdict on line adjacency. The gap is exactly the case where two branches did
the same work in different places — increasingly common as parallel agents and
sibling feature branches solve related problems independently. One compile of
the merged tree before committing converts a silent duplicate-definition (caught
later, mid-integration, under time pressure) into a five-second check.
