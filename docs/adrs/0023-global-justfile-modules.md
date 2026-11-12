---
id: ADR-0023
status: Accepted
created: 2026-11-11
modified: 2026-11-11
deciders: "Lauri Gates"
domain: task-runner
relates-to: [ADR-0012]
---

# ADR-0023: Global Justfile Built from Shared Modules

## Context

ADR-0012 adopted `just` as this repository's command runner. Some of its
recipes are not about this repository: the `plugins-*` recipes configure Claude
plugins in whichever project they run in, and branch, worktree, PR and Renovate
recipes apply to any checkout. They only worked from inside the dotfiles
repository.

The first attempt at a global justfile wrote `~/.user.justfile` (#261). That
path is not on just's global search path, which is
`$XDG_CONFIG_HOME/just/justfile`, then `~/.config/just/justfile`, `~/justfile`
and `~/.justfile`, so `just -g` never found it (#273).

Derived from commits 018d9ce (#261, 2026-06-25), dfacb88 (#273, 2026-06-28) and
c6976b1 (#308, 2026-07-07).

## Decision

Recipes that are useful outside this repository live in modules under
`private_dot_config/just/*.just`, applied to `~/.config/just/`. Two justfiles
import them:

- the global justfile at `~/.config/just/justfile`, reached from any directory
  with `just -g <recipe>`;
- this repository's root `justfile`, so the same recipes also work as
  `just <recipe>` here.

Each module is the single source for its recipes. Public recipes carry a native
`[group: …]` attribute, in modules and in the root justfile, so `just --list`
groups them consistently. Near-identical recipes share a private helper
recipe: the four bulk `plugins-*` recipes call one `_plugins-foreach`.

The module layout and the relationship with claude-plugins are documented in
[`docs/justfile-architecture.md`](../justfile-architecture.md).

## Consequences

### Positive

- Mechanical work (branch and worktree cleanup, PR and Renovate triage, plugin
  setup) is one command from any project.
- A recipe is defined once and read by both justfiles.
- `just -g --list` shows what exists before anyone rewrites it by hand.

### Negative

- Global recipes run from the applied copy in `~/.config/just/`, so an edit in
  the source has no effect until `chezmoi apply`.
- A global recipe cannot assume it runs inside this repository.
- Recipe names share one namespace across the imported modules.

## Options Considered

### Option 1: Shared modules imported by a global and a repository justfile (chosen)

**Pros:** one definition per recipe; works in and out of the repository.
**Cons:** depends on the applied copy being current.

### Option 2: Keep the recipes only in the repository justfile

**Pros:** nothing to apply. **Cons:** unusable from other projects.
**Rejected because:** running the plugin recipes in another project was the
reason for the change.

### Option 3: Shell functions or scripts on `PATH`

**Pros:** no dependency on just's global lookup. **Cons:** a second place for
task definitions, without `just --list`, groups or recipe completion.
**Rejected because:** ADR-0012 already made just the place where tasks are
defined.

## Related ADRs

- [ADR-0012: Justfile Command Runner](0012-justfile-command-runner.md) — this ADR extends it from one repository to every directory.
