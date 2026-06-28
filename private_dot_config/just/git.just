# Git branch hygiene — recipes for auditing and pruning local branches.
#
# Imported by BOTH the dotfiles repo justfile and the global
# ~/.config/just/justfile, so `just branch-audit` (in-repo) and
# `just -g branch-audit` (from ANY repo) resolve the same recipe.
#
# chezmoi applies this to ~/.config/just/git.just. Edit here, then `chezmoi apply`.

# Classify local branches as MERGED (safe to delete) or REVIEW (keep). Read-only.
#
# Two independent "definitely merged" signals, checked in order:
#   1. merge-tree no-op — merging the branch into the default branch changes
#      nothing, so its content is already present (survives squash-merge AND
#      later drift on the same files, which `git branch --merged` misses).
#   2. a MERGED pull request exists for the branch's head ref (GitHub is
#      authoritative; the squash landed the work even if main drifted since).
# Anything matching neither is REVIEW: genuine unmerged work or scratch.
# Prints a table and a copy-paste `git branch -D ...` for the MERGED set.
[group: "git"]
branch-audit:
    #!/usr/bin/env bash
    set -euo pipefail

    # Default branch: origin/HEAD if known, else main/master fallback.
    base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || true)
    [ -z "${base:-}" ] && base=$(git rev-parse --verify --quiet main >/dev/null 2>&1 && echo main || echo master)
    base_tree=$(git rev-parse "$base^{tree}")
    protected="^(${base}|master|develop|staging|production)$"

    # Pull PR head->state once (best effort; empty without gh / remote).
    prs=$(mktemp)
    gh pr list --state all --limit 500 --json number,headRefName,state \
      --jq '.[] | [.headRefName, "#"+(.number|tostring), .state] | @tsv' >"$prs" 2>/dev/null || true

    merged=()
    printf '%-44s %-9s %-16s %s\n' BRANCH VERDICT PR REASON
    printf '%.0s-' {1..90}; echo
    for b in $(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -vE "$protected"); do
      pr=$(awk -F'\t' -v b="$b" '$1==b{p=$2" "$3} END{print p}' "$prs")
      mt=$(git merge-tree --write-tree "$base" "$b" 2>/dev/null) && rc=0 || rc=$?
      if [ "${rc:-1}" -eq 0 ] && [ "$mt" = "$base_tree" ]; then
        printf '%-44s %-9s %-16s %s\n' "$b" MERGED "${pr:-—}" "contained in $base"; merged+=("$b")
      elif printf '%s' "${pr:-}" | grep -q ' MERGED$'; then
        printf '%-44s %-9s %-16s %s\n' "$b" MERGED "$pr" "PR merged (base drifted since)"; merged+=("$b")
      else
        printf '%-44s %-9s %-16s %s\n' "$b" REVIEW "${pr:-—}" "not contained, no merged PR"
      fi
    done
    rm -f "$prs"

    if [ ${#merged[@]} -gt 0 ]; then
      echo
      echo "# ${#merged[@]} branch(es) safe to delete:"
      echo "git branch -D ${merged[*]}"
    fi
