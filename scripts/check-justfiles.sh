#!/usr/bin/env bash
# Validate that every top-level justfile still PARSES and EVALUATES.
#
# `just --dump` parses the justfile and evaluates all variables (without running
# any recipe), so it fails on syntax errors AND on undefined-variable references
# across `import`ed fragments — exactly the failure that broke completion in
# PR #288 (a `{{claude_model}}` reference in the shared `plugins.just` was
# defined in only one of its two importers, so `just` errored in the other,
# silently downgrading the grouped `_just` fzf-tab completer to flat).
#
# Only justfile ROOTS are validated — imported fragments (plugins.just,
# claude.just, git.just, nvim.just) are not standalone justfiles. Each root
# pulls its fragments in via `import`, so validating the roots covers them.
set -euo pipefail

if ! command -v just >/dev/null 2>&1; then
  echo "check-justfiles: 'just' not installed — skipping." >&2
  exit 0
fi

# justfile roots (importers). Fragments are validated transitively via imports.
roots=(
  justfile                          # dotfiles repo root
  private_dot_config/just/justfile  # global justfile source (~/.config/just/justfile)
)

status=0
for f in "${roots[@]}"; do
  [ -f "$f" ] || continue
  if ! err="$(just --justfile "$f" --dump >/dev/null 2>&1 || just --justfile "$f" --dump 2>&1 >/dev/null)"; then
    echo "check-justfiles: FAILED to evaluate $f" >&2
    printf '%s\n' "$err" >&2
    status=1
  fi
done

exit "$status"
