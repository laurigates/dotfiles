---
id: ADR-0019
status: Accepted
created: 2026-11-11
modified: 2026-11-11
deciders: "Lauri Gates"
domain: chezmoi-workflow
relates-to: [ADR-0001]
---

# ADR-0019: Worktree-First Changes and Guard Hooks Around chezmoi

## Context

ADR-0001 manages `~/.claude` as an `exact_` directory, so an apply deletes any
target file that is in neither the source nor `.chezmoiignore`. Three failure
modes followed from working on this repository with an agent:

- A file created directly in `~/.claude` works on one machine and is one apply
  away from deletion. A skill sat uncaptured in the target from 2026-06-22
  until a guard's test matrix found it (#316).
- Edits made to a target file are overwritten by the next apply, and
  `chezmoi re-add` silently skips templates.
- Uncommitted work in the main checkout switches off the session-start
  fast-forward, which only runs on a clean tree, so the checkout goes stale.

Working in a git worktree solves the third but introduces a fourth: the chezmoi
source directory is pinned in `~/.config/chezmoi/chezmoi.toml`, so a bare
`chezmoi apply` from a worktree applies the main checkout's content and exits 0.

Derived from commits 3d0f209 (#265, 2026-06-25), #315 (2026-07-11), 51e54e5
(#397, 2026-09-04), 9b9da1d (#558, 2026-11-03) and 290a898 (#544).

## Decision

Changes to this repository are made in a Claude Code worktree, and hooks enforce
the chezmoi invariants that an exit code does not report.

- **Worktree first.** A change task enters a worktree before its first edit.
  `worktree.baseRef` is `fresh` (Claude Code's default; no tracked file sets
  it), so the branch starts from `origin/main`.
  Reading, answering questions and `chezmoi diff`/`status` need no worktree.
- **`--source` through the task runner.** `just apply|diff|status` and the
  matching `mise run` tasks pass `--source "$(git rev-parse --show-toplevel)"`.
- **Named targets from a worktree.** A full apply from a worktree rewrites
  `sourceDir` in `chezmoi.toml` to the worktree path. Worktrees apply named
  targets; the full apply runs from the main checkout after the merge.
- **Guard hooks**, all under `exact_dot_claude/hooks/`:

  | Hook | Fires on | Action |
  |---|---|---|
  | `chezmoi-exact-guard.sh` | an apply that would delete from an `exact_` dir | blocks, except a file chezmoi wrote and nobody edited since |
  | `chezmoi-drift-guard.sh` | an apply over uncaptured target edits | warns and names the capture recipes |
  | `chezmoi-target-guard.sh` | a write into `~/.claude/rules`, `skills` or `CLAUDE.md` | blocks and names the source path |
  | `chezmoi-worktree-source-guard.sh` | a bare chezmoi command inside a worktree | warns |

- **Freshness.** A SessionStart script fast-forwards this checkout when it is
  clean and then applies `~/.claude` behind the status-then-diff pre-flight.

Deletions block and overwrites warn because a deletion from an `exact_`
directory is almost never intended, while overwriting a target edit often is.

## Consequences

### Positive

- The main checkout stays clean, so the session-start fast-forward keeps
  running.
- The silent outcomes (wrong source applied, target edit lost, stray file
  deleted) each produce a message at the point of the command.
- Rules deleted from source are removed from `~/.claude/rules` on the next
  apply, because the rules directory is itself `exact_`.

### Negative

- Four hooks run on Bash and edit tool calls, each adding latency and a
  possible false positive.
- The `sourceDir` hazard is documented but not removed. A fix in the template
  (rendering the canonical path) would remove it.
- The hooks parse shell command text, which cannot cover every way a command
  can write a file.

## Options Considered

### Option 1: Worktrees plus PreToolUse guards (chosen)

**Pros:** checks run only when a relevant command runs; the agent cannot skip
them. **Cons:** command-text parsing is approximate.

### Option 2: Work in the main checkout and rely on documentation

**Pros:** no hooks; `chezmoi apply` needs no flag. **Cons:** dirty trees
disable the fast-forward, and the documented hazards depend on being
remembered. **Rejected because:** the uncaptured skill and the lost target
edits both happened while the guidance was already written down.

### Option 3: Check for drift in pre-commit or at session start

**Pros:** simpler wiring. **Cons:** pre-commit fires on source commits, while
drift lives in target files; a session-start check pays for `chezmoi status` in
every session. **Rejected because:** neither fires at the apply, which is where
the loss happens.

## Related ADRs

- [ADR-0001: Chezmoi exact_ Directory Strategy](0001-chezmoi-exact-directory-strategy.md) — this ADR adds the guards that make that strategy safe to operate.
