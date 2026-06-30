#!/bin/bash
# Per-location git identity via includeIf.
#
# Default (global) identity is FVH work; commits in personal locations override
# to the personal identity in ~/.config/git/personal.inc. git evaluates the
# includeIf directives by repo location at runtime, so the right author is
# stamped automatically with no per-repo `git config` needed.
#
# This is a run_onchange script (not the heavy run_once initial-setup): editing
# it re-applies just these settings on the next `chezmoi apply`. `git config`
# is idempotent, so re-running only re-asserts the values.
set -euo pipefail

PERSONAL="$HOME/.config/git/personal.inc"

# Default identity: FVH work (already public in this repo's commit history).
git config --global user.name "Lauri Gates"
git config --global user.email "lauri.gates@forumvirium.fi"

# Personal-location overrides. Trailing slash => matches all repos *under* the
# path; the umbrella ~/repos repo is matched by its exact .git dir.
git config --global "includeIf.gitdir:~/repos/.git.path"                 "$PERSONAL"
git config --global "includeIf.gitdir:~/repos/laurigates/.path"          "$PERSONAL"
git config --global "includeIf.gitdir:~/.local/share/chezmoi/.path"      "$PERSONAL"
git config --global "includeIf.gitdir:~/Documents/LakuVault/.path"       "$PERSONAL"
