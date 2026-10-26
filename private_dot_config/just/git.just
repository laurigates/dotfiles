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
#      the merge (squash or rebase) landed the work even if the default branch drifted since.
#   2. `git cherry` reports no '+' commits — every commit has a patch-equivalent
#      already upstream. Survives squash-merge, rebase-merge (new SHAs) AND cherry-pick, and unlike
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
      if [ "$crc" -eq 0 ] && ! printf '%s\n' "$cout" | grep -c '^+' >/dev/null; then
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

# Classify linked worktrees as MERGED / REVIEW / DIRTY / IN-USE / PRUNE. Read-only.
#
# With no argument, audits the current repo. With a directory, audits every
# repo found up to three levels below it (`just -g worktree-audit ~/repos`).
# Repos are discovered by their `.git` DIRECTORY and worktrees read from
# `git worktree list`, so a worktree is found wherever it was created.
#
# LOC is `stray` for a worktree outside `<repo>/.claude/worktrees/` — the
# sibling-dir `git worktree add ../<name>` pattern that littered ~/repos with
# 41 of them by 2026-10.
#
# VERDICT, first match wins:
#   PRUNE  — the directory is gone; only the metadata is left.
#   IN-USE — a running process has its cwd inside it (lsof).
#   DIRTY  — uncommitted or untracked files; removing them needs --force.
#   MERGED — the branch-audit signals: a MERGED PR whose head (or one of its
#            commits) is the worktree HEAD, else `git cherry` with no '+',
#            else a merge-tree no-op. A merged PR with commits past its head is
#            REVIEW: those commits did not ride the merge. A detached HEAD
#            (workflow/agent worktrees) is matched by commit via
#            `repos/{nwo}/commits/{sha}/pulls`, which finds the PR whatever its
#            branch was called.
#   REVIEW — none of the above.
# Compares against origin/<default> as last fetched; fetch first for a fresh read.
# Prints copy-paste `git worktree remove` commands for MERGED rows only.
#
# Audit linked worktrees (stray + merged); prints removal commands, read-only.
[group: "git"]
worktree-audit root="":
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -n "{{root}}" ]; then
      mapfile -t repos < <(find "{{root}}" -mindepth 1 -maxdepth 3 -type d -name .git -prune 2>/dev/null \
        | sed 's#/\.git$##' | sort)
    else
      repos=("$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")
    fi

    # cwds of every running process, for the IN-USE check.
    cwds=$(lsof -a -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | sort -u || true)

    removes=(); prunes=()
    printf '%-58s %-5s %-8s %-10s %s\n' WORKTREE LOC VERDICT PR DETAIL
    printf '%.0s-' {1..110}; echo
    for repo in "${repos[@]}"; do
      wts=$(git -C "$repo" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | tail -n +2)
      [ -z "$wts" ] && continue

      base=$(git -C "$repo" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
      [ -z "$base" ] && base=$(git -C "$repo" rev-parse --verify --quiet origin/main >/dev/null && echo origin/main || echo origin/master)
      base_tree=$(git -C "$repo" rev-parse "$base^{tree}" 2>/dev/null || true)

      # Same no-small-limit reasoning as branch-audit: a capped window reads as "no PR".
      prs=$(cd "$repo" && gh pr list --state all --limit 10000 --json number,headRefName,state,headRefOid \
        --jq '.[] | [.headRefName, (.number|tostring), .state, .headRefOid] | @tsv' 2>/dev/null || true)
      nwo=$(cd "$repo" && gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)

      while IFS= read -r wt; do
        name=${wt#"$HOME"/}
        case "$wt" in "$repo"/.claude/worktrees/*) loc=ok ;; *) loc=stray ;; esac
        row() { printf '%-58s %-5s %-8s %-10s %s\n' "$name" "$loc" "$1" "$2" "$3"; }

        if [ ! -d "$wt" ]; then
          row PRUNE — "directory missing"; prunes+=("$repo"); continue
        fi
        if printf '%s\n' "$cwds" | awk -v p="$wt" '$0==p || index($0, p"/")==1 {f=1} END {exit !f}'; then
          row IN-USE — "a process has its cwd here"; continue
        fi

        head=$(git -C "$wt" rev-parse HEAD)
        br=$(git -C "$wt" symbolic-ref --quiet --short HEAD || echo "")
        detail_br=${br:-detached@${head:0:8}}
        dirty=$(git -C "$wt" status --porcelain | wc -l | tr -d ' ')
        if [ "$dirty" -gt 0 ]; then
          row DIRTY — "$detail_br, $dirty uncommitted/untracked path(s)"; continue
        fi

        pr="—"; verdict=""; why=""; state=""
        if [ -n "$br" ]; then
          line=$(printf '%s\n' "$prs" | awk -F'\t' -v b="$br" '$1==b && $3=="MERGED" && !l {l=$0} END {print l}')
          [ -z "$line" ] && line=$(printf '%s\n' "$prs" | awk -F'\t' -v b="$br" '$1==b && !l {l=$0} END {print l}')
          if [ -n "$line" ]; then
            IFS=$'\t' read -r _ num state prhead <<<"$line"
            pr="#$num"
            if [ "$state" = MERGED ]; then
              if [ "$head" = "$prhead" ] || git -C "$wt" merge-base --is-ancestor "$head" "$prhead" 2>/dev/null \
                 || { [ -n "$nwo" ] && gh api "repos/$nwo/pulls/$num/commits" --paginate --jq '.[].sha' 2>/dev/null | grep -cx "$head" >/dev/null; }; then
                verdict=MERGED; why="$br, PR merged at this HEAD"
              fi
            else
              pr="#$num:$state"
            fi
          fi
        fi

        # A detached or renamed HEAD has no head-ref PR; ask GitHub which PRs
        # contain the commit itself. Errors (commit never pushed) stay REVIEW.
        if [ -z "$verdict" ] && [ -n "$nwo" ]; then
          # On an HTTP error gh still prints the error body to stdout, so a
          # failed call must clear $via and only a bare PR number counts.
          via=$(gh api "repos/$nwo/commits/$head/pulls" --jq '[.[] | select(.merged_at != null) | .number][0] // empty' 2>/dev/null) || via=""
          [[ "$via" =~ ^[0-9]+$ ]] && { verdict=MERGED; pr="#$via"; why="$detail_br, HEAD is a commit of merged PR #$via"; }
        fi

        if [ -z "$verdict" ]; then
          crc=0; cout=$(git -C "$wt" cherry "$base" HEAD 2>/dev/null) || crc=$?
          if [ "$crc" -eq 0 ] && ! printf '%s\n' "$cout" | grep -c '^+' >/dev/null; then
            verdict=MERGED; why="$detail_br, patch-equivalent in $base"
          else
            mt=$(git -C "$wt" merge-tree --write-tree "$base" HEAD 2>/dev/null) && rc=0 || rc=$?
            if [ "$rc" -eq 0 ] && [ "$mt" = "$base_tree" ]; then
              verdict=MERGED; why="$detail_br, contained in $base"
            else
              n=$(printf '%s\n' "$cout" | grep -c '^+' || true)
              verdict=REVIEW; why="$detail_br, $n commit(s) not in $base"
              [ "${state:-}" = MERGED ] && why="$why (past the merged PR head)"
            fi
          fi
        fi

        row "$verdict" "$pr" "$why"
        [ "$verdict" = MERGED ] && removes+=("git -C '$repo' worktree remove '$wt'")
      done <<<"$wts"
    done

    if [ ${#removes[@]} -gt 0 ]; then
      echo; echo "# ${#removes[@]} merged worktree(s) safe to remove (branches are kept):"
      printf '%s\n' "${removes[@]}"
    fi
    if [ ${#prunes[@]} -gt 0 ]; then
      echo; echo "# stale worktree metadata:"
      printf '%s\n' "${prunes[@]}" | sort -u | sed "s#^#git -C '#; s#\$#' worktree prune#"
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

# Classify open Renovate PRs into SAFE vs HOLD buckets and print merge lines. Read-only.
#
# Every PR is fetched with `gh pr view` (the search index lags, so search is only
# used to enumerate). SAFE means all of: mergeable and not BLOCKED, no failing or
# pending checks, `renovate/stability-days` passed, at least one real CI check
# passed, and every row of the Renovate update table is patch/minor/digest/pin/
# lockfile. A minor bump on a 0.x version counts as major (semver), and language
# runtime bumps (`python to 3.15`, ...) are held however small. "Configure Renovate"
# onboarding PRs are SAFE with no checks: no build reads renovate.json.
#
# The update table's columns differ between Renovate configs, so it is parsed by
# header (`Update`, `Change`), never by position.
#
# SAFE output is a list of literal `gh pr merge` lines; nothing is merged. The
# external-PR merge guard refuses `$var` selectors, so run them as written. SAFE is
# mechanical: a minor chart bump on a platform component (ArgoCD, Envoy Gateway,
# cert-manager, external-dns) still needs a human read before it ships.
[group: "git"]
renovate-triage owners="ForumViriumHelsinki laurigates" authors="app/fvh-renovate-bot app/laurigates-renovate" jobs="8":
    #!/usr/bin/env -S python3 -I
    import collections, json, re, subprocess, sys
    from concurrent.futures import ThreadPoolExecutor

    OWNERS = "{{owners}}".split()
    AUTHORS = "{{authors}}".split()
    BAD = {"FAILURE", "ERROR", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE"}
    WAIT = {"PENDING", "IN_PROGRESS", "QUEUED", "EXPECTED", ""}
    RUNTIME = re.compile(r"update (dependency )?(python|node|nodejs|golang|go|ruby|java)( docker tag)? to", re.I)
    FIELDS = "number,title,isDraft,mergeStateStatus,mergeable,body,statusCheckRollup"

    def gh(*args):
        return json.loads(subprocess.run(["gh", *args], check=True, capture_output=True, text=True).stdout)

    def change_type(change):
        sides = re.split(r"→|->", change)
        if len(sides) < 2:
            return "unknown"
        a, b = (re.findall(r"(\d+)(?:\.(\d+))?", s) for s in sides[:2])
        if not a or not b:
            return "digest" if re.search(r"\b[0-9a-f]{7,}\b", change) else "unknown"
        (amaj, amin), (bmaj, bmin) = a[0], b[0]
        if amaj != bmaj or (amaj == "0" and (amin or "0") != (bmin or "0")):
            return "major"
        return "minor" if (amin or "0") != (bmin or "0") else "patch"

    def update_types(body):
        lines = (body or "").splitlines()
        cells = lambda l: [c.strip() for c in l.strip().strip("|").split("|")]
        for i, line in enumerate(lines[:-1]):
            if line.startswith("|") and re.fullmatch(r"\|[\s\-:|]+\|", lines[i + 1].strip()):
                hdr = [h.lower() for h in cells(line)]
                ui = hdr.index("update") if "update" in hdr else None
                ci = hdr.index("change") if "change" in hdr else None
                types = []
                for row in lines[i + 2:]:
                    if not row.startswith("|"):
                        break
                    c = cells(row)
                    t = change_type(c[ci]) if ci is not None and ci < len(c) else "unknown"
                    declared = c[ui].lower() if ui is not None and ui < len(c) else ""
                    # Computed 0.x "major" wins over a declared "minor"; a declared
                    # value fills in when the Change cell cannot be parsed.
                    if declared == "major" or (t == "unknown" and declared):
                        t = declared
                    types.append(t)
                return types
        return []

    def verdict(d):
        title = d["title"]
        types = set(update_types(d["body"]))
        checks = [(c.get("name") or c.get("context") or "", (c.get("conclusion") or c.get("state") or "").upper())
                  for c in d["statusCheckRollup"] or []]
        real = [(n, s) for n, s in checks if n != "renovate/stability-days" and not n.startswith("conventional-commits")]
        stability = [s for n, s in checks if n == "renovate/stability-days"]
        if d["isDraft"]: return "HOLD-draft"
        if d["mergeable"] == "CONFLICTING" or d["mergeStateStatus"] == "DIRTY": return "HOLD-conflict"
        if d["mergeStateStatus"] == "BLOCKED": return "HOLD-blocked"
        if any(s in BAD for _, s in real): return "HOLD-failing"
        if any(s in WAIT for _, s in real): return "HOLD-pending"
        if stability and stability[0] != "SUCCESS": return "HOLD-stability"
        if not types and re.search(r"configure renovate", title, re.I): return "SAFE"
        if RUNTIME.search(title): return "HOLD-runtime"
        if not types or types & {"major", "unknown"}: return "HOLD-major"
        if not any(s == "SUCCESS" for _, s in real): return "HOLD-nochecks"
        return "SAFE"

    prs = sorted({(p["repository"]["nameWithOwner"], p["number"])
                  for o in OWNERS for a in AUTHORS
                  for p in gh("search", "prs", "--owner", o, "--author", a, "--state", "open",
                              "--limit", "1000", "--json", "repository,number")})
    if not prs:
        print("No open Renovate PRs for", " ".join(AUTHORS), "under", " ".join(OWNERS))
        sys.exit(0)

    def fetch(pr):
        repo, n = pr
        try:
            return repo, gh("pr", "view", str(n), "-R", repo, "--json", FIELDS)
        except subprocess.CalledProcessError as e:
            print(f"warn: {repo}#{n}: {e.stderr.strip()}", file=sys.stderr)
            return repo, None

    with ThreadPoolExecutor(max_workers=int("{{jobs}}")) as pool:
        rows = [(repo, d, verdict(d)) for repo, d in pool.map(fetch, prs) if d]

    counts = collections.Counter(v for _, _, v in rows)
    print(f"{len(rows)} open Renovate PRs across {len({r for r, _, _ in rows})} repos\n")
    for v, n in counts.most_common():
        print(f"{n:5}  {v}")
    for v in [v for v, _ in counts.most_common() if v != "SAFE"]:
        per_repo = collections.Counter(r for r, _, vv in rows if vv == v)
        print(f"\n== {v}: " + ", ".join(f"{r}({n})" for r, n in per_repo.most_common()))
    safe = [(r, d) for r, d, v in rows if v == "SAFE"]
    if safe:
        print("\n== SAFE (review titles, then run each line as written)")
        print("#   SAFE is mechanical: a chart bump on a platform component (ArgoCD, gateway,")
        print("#   cert-manager, external-dns, ingress) deploys to production on merge. Read it first.")
        for r, d in safe:
            print(f"#   {r}#{d['number']}  {d['title']}")
        for r, d in safe:
            print(f"gh pr merge {d['number']} -R {r} --squash --delete-branch")
        print("\n# Sibling PRs that touch one lockfile can conflict after the first merges;")
        print("# confirm with `gh pr view <n> -R <repo> --json state`, not search (index lags).")
