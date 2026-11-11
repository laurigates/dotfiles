#!/usr/bin/env zsh
# Regression test for the gh* wrappers (private_dot_config/zsh/gh-wrappers.zsh):
# what ghm and ghrp merge, with which method, and what they refuse to merge; and
# what ghi hands to Claude.
#
# What is being protected
# -----------------------
# ghm is run as `ghm`, ^a (select all), a (all remaining). The guards behind
# that reflex are the contributor-trust gate, the per-PR merge method, the
# update-and-wait-for-CI step for a PR whose base moved, and the handling of
# draft and conflicting PRs. Each fails quietly when broken: the PR merges.
#
# How the run is shaped
# ---------------------
# The shipped file is sourced as it is, never retyped. Everything it calls
# outside the shell is replaced by a function defined here:
#   gh      answers from per-PR JSON fixtures, and applies the wrapper's own
#           --jq program to them with the real jq, so the jq programs are
#           exercised too. `pr merge`, `pr ready` and `pr update-branch` change
#           the fixture. Fixtures are files because many calls run in $(...).
#           A fixture belongs to one repo: --repo picks it, and without --repo
#           it is $REPO. `search prs` reads every repo's fixtures and applies
#           its --label and --owner filters.
#   fzf     returns the rows named in $FZF_PICK, and saves the table it was
#           shown to $W/fzf.in. An entry is a number (rows starting "#<n>") or
#           "<owner/repo>#<n>" (ghrp rows, which start with the repo).
#   read    a prompt (`read "var?text"`) takes its answer from the queue in
#           $W/answers. With no terminal the builtin would read nothing, and a
#           prompt nobody queued an answer for is logged as UNANSWERED.
#   git, claude, sleep   log the call and do nothing.
# Every stub appends its call to $W/calls; the assertions read that log.
#
# HOME points at an empty directory, so no installed git-plugin is found and
# the merge method comes from the PR's merge:* label.

emulate -R zsh
setopt extended_glob   # on in the interactive shell these functions run in

REPO_ROOT=${0:A:h:h}
SRC=$REPO_ROOT/private_dot_config/zsh/gh-wrappers.zsh

for tool in jq column; do
  (( $+commands[$tool] )) || { print -r -- "SKIP: $tool is not installed"; exit 0 }
done

W=$(mktemp -d)
trap 'rm -rf $W' EXIT
export HOME=$W/home
mkdir -p $HOME

source $SRC || { print -r -- "FAIL: could not source $SRC"; exit 1 }

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

# Start a case: no PRs, no calls, no queued answers, on `main` with no PR.
reset() {
  rm -rf $W/pr $W/issues.json $W/fzf.in
  mkdir -p $W/pr
  : > $W/calls; : > $W/answers; : > $W/out
  ME=lauri REPO=o/r HEAD_BRANCH=main CUR_PR=
  ORGS=(acme)
  FZF_PICK=()
  _GH_ME= _GH_ME_TRIED=0
}

# pr <number> [key=value ...]: write one PR fixture. Keys and defaults below.
#   label   rebase|squash|"" (the merge:* label)   update  ok|uptodate|conflict
#   checks  pass|fail (CI on the updated head)     merge   ok|fail
#   repo    owner/name (default $REPO)             release true = carries the
#                                                  'autorelease: pending' label
# author/bot are given as `gh pr list` and `gh pr view` report them: an App bot
# is login "app/<name>" with is_bot true.
pr() {
  local n=$1; shift
  local -A f=(
    author lauri bot false title "PR $n" label squash draft false base main
    head "feat-$n" sha "sha${n}a" mergeable MERGEABLE mss CLEAN state OPEN
    update ok checks pass merge ok repo $REPO release false
  )
  local kv k v
  for kv in "$@"; do f[${kv%%=*}]=${kv#*=}; done
  local -a args
  for k v in "${(@kv)f}"; do args+=(--arg $k "$v"); done
  local file=$(_pr_file $f[repo] $n)
  mkdir -p ${file:h}
  jq -n --argjson number $n "${args[@]}" '{
    number: $number, title: $title, state: $state, mergedAt: null,
    repository: {nameWithOwner: $repo},
    author: {login: $author, is_bot: ($bot == "true")},
    isDraft: ($draft == "true"), baseRefName: $base, headRefName: $head,
    headRefOid: $sha, mergeable: $mergeable, mergeStateStatus: $mss,
    labels: ((if $label == "" then [] else [{name: ("merge:" + $label)}] end)
             + (if $release == "true" then [{name: "autorelease: pending"}] else [] end)),
    additions: 1, deletions: 1, changedFiles: 1, files: [{path: "README.md"}],
    statusCheckRollup: [], reviewDecision: "", createdAt: "2026-01-01T00:00:00Z",
    _update: $update, _checks: $checks, _merge: $merge
  }' > $file
}

# _pr_file <owner/repo> <number>: where that PR's fixture lives.
_pr_file() { print -r -- $W/pr/${1//\//__}/$2.json }
# _pr_get / _pr_set <fixture file> <jq program>
_pr_get() { jq -r "$2" $1 }
_pr_set() { jq "$2" $1 > $1.tmp && mv $1.tmp $1 }

# Queue answers for the prompts, one per prompt, in order.
answers() { print -rl -- "$@" > $W/answers }

# ---------------------------------------------------------------------------
# Stubs
# ---------------------------------------------------------------------------

gh() {
  # One line per call: a multi-line --jq program is logged by its first line.
  print -r -- "gh ${${@}%%$'\n'*}" >> $W/calls
  local -a pos owners
  local jqx= repo=$REPO label=
  while (( $# )); do
    case $1 in
      --jq|-q)                        jqx=$2; shift 2 ;;
      --repo|-R)                      repo=$2; shift 2 ;;
      --owner)                        owners+=("$2"); shift 2 ;;
      --label)                        label=$2; shift 2 ;;
      --json|--limit|--state|--match-head-commit) shift 2 ;;
      *)                              pos+=("$1"); shift ;;
    esac
  done
  local n f
  case "${pos[1]} ${pos[2]}" in
    'api user')
      [[ -n $ME ]] || return 1
      jq -r "${jqx:-.}" <<< "{\"login\":\"$ME\"}" ;;
    'api user/orgs')
      jq -n '$ARGS.positional | map({login: .})' --args $ORGS | jq -r "${jqx:-.}" ;;
    'api repos/'*)
      jq -r "${jqx:-.}" <<< '{"author_association":"NONE"}' ;;
    'repo view')
      jq -r "${jqx:-.}" <<< "{\"nameWithOwner\":\"$REPO\"}" ;;
    'pr view')
      n=${pos[3]#\#}; [[ -n $n ]] || n=$CUR_PR
      f=$(_pr_file $repo "$n")
      [[ -n $n && -f $f ]] || return 1
      jq -r "${jqx:-.}" $f ;;
    'pr list')
      f=$(_pr_file $repo x)
      jq -s '[.[] | select(.state == "OPEN")]' ${f:h}/*.json(nN) | jq -r "${jqx:-.}" ;;
    'search prs')
      # Open PRs of every repo carrying --label, in the --owner scopes (all
      # owners when none is given). The author is rewritten to what `gh search
      # prs` reports for an App bot: login "<name>[bot]", is_bot false, type
      # "Bot". That shape is taken from the comment on _gh_trust in the source.
      jq -s --arg label "$label" '
        $ARGS.positional as $owners
        | .[] | select(.state == "OPEN")
        | select($label == "" or any(.labels[]; .name == $label))
        | select(($owners | length) == 0
                 or ((.repository.nameWithOwner | split("/")[0]) as $o | any($owners[]; . == $o)))
        | .author |= (if .is_bot
                      then {login: ((.login | ltrimstr("app/")) + "[bot]"), is_bot: false, type: "Bot"}
                      else . + {type: "User"} end)' \
        $W/pr/*/*.json(nN) --args $owners | jq -s -r "${jqx:-.}" ;;
    'pr merge')
      n=${pos[3]}; f=$(_pr_file $repo "$n")
      [[ -f $f && $(_pr_get $f ._merge) == ok ]] || return 1
      _pr_set $f '.state = "MERGED" | .mergedAt = "2026-01-02T03:04:05Z"' ;;
    'pr ready')
      _pr_set $(_pr_file $repo "${pos[3]}") '.isDraft = false' ;;
    'pr update-branch')
      n=${pos[3]}; f=$(_pr_file $repo "$n")
      case $(_pr_get $f ._update) in
        conflict) print -r -- "Cannot update PR branch due to conflicts"; return 1 ;;
        uptodate) print -r -- "PR branch already up-to-date" ;;
        *)        _pr_set $f ".headRefOid = \"sha${n}b\""; print -r -- "PR branch updated" ;;
      esac ;;
    'pr checks')
      n=${pos[3]}
      if [[ -n $jqx ]]; then jq -r "$jqx" <<< '[{"name":"ci"}]'
      else [[ $(_pr_get $(_pr_file $repo "$n") ._checks) == pass ]]; fi ;;
    'issue list')
      jq -r "${jqx:-.}" $W/issues.json ;;
    *)
      print -r -- "UNSTUBBED gh ${pos[*]}" >> $W/calls
      return 97 ;;
  esac
}

git() {
  print -r -- "git $*" >> $W/calls
  case "$1 $2" in
    'rev-parse --git-dir')  print .git ;;
    'symbolic-ref --short') print -r -- $HEAD_BRANCH ;;
    'show-ref '*)           return 1 ;;
  esac
  return 0
}

claude() { print -r -- "claude $*" >> $W/calls }
sleep()  { : }

fzf() {
  local shown p
  # fzf --ansi matches on, and returns, the text without the colour escapes.
  shown=$(sed $'s/\033\\[[0-9;]*m//g')
  print -r -- "$shown" > $W/fzf.in
  for p in $FZF_PICK; do
    if [[ $p == */*\#* ]]; then
      awk -v r="${p%%\#*}" -v n="#${p#*\#}" '$1 == r && $2 == n' <<< "$shown"
    else
      grep -E "^#$p( |\$)" <<< "$shown"
    fi
  done
  return 0
}

# A prompt is `read ... "name?text"`. Anything else goes to the builtin, which
# assigns the caller's variables through dynamic scope.
read() {
  local _rs_arg _rs_name= _rs_text= _rs_ans
  for _rs_arg in "$@"; do
    if [[ $_rs_arg == [A-Za-z_][A-Za-z0-9_]#\?* ]]; then
      _rs_name=${_rs_arg%%\?*} _rs_text=${_rs_arg#*\?}
    fi
  done
  [[ -n $_rs_name ]] || { builtin read "$@"; return }
  if [[ ! -s $W/answers ]]; then
    print -r -- "UNANSWERED ${_rs_text[1,50]}" >> $W/calls
    eval "$_rs_name="
    return 1
  fi
  _rs_ans=$(head -n 1 $W/answers)
  tail -n +2 $W/answers > $W/answers.tmp && mv $W/answers.tmp $W/answers
  print -r -- "PROMPT ${_rs_text[1,50]} <- $_rs_ans" >> $W/calls
  eval "$_rs_name=\$_rs_ans"
}

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

integer pass=0 fail=0
ok()  { print -r -- "  ✓ $1"; (( pass++ )) }
bad() {
  print -r -- "  ✗ $1"; (( fail++ ))
  print -r -- "      calls:"; sed 's/^/        /' $W/calls
  print -r -- "      output:"; sed 's/^/        /' $W/out
}
# run <command...>: run a wrapper in THIS shell, output to $W/out.
run()      { "$@" > $W/out 2>&1 }
called()   { if grep -Fxq -- "$2" $W/calls; then ok "$1"; else bad "$1 — expected call: $2"; fi }
uncalled() { if grep -Fq  -- "$2" $W/calls; then bad "$1 — unexpected call matching: $2"; else ok "$1"; fi }
printed()  { if grep -Fq  -- "$2" $W/out;   then ok "$1"; else bad "$1 — expected output: $2"; fi }
shown()    { if grep -Fq  -- "$2" $W/fzf.in; then ok "$1"; else bad "$1 — picker did not list: $2"; fi }
unshown()  { if grep -Fq  -- "$2" $W/fzf.in; then bad "$1 — picker listed: $2"; else ok "$1"; fi }
# before <desc> <call A> <call B>: A is logged, and before B.
before() {
  local a b
  a=$(grep -Fxn -- "$2" $W/calls | head -n 1); b=$(grep -Fxn -- "$3" $W/calls | head -n 1)
  if [[ -n $a && -n $b ]] && (( ${a%%:*} < ${b%%:*} )); then ok "$1"; else bad "$1 — expected '$2' before '$3'"; fi
}
is() { if [[ $2 == $3 ]]; then ok "$1"; else print -r -- "  ✗ $1 — want '$3', got '$2'"; (( fail++ )); fi }

# ---------------------------------------------------------------------------
print -r -- "Author classification (_gh_trust)"
# ---------------------------------------------------------------------------
reset
is "own login is self"                         "$(_gh_trust lauri false)"                       self
is "gh pr list bot (app/ login, is_bot)"       "$(_gh_trust app/renovate true)"                 bot
is "gh search bot (type Bot, is_bot false)"    "$(_gh_trust 'release-please[bot]' false Bot)"   bot
is "[bot] login alone is a bot"                "$(_gh_trust 'dependabot[bot]' false)"           bot
is "anyone else is external"                   "$(_gh_trust stranger false)"                    external
is "no author is unknown"                      "$(_gh_trust '' false)"                          unknown
reset; ME=
is "own login unresolvable is unknown"         "$(_gh_trust lauri false)"                       unknown

# ---------------------------------------------------------------------------
print -r -- "ghm <number>: method and trust"
# ---------------------------------------------------------------------------
reset; pr 5 label=squash
run ghm 5
called "merge:squash label merges with --squash" 'gh pr merge 5 --squash --delete-branch'
uncalled "own PR merges without a prompt" 'PROMPT'

reset; pr 5 label=rebase
run ghm '5[some title]'
called "merge:rebase label merges with --rebase; completion suffix stripped" 'gh pr merge 5 --rebase --delete-branch'

reset; pr 5 author=app/renovate bot=true
run ghm 5
called "bot PR merges" 'gh pr merge 5 --squash --delete-branch'
uncalled "bot PR merges without a prompt" 'PROMPT'

reset; pr 5 author=stranger; answers y
run ghm 5
uncalled "external PR: a keypress-style 'y' does not merge" 'gh pr merge'
printed "external PR: the warning names the author" 'stranger'

reset; pr 5 author=stranger; answers merge
run ghm 5
called "external PR: the typed word 'merge' merges" 'gh pr merge 5 --squash --delete-branch'

reset; ME=; pr 5
run ghm 5
uncalled "own login unresolvable: not merged without the typed word" 'gh pr merge'
printed "own login unresolvable: says authorship is unverified" 'AUTHORSHIP UNVERIFIED'

reset
run ghm 99
uncalled "unreadable PR is not merged" 'gh pr merge'

reset; pr 5 label=; answers k
run ghm 5
uncalled "no method and 'k' at the prompt: not merged" 'gh pr merge'

reset; pr 5 label=; answers s
run ghm 5
called "no method and 's' at the prompt: --squash" 'gh pr merge 5 --squash --delete-branch'

# ---------------------------------------------------------------------------
print -r -- "ghm <number>: same engine as the picker"
# ---------------------------------------------------------------------------
reset; pr 5 draft=true; answers s
run ghm 5
uncalled "draft, 's': not merged" 'gh pr merge'

reset; pr 5 draft=true; answers r
run ghm 5
before "draft, 'r': marked ready, then merged" 'gh pr ready 5' 'gh pr merge 5 --squash --delete-branch'

reset; pr 5 mss=BEHIND
run ghm 5
before "BEHIND: branch updated, then merged pinned to the new head" 'gh pr update-branch 5' 'gh pr merge 5 --match-head-commit sha5b --squash --delete-branch'

reset; pr 5 mss=BEHIND checks=fail
run ghm 5
uncalled "CI fails on the updated head: not merged" 'gh pr merge'

reset; pr 5 mergeable=CONFLICTING; answers n
run ghm 5
uncalled "conflicting: not merged" 'gh pr merge'
printed "conflicting: reported" 'conflicting'

reset; pr 5 mergeable=CONFLICTING; answers y
run ghm 5
if grep -Eq '^claude --worktree pr-5-conflicts .*merge origin/main into it' $W/calls; then
  ok "conflicting, 'y' at the handoff: Claude gets a worktree and a merge brief"
else
  bad "conflicting, 'y' at the handoff: Claude gets a worktree and a merge brief"
fi

# ---------------------------------------------------------------------------
print -r -- "ghm: after the merge"
# ---------------------------------------------------------------------------
reset; pr 5 base=main
run ghm 5
called "on the base of the merged PR: pulls" 'git pull --ff-only'

reset; pr 5 author=stranger base=main; answers n
run ghm 5
uncalled "nothing merged: no pull" 'git pull'

reset; pr 5 base=main; CUR_PR=5 HEAD_BRANCH=feat-5
run ghm 5
before "on the merged PR's own branch: switches to the base, then pulls" 'git switch main' 'git pull --ff-only'

# ---------------------------------------------------------------------------
print -r -- "ghm picker: batch merge"
# ---------------------------------------------------------------------------
reset; pr 5 label=squash; pr 6 label=rebase; FZF_PICK=(5 6); answers a
run ghm
called "first PR merges with its own method" 'gh pr merge 5 --repo o/r --squash --delete-branch'
called "second PR, same base: branch updated first (rebase for a rebase merge)" 'gh pr update-branch 6 --repo o/r --rebase'
called "second PR merges pinned to the head CI ran on" 'gh pr merge 6 --repo o/r --match-head-commit sha6b --rebase --delete-branch'
before "PRs merge in selection order" 'gh pr merge 5 --repo o/r --squash --delete-branch' 'gh pr update-branch 6 --repo o/r --rebase'

reset; pr 5; pr 6; FZF_PICK=(5 6); answers n y
run ghm
uncalled "'n' skips that PR" 'gh pr merge 5'
called "'y' merges that PR" 'gh pr merge 6 --repo o/r --squash --delete-branch'
uncalled "no update-branch when the base took no merge this run" 'gh pr update-branch'

reset; pr 5; pr 6; FZF_PICK=(5 6); answers q
run ghm
uncalled "'q' stops before any merge" 'gh pr merge'

reset; pr 5; FZF_PICK=()
run ghm
uncalled "nothing picked: no merge" 'gh pr merge'

reset; pr 5 merge=fail; pr 6; FZF_PICK=(5 6); answers a
run ghm
printed "a failed merge is reported" 'merge failed'
uncalled "a failed merge does not count as moving the base" 'gh pr update-branch'
called "the batch continues after a failed merge" 'gh pr merge 6 --repo o/r --squash --delete-branch'

# ---------------------------------------------------------------------------
print -r -- "Own login lookup (_gh_me) is cached for the run"
# ---------------------------------------------------------------------------
# The picker and each PR's trust check need the login. A lookup made inside
# $(...) cannot cache, so the wrappers resolve it in the calling shell (#590).
reset; pr 5; pr 6; FZF_PICK=(5 6); answers a
run ghm
called "both PRs still merge" 'gh pr merge 6 --repo o/r --match-head-commit sha6b --squash --delete-branch'
is "picker run with two PRs: one gh api user call" "$(grep -c '^gh api user' $W/calls)" 1

reset; pr 5
run ghm 5
is "ghm <number>: one gh api user call" "$(grep -c '^gh api user' $W/calls)" 1

reset; ME=; pr 5; pr 6; FZF_PICK=(5 6); answers a
run ghm -x
uncalled "login unresolvable: nothing merged" 'gh pr merge'
is "a failed lookup is cached too: one gh api user call" "$(grep -c '^gh api user' $W/calls)" 1

# ---------------------------------------------------------------------------
print -r -- "ghm picker: external contributors"
# ---------------------------------------------------------------------------
reset; pr 5; pr 7 author=stranger; FZF_PICK=(7)
run ghm
shown   "own PR is listed" '#5'
unshown "external PR is hidden by default" '#7'
printed "the hidden external PR is reported" '1 external PR(s) hidden'
uncalled "a hidden PR cannot be merged" 'gh pr merge'

reset; pr 7 author=stranger; FZF_PICK=(7); answers a nope
run ghm -x
shown "-x lists the external PR, marked" '⚠stranger'
uncalled "-x: 'a' (all) does not merge an external PR" 'gh pr merge'

reset; pr 7 author=stranger; FZF_PICK=(7); answers a merge
run ghm -x
called "-x: the typed word 'merge' merges it" 'gh pr merge 7 --repo o/r --squash --delete-branch'

# ---------------------------------------------------------------------------
print -r -- "ghm picker: draft, behind, conflicting"
# ---------------------------------------------------------------------------
reset; pr 5 draft=true; FZF_PICK=(5); answers y s
run ghm
uncalled "draft, 's': not marked ready" 'gh pr ready'
uncalled "draft, 's': not merged" 'gh pr merge'

reset; pr 5 draft=true; FZF_PICK=(5); answers y r
run ghm
before "draft, 'r': marked ready, then merged" 'gh pr ready 5 --repo o/r' 'gh pr merge 5 --repo o/r --squash --delete-branch'

reset; pr 5 mss=BEHIND; FZF_PICK=(5); answers y
run ghm
before "BEHIND: branch updated (merge, for a squash) before merging" 'gh pr update-branch 5 --repo o/r' 'gh pr merge 5 --repo o/r --match-head-commit sha5b --squash --delete-branch'

reset; pr 5 mss=BEHIND update=uptodate; FZF_PICK=(5); answers y
run ghm
called "BEHIND but already up to date: merges unpinned" 'gh pr merge 5 --repo o/r --squash --delete-branch'

reset; pr 5 mss=BEHIND checks=fail; FZF_PICK=(5); answers y
run ghm
uncalled "CI fails on the updated head: not merged" 'gh pr merge'
printed "CI failure is reported" 'CI failed'

reset; pr 5 mergeable=CONFLICTING; FZF_PICK=(5); answers y n
run ghm
uncalled "conflicting: not merged" 'gh pr merge'
uncalled "conflicting, 'n' at the handoff: Claude not started" 'claude'

reset; pr 5 mergeable=CONFLICTING label=rebase; FZF_PICK=(5); answers y y
run ghm
uncalled "conflicting: not merged" 'gh pr merge'
if grep -Eq '^claude --worktree pr-5-conflicts .*rebase it onto origin/main' $W/calls; then
  ok "conflicting, 'y' at the handoff: Claude gets a worktree and a rebase brief"
else
  bad "conflicting, 'y' at the handoff: Claude gets a worktree and a rebase brief"
fi

reset; pr 5 mss=BEHIND update=conflict; FZF_PICK=(5); answers y n
run ghm
uncalled "update-branch reports a conflict: not merged" 'gh pr merge'
printed "update-branch conflict is reported as conflicting" 'conflicting'

# ---------------------------------------------------------------------------
print -r -- "_gh_poll_merge: exit status and reply"
# ---------------------------------------------------------------------------
# poll <args...>: run it in this shell and print "<status> <reply...>".
poll() { _gh_poll_merge "$@" > $W/out 2>&1; print -r -- "$? ${reply[*]}" }

reset; pr 5 label=rebase base=dev
poll o/r 5 "" auto --delete-branch > $W/res
is "merged: 0, reply = base and method" "$(<$W/res)" "0 dev rebase"

reset; pr 5 mergeable=CONFLICTING
poll o/r 5 "" auto > $W/res
is "conflicting: 2, reply = base and method" "$(<$W/res)" "2 main squash"

reset; pr 5 merge=fail
poll o/r 5 "" auto > $W/res
is "merge failed: 1, empty reply" "$(<$W/res)" "1 "

reset; pr 5 author=stranger; answers no
poll o/r 5 "" auto > $W/res
is "declined at the trust gate: 3 (skipped), empty reply" "$(<$W/res)" "3 "

reset; pr 5 draft=true; answers s
poll o/r 5 "" auto > $W/res
is "draft skipped: 3" "$(<$W/res)" "3 "

reset; pr 5 label=; answers k
poll o/r 5 "" auto > $W/res
is "no method chosen: 3" "$(<$W/res)" "3 "

reset; pr 5 label=squash
poll o/r 5 "" squash > $W/res
is "explicit method matching the recommendation: merged" "$(<$W/res)" "0 main squash"
uncalled "explicit method matching the recommendation: no prompt" 'PROMPT'

reset; pr 5 label=rebase; answers n
poll o/r 5 "" squash > $W/res
is "explicit method against the recommendation, 'n': 3" "$(<$W/res)" "3 "
uncalled "explicit method against the recommendation, 'n': not merged" 'gh pr merge'

reset; pr 5 label=rebase; answers y
poll o/r 5 "" squash > $W/res
called "explicit method against the recommendation, 'y': merges with the explicit one" 'gh pr merge 5 --repo o/r --squash'

reset; pr 5 base=dev; pr 6 base=main; FZF_PICK=(5 6); answers a
run ghm
uncalled "a merge into another base does not trigger an update" 'gh pr update-branch'

# ---------------------------------------------------------------------------
print -r -- "ghrp: release PRs across repos"
# ---------------------------------------------------------------------------
# release <number> <owner/repo> [key=value ...]: a release-please PR as the
# release bot opens it.
release() {
  local n=$1 r=$2; shift 2
  pr $n repo=$r release=true author=app/release-please bot=true "$@"
}

# The same number in two repos: only --repo tells the two PRs apart.
reset
release 3 lauri/tool title='chore(main): release 1.2.0'
release 3 acme/api   title='chore(main): release 2.0.0'
pr 9 repo=lauri/tool
FZF_PICK=('lauri/tool#3' 'acme/api#3'); answers a
run ghrp
shown   "a release bot's PR is listed as bot (search reports type Bot, is_bot false)" '#3  bot  chore(main): release 1.2.0'
unshown "a bot row carries no warning marker" '⚠'
unshown "a PR without the release label is not listed" '#9'
printed "the selected row's title reaches the summary whole" '#3  chore(main): release 1.2.0'
called  "release PR in the user's repo: --repo and --squash" 'gh pr merge 3 --repo lauri/tool --squash'
called  "release PR in an org repo: --repo and --squash" 'gh pr merge 3 --repo acme/api --squash'
uncalled "bot release PRs merge without the typed confirmation" 'merge>'
uncalled "a merge in one repo does not update a PR in another" 'gh pr update-branch'

reset
pr 4 repo=acme/api release=true author=mallory
pr 6 repo=lauri/tool release=true
FZF_PICK=('acme/api#4'); answers a nope
run ghrp
shown    "a non-bot author is listed with the warning marker" '#4  ⚠mallory'
shown    "own PR is listed as me" '#6  me '
printed  "non-bot author: the external-contributor warning is printed" 'EXTERNAL CONTRIBUTOR'
uncalled "non-bot author: 'a' (all) and a wrong word do not merge" 'gh pr merge'

reset; pr 4 repo=acme/api release=true author=mallory
FZF_PICK=('acme/api#4'); answers a merge
run ghrp
called "non-bot author: the typed word 'merge' merges" 'gh pr merge 4 --repo acme/api --squash'

reset; release 3 acme/api; FZF_PICK=()
run ghrp
printed  "nothing picked: says so" 'Nothing selected.'
uncalled "nothing picked: no merge" 'gh pr merge'

reset
run ghrp
printed "empty search: names the owners searched" 'No open release-please PRs found in: lauri, acme'
if [[ -e $W/fzf.in ]]; then bad "empty search: the picker is not opened"; else ok "empty search: the picker is not opened"; fi

reset; release 3 other/x; FZF_PICK=()
run ghrp
printed "a PR outside the user's login and orgs is not found" 'No open release-please PRs found'
run ghrp other
shown "an owner given as an argument is searched too" 'other/x'

# ---------------------------------------------------------------------------
print -r -- "ghi: issues handed to Claude"
# ---------------------------------------------------------------------------
issues() {
  print -r -- '[
    {"number":7,"title":"c","labels":[],"createdAt":"2026-01-03T00:00:00Z"},
    {"number":12,"title":"a","labels":[],"createdAt":"2026-01-01T00:00:00Z"},
    {"number":1157,"title":"Investigate hydration error #418","labels":[{"name":"type:bug"}],"createdAt":"2026-01-02T00:00:00Z"}
  ]' > $W/issues.json
}
reset; issues; FZF_PICK=(1157)
run ghi
called "one picked issue; a later #418 in the title is not picked up" 'claude /git-issue 1157'

reset; issues; FZF_PICK=(12 1157 7)
run ghi
called "several picked issues go to one session" 'claude /git-issue 12 1157 7'

reset; issues; FZF_PICK=()
run ghi
uncalled "nothing picked: Claude not started" 'claude'

reset
run ghi 42 '43[some title]' '#44'
called "arguments: completion suffix and leading # stripped" 'claude /git-issue 42 43 44'

# ---------------------------------------------------------------------------
print -r -- "Single-PR pickers (shared jq ci/rev functions)"
# ---------------------------------------------------------------------------
reset; pr 5; pr 6; FZF_PICK=(6)
is "_gh_pr_pick prints the picked PR's number" "$(_gh_pr_pick)" 6
shown "_gh_pr_pick lists the CI and review tokens" '⏳CI  -rev'

# The title's "#418" comes after the PR's own number in the row: the number
# taken must be the first column's (#586).
reset; pr 5; pr 6 title='fix #418 thing'; FZF_PICK=(6)
run ghpc
shown "ghpc lists the CI and review tokens" '⏳CI  -rev'
if grep -q '^claude Check the PR #6 workflow results' $W/calls; then
  ok "ghpc hands the picked PR to Claude"
else
  bad "ghpc hands the picked PR to Claude"
fi

# ---------------------------------------------------------------------------
print -r -- "Colour variables"
# ---------------------------------------------------------------------------
# The wrappers set their colours through dynamic scope (_gh_palette), so a
# name missing from a `local $_GH_COLORS` would become a global in the shell.
leaked=()
for c in $_GH_COLORS; do (( ${+parameters[$c]} )) && leaked+=($c); done
is "no colour variable leaked into the shell after the runs above" "${leaked[*]}" ""
palette_probe() { local $_GH_COLORS; _gh_palette 1; print -r -- "${#red}${#rst}" }
is "colours are empty when stdout is not a terminal" "$(palette_probe)" "00"

# ---------------------------------------------------------------------------
print
if grep -q '^UNSTUBBED' $W/calls; then
  print -r -- "  ✗ the last case made a gh call this harness does not stub"; (( fail++ ))
fi
print -r -- "Passed: $pass  Failed: $fail"
(( fail == 0 ))
