#!/usr/bin/env bash
# Behaviour tests for the `branch-audit` recipe in private_dot_config/just/git.just.
#
# Builds a throwaway origin + clone, stubs `gh` on PATH, and asserts the verdict
# each branch shape gets. The cases pin the rule that a merged PR only proves a
# branch landed when the branch tip is inside that PR: the repo-cleanup routine
# deletes MERGED rows with `git branch -D`, so a tip past the PR head must never
# read MERGED.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
JUSTFILE="$ROOT/private_dot_config/just/git.just"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

fail=0
pass() { printf 'ok   %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; fail=1; }

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
g() { git -C "$T/work" "$@"; }
commit() { printf '%s\n' "$2" >>"$T/work/$1"; g add "$1"; g commit -qm "$3"; }

git init -q --bare -b main "$T/origin.git"
git clone -q "$T/origin.git" "$T/work" 2>/dev/null
commit base.txt base "init"
g push -q origin main

# landed: fast-forwarded into main.
g switch -qc landed; commit a.txt a "landed work"; g switch -q main; g merge -q --ff-only landed

# squashed: two commits squash-merged; PR head == tip.
g switch -qc squashed; commit s.txt s1 "s1"; commit s.txt s2 "s2"; SQ_TIP=$(g rev-parse squashed)
g switch -q main; g merge -q --squash squashed; g commit -qm "squashed (#1)"
# main drifts over the same file, so merge-tree and git cherry cannot prove it.
commit s.txt s3 "drift s"

# past-head: PR #2 merged at its first commit; the branch kept going.
g switch -qc past-head; commit p.txt p1 "p1"; commit p.txt p1b "p1b"; PH_PR_HEAD=$(g rev-parse past-head)
g switch -q main; g merge -q --squash past-head; g commit -qm "past-head (#2)"
g switch -q past-head; commit p.txt p2 "p2 after merge"

# renamed: local fix-9 tracked origin/feat/nine, which was deleted after PR #3 merged.
g switch -q main; g switch -qc fix-9; commit r.txt r1 "r1"; commit r.txt r2 "r2"; RN_TIP=$(g rev-parse fix-9)
g push -q origin fix-9:feat/nine; g branch -q --set-upstream-to=origin/feat/nine
g switch -q main; g merge -q --squash fix-9; g commit -qm "nine (#3)"; commit r.txt r3 "drift r"
g push -q origin --delete feat/nine; g fetch -q --prune

# pr-12: a fetched PR head under a local name; PR #12 merged by commit lookup only.
g switch -qc pr-12; commit c.txt c1 "c1"; commit c.txt c2 "c2"; BC_TIP=$(g rev-parse pr-12)
g switch -q main; g merge -q --squash pr-12; g commit -qm "twelve (#12)"; commit c.txt c3 "drift c"

# pushed: on the remote, never merged, no PR.
g switch -qc pushed; commit o.txt o "pushed work"; g push -q origin pushed

# local: never left this machine.
g switch -q main; g switch -qc local; commit l.txt l "local work"

g switch -q main; g push -q origin main; g fetch -q

# gh stub: pr list, repo view, commits/{sha}/pulls, pulls/{n}/commits.
mkdir -p "$T/bin"
cat >"$T/prs.tsv" <<EOF
squashed	#1	MERGED	$SQ_TIP
past-head	#2	MERGED	$PH_PR_HEAD
feat/nine	#3	MERGED	$RN_TIP
EOF
printf '%s\t12\n' "$BC_TIP" >"$T/commit-pulls.tsv"
cat >"$T/bin/gh" <<EOF
#!/usr/bin/env bash
case "\$1 \$2" in
  "pr list") cat "$T/prs.tsv" ;;
  "repo view") echo o/r ;;
  "api "*)
    case "\$2" in
      repos/o/r/commits/*/pulls) sha=\${2#repos/o/r/commits/}; sha=\${sha%/pulls}; awk -F'\t' -v s="\$sha" '\$1==s{print \$2}' "$T/commit-pulls.tsv" ;;
      repos/o/r/pulls/*/commits) : ;;
      *) exit 1 ;;
    esac ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$T/bin/gh"
export PATH="$T/bin:$PATH"
[ "$(command -v gh)" = "$T/bin/gh" ] || { echo "FAIL gh stub not first on PATH"; exit 1; }

out=$(cd "$T/work" && just --justfile "$JUSTFILE" --working-directory "$T/work" branch-audit 2>&1) || { echo "$out"; bad "recipe exited non-zero"; }

verdict() { awk -v b="$1" '$1==b {print $2}' <<<"$out"; }
expect() {
  local b=$1 want=$2 got
  got=$(verdict "$b")
  if [ "$got" = "$want" ]; then pass "$b -> $want"; else bad "$b -> want $want, got '${got:-<missing>}'"; fi
}

expect landed MERGED
expect squashed MERGED
expect past-head REVIEW
expect fix-9 MERGED
expect pr-12 MERGED
expect pushed ONREMOTE
expect local REVIEW

# The tip column lets a deletion be undone with `git branch <name> <sha>`.
tip=$(awk '$1=="local" {print $3}' <<<"$out")
if [ "$tip" = "$(g rev-parse local)" ]; then pass "TIP column holds the full tip SHA"; else bad "TIP column: got '$tip'"; fi

# The paste line names MERGED branches only.
del=$(grep '^git branch -D ' <<<"$out" || true)
for b in landed squashed fix-9 pr-12; do
  grep -qw -- "$b" <<<"$del" && pass "-D line has $b" || bad "-D line lacks $b"
done
for b in past-head pushed local; do
  grep -qw -- "$b" <<<"$del" && bad "-D line has $b" || pass "-D line omits $b"
done

[ "$fail" -eq 0 ] || { printf '\n%s\n' "$out"; exit 1; }
echo "all branch-audit tests passed"
