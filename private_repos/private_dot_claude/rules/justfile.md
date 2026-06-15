---
paths:
  - "**/justfile"
  - "**/*.just"
---
# Justfile Standards — Portfolio Conventions

Generic justfile authoring (structure, attributes, shebang recipes, parameters,
naming) is covered by the `tools-plugin:justfile-expert` skill and audited by
`configure-plugin:configure-justfile` — consult those rather than restating
syntax here. This rule holds only the conventions specific to this repos/
portfolio layout.

## Portfolio-Level Conventions

The root `repos/justfile` operates across all repositories using dynamic
discovery (`find . -maxdepth 3 -name .git`). Subdirectory justfiles handle
org/personal-specific recipes (`ForumViriumHelsinki/justfile`,
`laurigates/justfile`).

### Module Integration

When a subdirectory has its own justfile, register it as a module in the
parent — at every level, not just the root:

```just
mod name 'subdirectory'
# Invoke: just name::recipe
```

The root registers `fvh`, `laurigates`, and `dotgithub`; org/personal justfiles
register their own children (e.g. `infrastructure/`, `claude-plugins/`).

### Bash 5 Prerequisite

macOS ships bash 3.2 which lacks `declare -A`, `readarray`/`mapfile`, and other
modern features used by the portfolio recipes. Install bash 5+ via
`brew install bash` and ensure `/opt/homebrew/bin` is in PATH before `/bin`.
Document this in each justfile's header comment.

### Repo-Iteration Recipe Patterns

Recipes that sweep many repos follow the `pull-clean` house style:

- **Counters survive the loop** — `declare -i` + process substitution
  (`done < <(…)`), never `find | while` (subshell discards counters)
- **No silent skips** — every skipped repo prints a reason
  (`skip: dirty`, `skip: detached HEAD`, `skip: no upstream`)
- **Guard git substitutions** — `$(git … || echo "?")` so one broken repo
  (unborn HEAD, corrupt worktree) cannot abort the sweep under
  `set -euo pipefail`
- **Summary line** at the end with tallies
- **`[confirm]`** on bulk-mutating sweeps (pull/checkout/fetch across repos)
- Aligned `printf "%-NNs"` output; report success/failure inline
  (`ok` / `FAILED`)
