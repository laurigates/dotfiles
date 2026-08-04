# Git branch hygiene — recipes for auditing and pruning local branches.
#
# Imported by BOTH the dotfiles repo justfile and the global
# ~/.config/just/justfile, so `just branch-audit` (in-repo) and
# `just -g branch-audit` (from ANY repo) resolve the same recipe.
#
# chezmoi applies this to ~/.config/just/git.just. Edit here, then `chezmoi apply`.

# Classify local branches as MERGED (safe to delete) or REVIEW (keep). Read-only.
#
# Three "definitely merged" signals, checked in ORDER OF AUTHORITY — the order
# matters, see ~/.claude/rules/pr-merge-hazards.md #1:
#   1. a MERGED pull request for the branch's head ref. GitHub is authoritative;
#      the squash landed the work even if the default branch drifted since.
#   2. `git cherry` reports no '+' commits — every commit has a patch-equivalent
#      already upstream. Survives squash-merge AND cherry-pick, and unlike
#      merge-tree it does NOT care that the base drifted over the same files.
#   3. merge-tree no-op — merging the branch changes nothing. Positive proof of
#      containment only: a NON-match proves nothing, because once the base moves
#      on over the same files the trees differ for work that fully landed.
# Anything matching none is REVIEW: genuine unmerged work or scratch.
# Prints a table and a copy-paste `git branch -D ...` for the MERGED set.
#
# Both #1 and #2 were added 2026-08-04 after this recipe misclassified 174 of
# 191 REVIEW rows (91%) on laurigates/claude-plugins: merge-tree alone lost 132
# to base drift, and the PR window was capped at 500 on a repo with 1881 PRs, so
# every older merged PR read as "no merged PR".
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
    # NO SMALL --limit: the cap is silent and one-directional — a branch whose
    # merged PR falls outside the window reads as "no merged PR" and lands in
    # REVIEW. gh paginates internally, so this costs a few seconds on big repos
    # and buys a correct answer.
    prs=$(mktemp)
    gh pr list --state all --limit 10000 --json number,headRefName,state \
      --jq '.[] | [.headRefName, "#"+(.number|tostring), .state] | @tsv' >"$prs" 2>/dev/null || true

    merged=()
    printf '%-44s %-9s %-16s %s\n' BRANCH VERDICT PR REASON
    printf '%.0s-' {1..90}; echo
    for b in $(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -vE "$protected"); do
      pr=$(awk -F'\t' -v b="$b" '$1==b{p=$2" "$3} END{print p}' "$prs")

      # 1. A MERGED PR is authoritative — check it before any git-side test.
      if printf '%s' "${pr:-}" | grep -q ' MERGED$'; then
        printf '%-44s %-9s %-16s %s\n' "$b" MERGED "$pr" "PR merged (authoritative)"; merged+=("$b"); continue
      fi

      # 2. git cherry: '+' marks a commit with no patch-equivalent upstream.
      #    A non-zero exit is NOT containment (no merge base, bad ref), so
      #    require rc 0 before reading an empty '+' set as "landed".
      crc=0; cout=$(git cherry "$base" "$b" 2>/dev/null) || crc=$?
      if [ "$crc" -eq 0 ] && ! printf '%s\n' "$cout" | grep -q '^+'; then
        printf '%-44s %-9s %-16s %s\n' "$b" MERGED "${pr:-—}" "patch-equivalent in $base"; merged+=("$b"); continue
      fi

      # 3. merge-tree no-op — positive proof only; a non-match proves nothing.
      mt=$(git merge-tree --write-tree "$base" "$b" 2>/dev/null) && rc=0 || rc=$?
      if [ "${rc:-1}" -eq 0 ] && [ "$mt" = "$base_tree" ]; then
        printf '%-44s %-9s %-16s %s\n' "$b" MERGED "${pr:-—}" "contained in $base"; merged+=("$b"); continue
      fi

      printf '%-44s %-9s %-16s %s\n' "$b" REVIEW "${pr:-—}" "no merged PR, not patch-equivalent"
    done
    rm -f "$prs"

    if [ ${#merged[@]} -gt 0 ]; then
      echo
      echo "# ${#merged[@]} branch(es) safe to delete:"
      echo "git branch -D ${merged[*]}"
    fi

# List your own open PRs blocked on YOU — changes requested or CI failing. Read-only.
#
# Two independent GitHub searches, unioned by URL:
#   1. --review=changes_requested — a reviewer asked for changes.
#   2. --checks=failure           — the PR's checks are failing.
# A PR matching both shows both reasons. Empty result prints a clean line
# and still exits 0 (safe in pipelines / autonomous sweeps).
[group: "git"]
pr-todo:
    #!/usr/bin/env bash
    set -euo pipefail

    changes=$(gh search prs --author=@me --state=open --review=changes_requested \
      --json repository,number,title,url \
      --jq '.[] | [.url, .repository.nameWithOwner, "#"+(.number|tostring), "changes-requested", .title] | @tsv' 2>/dev/null || true)
    failing=$(gh search prs --author=@me --state=open --checks=failure \
      --json repository,number,title,url \
      --jq '.[] | [.url, .repository.nameWithOwner, "#"+(.number|tostring), "ci-failing", .title] | @tsv' 2>/dev/null || true)

    # Union by URL; a PR in both searches gets both reasons joined with "+".
    rows=$(printf '%s\n%s\n' "$changes" "$failing" | grep -v '^$' | awk -F'\t' '
      { url=$1; repo[$1]=$2; num[$1]=$3; title[$1]=$5;
        reason[$1] = ($1 in reason) ? reason[$1]"+"$4 : $4 }
      END { for (u in repo) printf "%s\t%s\t%s\t%s\t%s\n", repo[u], num[u], reason[u], title[u], u }
    ' | sort)

    if [ -z "$rows" ]; then
      echo "Nothing blocked on you — no open PRs with changes requested or failing CI."
      exit 0
    fi

    printf '%-40s %-7s %-24s %s\n' REPO PR REASON TITLE
    printf '%.0s-' {1..100}; echo
    printf '%s\n' "$rows" | while IFS=$'\t' read -r repo num reason title url; do
      printf '%-40s %-7s %-24s %s\n' "$repo" "$num" "$reason" "$title"
    done
