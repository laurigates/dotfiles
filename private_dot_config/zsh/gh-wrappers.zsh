# gh* wrapper functions: fzf pickers over `gh`, the multi-merge engine behind
# ghm / ghrp, and the Claude handoffs (ghi, ghpc).
#
# Sourced by ~/.zshrc (dot_zshrc.tmpl). Kept in its own file so that
# tests/test-gh-wrappers.sh can source it with gh, fzf, git and claude stubbed.
# The completions and fzf-tab previews for these wrappers stay in ~/.zshrc,
# because they need compinit to have run.

# Colours for a function that prints status lines. Declare them with
#   local $_GH_COLORS; _gh_palette <fd>
# They stay empty unless <fd> (1 = stdout, 2 = stderr) is a terminal, so
# redirected output carries no escapes.
typeset -ga _GH_COLORS=(green red yellow cyan magenta dim bold rst alarm)
_gh_palette() {
  [[ -t ${1:-1} ]] || return 0
  green=$'\033[32m' red=$'\033[31m' yellow=$'\033[33m' cyan=$'\033[36m' magenta=$'\033[35m'
  dim=$'\033[2m' bold=$'\033[1m' rst=$'\033[0m' alarm=$'\033[1;97;41m'
}

# jq functions for the PR pickers, prepended to their --jq programs: `ci` and
# `rev` turn one PR object into the CI and review tokens _gh_paint colours.
typeset -g _GH_JQ_PR_DEFS='
  def ci: if (.statusCheckRollup | length) == 0 then "⏳CI"
          elif (.statusCheckRollup | all(.conclusion == "SUCCESS")) then "✓CI"
          elif (.statusCheckRollup | any(.conclusion == "FAILURE")) then "✗CI"
          else "⏳CI" end;
  def rev: if .reviewDecision == "APPROVED" then "✓rev"
           elif .reviewDecision == "CHANGES_REQUESTED" then "✗rev"
           elif .reviewDecision == "REVIEW_REQUIRED" then "⏳rev"
           else "-rev" end;
'

# Colourise gh fzf-picker tables *after* `column -t` has aligned them, so the
# padding widths are computed on plain text and the escapes (zero-width under
# fzf --ansi) never shift a column. Shared by every gh picker below.
#   … | column -t -s $'\t' | _gh_paint | fzf --ansi …
_gh_paint() {
  awk '
    {
      # ⚠<login> (external contributor) FIRST, while the line is still free of
      # escapes: the [^ ]* run would otherwise swallow an escape another gsub
      # had inserted immediately after the token. White-on-red so a stranger’s
      # PR cannot be mistaken for one of yours at a glance.
      gsub(/⚠[^ ]*/,     "\033[1;97;41m&\033[0m")
      gsub(/✓[A-Za-z]*/, "\033[32m&\033[0m")   # success  → green
      gsub(/✗[A-Za-z]*/, "\033[31m&\033[0m")   # failure  → red
      gsub(/⏳[A-Za-z]*/, "\033[33m&\033[0m")  # pending  → yellow
      gsub(/#[0-9]+/,     "\033[36m&\033[0m")  # PR/issue → cyan
      gsub(/ draft /, " \033[1;35mdraft\033[0m ")  # draft PR (blocks merge) → bold magenta
      gsub(/ ready /, " \033[2mready\033[0m ")     # ready PR → dim (so drafts pop)
      gsub(/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/, "\033[2m&\033[0m")  # date → dim
      print
    }'
}

# ---- contributor trust (external-PR merge guard) ---------------------
# The gh* merge wrappers exist for bulk-merging your OWN and bots' PRs, and the
# muscle memory is `ghm` → ^a (select all) → a (all remaining). A drive-by PR
# from a stranger riding that reflex is the hazard these three helpers close:
# external PRs are hidden from the picker by default (ghm -x opts in) and can
# never be merged by a single keypress or swept up by `a`.

# Your own login, resolved once per shell into $_GH_ME. A failure is cached
# too, so a network-less shell doesn't re-probe per PR — it just fails closed
# below.
#
# It prints nothing: call it, then read $_GH_ME. A lookup made inside $(...)
# would cache in a subshell that is about to exit, so ghm and _gh_trust_gate
# call it in their own shell before any substitution that needs the login.
typeset -g _GH_ME= _GH_ME_TRIED=0
_gh_me() {
  (( _GH_ME_TRIED )) || { _GH_ME=$(gh api user --jq '.login' 2>/dev/null); _GH_ME_TRIED=1 }
  return 0
}

# Classify a PR author → self | bot | external | unknown.
#   _gh_trust <login> [is_bot] [author_type]
# Bot authors render DIFFERENTLY per gh subcommand, which is the trap here:
#   gh pr list    → login "app/<name>",   is_bot true,  no type
#   gh search prs → login "<name>[bot]",  is_bot FALSE, type "Bot"
# So `is_bot` alone silently misclassifies every App bot in search results as a
# stranger. Accept any of the four signals. `unknown` (own login unresolvable,
# or no author) is treated as untrusted by callers — fail closed.
_gh_trust() {
  local login="$1" is_bot="${2:-}" atype="${3:-}" me
  _gh_me; me=$_GH_ME
  [[ -z "$me" || -z "$login" ]] && { print -r -- unknown; return }
  [[ "$login" == "$me" ]] && { print -r -- self; return }
  [[ "$is_bot" == true || "$atype" == Bot || "$login" == *'[bot]' || "$login" == app/* ]] \
    && { print -r -- bot; return }
  print -r -- external
}

# Loud confirmation for a PR that is not yours and not a bot's. Prints who wrote
# it, how big it is, and — the part that matters — which touched paths actually
# EXECUTE something (CI workflow, shell, Claude config, build entry point).
# Requires a typed word, never a keypress. 0 = merge it, 1 = skip it.
#   _gh_confirm_external <repo|""> <num> <login> <trust> <title>
_gh_confirm_external() {
  local repo="$1" num="$2" login="$3" trust="$4" title="$5"
  local -a repo_flag; [[ -n "$repo" ]] && repo_flag=(--repo "$repo")
  local id="${repo}#${num}"

  local $_GH_COLORS; _gh_palette 1

  # author_association needs an owner/repo slug (gh pr view has no such field).
  local slug="$repo" assoc=
  [[ -z "$slug" ]] && slug=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
  [[ -n "$slug" ]] && assoc=$(gh api "repos/$slug/pulls/$num" --jq '.author_association' </dev/null 2>/dev/null)

  local stats adds dels nfiles
  stats=$(gh pr view "$num" "${repo_flag[@]}" --json additions,deletions,changedFiles \
            --jq '[(.additions|tostring),(.deletions|tostring),(.changedFiles|tostring)] | @tsv' </dev/null 2>/dev/null)
  IFS=$'\t' read -r adds dels nfiles <<< "$stats"

  # One path per line, so paths containing spaces survive.
  local -a paths risky
  paths=("${(@f)$(gh pr view "$num" "${repo_flag[@]}" --json files --jq '.files[].path' </dev/null 2>/dev/null)}")
  local p
  for p in "${paths[@]}"; do
    [[ -z "$p" ]] && continue
    case "$p" in
      .github/workflows/*|.github/actions/*)              risky+=("$p  ${dim}← CI executes this${rst}") ;;
      *.sh|*.bash|*.zsh|*/hooks/*|.githooks/*)            risky+=("$p  ${dim}← shell that may run on your machine${rst}") ;;
      .claude/*|*/.claude/*)                              risky+=("$p  ${dim}← Claude Code config / permissions${rst}") ;;
      package.json|*/package.json|pyproject.toml|Cargo.toml|mise.toml|[jJ]ustfile|Makefile|Dockerfile|.pre-commit-config.yaml) \
                                                          risky+=("$p  ${dim}← build / tooling entry point${rst}") ;;
      *.lock|package-lock.json)                           risky+=("$p  ${dim}← dependency pin${rst}") ;;
    esac
  done

  print
  if [[ "$trust" == unknown ]]; then
    print -r -- "  ${alarm}╔═ ⚠ AUTHORSHIP UNVERIFIED ═${rst}"
  else
    print -r -- "  ${alarm}╔═ ⚠ EXTERNAL CONTRIBUTOR ═${rst}"
  fi
  print -r -- "  ${red}║${rst} ${cyan}${id}${rst}  ${title}"
  print -r -- "  ${red}║${rst} ${bold}author${rst}  ${alarm} ${login:-<unknown>} ${rst}${assoc:+  ${dim}(${assoc})${rst}}"
  [[ -n "$nfiles" ]] && print -r -- "  ${red}║${rst} ${bold}size${rst}    ${nfiles} file(s)  ${yellow}+${adds}${rst} ${dim}-${dels}${rst}"
  if (( ${#risky} )); then
    print -r -- "  ${red}║${rst} ${alarm} ⚠ EXECUTABLE PATHS TOUCHED ${rst}"
    for p in "${risky[@]}"; do print -r -- "  ${red}║${rst}     ${p}"; done
  elif (( ${#paths} )); then
    print -r -- "  ${red}║${rst} ${dim}no CI / shell / config paths touched${rst}"
  fi
  print -r -- "  ${red}╠═${rst} ${yellow}not covered by 'a'=all — review it before answering${rst}"
  print -r -- "  ${red}╚═${rst} type ${bold}merge${rst} to merge, anything else skips"
  local ans
  read -r "ans?  ${bold}merge>${rst} "
  [[ "${ans:l}" == merge ]] && return 0
  print -r -- "  ${dim}– skipped ${id} (not merged)${rst}"
  return 1
}

# Resolve a PR's author and gate on it. Silent (and 0) for your own and bots'
# PRs, so bulk-merging is unchanged; loud and typed-word-gated otherwise.
# Called from _gh_poll_merge (covers the batch path, including `a`=all) AND from
# the ghm single-arg form, which bypasses the picker entirely.
#   _gh_trust_gate <repo|""> <num>     → 0 proceed, 1 skip
_gh_trust_gate() {
  local repo="$1" num="$2"
  local -a repo_flag; [[ -n "$repo" ]] && repo_flag=(--repo "$repo")
  local id="${repo}#${num}"
  local $_GH_COLORS; _gh_palette 1

  local meta login is_bot title
  meta=$(gh pr view "$num" "${repo_flag[@]}" --json author,title \
           --jq '[.author.login, (.author.is_bot|tostring), .title] | @tsv' </dev/null 2>/dev/null)
  if [[ -z "$meta" ]]; then
    print -r -- "  ${yellow}!${rst} ${id}: couldn't read PR author — ${yellow}skipped${rst} (can't verify it's yours)"
    return 1
  fi
  IFS=$'\t' read -r login is_bot title <<< "$meta"

  _gh_me   # here, not only inside the substitution below, so the result is kept
  local trust; trust=$(_gh_trust "$login" "$is_bot")
  case "$trust" in
    self|bot) return 0 ;;
    *)        _gh_confirm_external "$repo" "$num" "$login" "$trust" "$title" ;;
  esac
}

# `gh pr list` with each PR's #number wrapped in an OSC 8 terminal hyperlink to
# the PR page. We let gh render natively (GH_FORCE_TTY forces its TTY layout
# even through a pipe), so the state-based number colours (green=open,
# magenta=merged, red=closed), cyan branch, dim date, and column alignment all
# match `gh pr ls` exactly; an awk pass then wraps the leading #number — the
# first match per line, i.e. the ID column, never a #123 inside a title — in a
# zero-width hyperlink. Clickable under kitty/WezTerm/iTerm2, plain text
# elsewhere. Extra args pass through (e.g. `ghprls --author @me`,
# `ghprls -L 50 --state all`).
ghprls() {
  local repo
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || return
  GH_FORCE_TTY="${COLUMNS:-100}" gh pr list "$@" |
    awk -v repo="$repo" '
      match($0, /#[0-9]+/) {
        num = substr($0, RSTART + 1, RLENGTH - 1)
        link = "\033]8;;https://github.com/" repo "/pull/" num "\033\\"
        $0 = substr($0, 1, RSTART - 1) link substr($0, RSTART, RLENGTH) "\033]8;;\033\\" substr($0, RSTART + RLENGTH)
      }
      { print }'
}

# GitHub Issues → Claude: select issue and process with git:issue skill
# Sorted oldest-first by creation date (like ghm), with --layout=reverse so
# the cursor starts on the oldest issue at the top.
# Several issues (Tab-marked in the picker, or passed as args) go to one Claude
# session as `/git-issue N M …`; the skill plans and groups them itself.
ghi() {
  local -a issue_nums
  if [[ $# -eq 0 ]]; then
    # No args: interactive fzf selection (Tab marks several, Enter confirms)
    local selection line
    selection=$(gh issue list --limit 100 --json number,title,labels,createdAt \
      --jq 'sort_by(.createdAt) | .[] | [
        "#\(.number)",
        (if (.labels | length) > 0 then (.labels | map(.name) | join(","))[:20] else "-" end),
        (.createdAt | fromdateiso8601 | strftime("%Y-%m-%d")),
        .title[:60]
      ] | @tsv' | \
      column -t -s $'\t' | \
      _gh_paint | \
      fzf --ansi --multi --layout=reverse \
          --header $'Tab mark · ^a all · ⏎ hand to Claude · ^t toggle preview · ^d/u scroll\n#       Labels               Created     Title' \
          --preview 'GH_FORCE_TTY=1 gh issue view {1}' \
          --preview-window right:60%:wrap \
          --bind 'tab:toggle+down,btab:toggle+up' \
          --bind 'ctrl-a:select-all' \
          --bind 'ctrl-t:toggle-preview' \
          --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up')

    [[ -z "$selection" ]] && return 0
    # One selected row per line; the number is the first column, "#123".
    for line in "${(@f)selection}"; do
      issue_nums+=("${${line#\#}%% *}")
    done
  else
    # Args provided: strip a leading "#" and the completion suffix
    # (e.g. "123[title]" -> "123") from each
    local arg
    for arg in "$@"; do
      arg="${arg#\#}"
      issue_nums+=("${arg%%\[*}")
    done
  fi

  print -r -- "Processing issue(s) #${(j:, #:)issue_nums} with Claude..."
  claude "/git-issue ${issue_nums[*]}"
}

# Start Claude on a PR's branch in a worktree.
#   _claude_pr_worktree <pr-number> <worktree-name> <prompt>
# If a worktree already has the PR's head branch checked out, Claude runs
# there: a new worktree could not check that branch out ("already used by
# worktree"). Otherwise a new worktree named <worktree-name> is created; the
# name goes before the prompt because --worktree takes an optional name and
# would otherwise consume the prompt as one.
_claude_pr_worktree() {
  local n="$1" name="$2" prompt="$3" head wt line
  head=$(gh pr view "$n" --json headRefName -q .headRefName 2>/dev/null)
  if [[ -n "$head" ]]; then
    while IFS= read -r line; do
      case "$line" in
        "worktree "*) wt="${line#worktree }" ;;
        "branch refs/heads/$head") break ;;
        "") wt="" ;;
      esac
    done < <(git worktree list --porcelain; print)
    [[ "$line" == "branch refs/heads/$head" ]] || wt=""
  fi
  # A worktree whose directory was deleted without `git worktree remove` is
  # still listed and still holds the branch, so a new worktree would fail
  # too. Prune such stale entries; git leaves live and locked ones alone.
  if [[ -n "$wt" && ! -d "$wt" ]]; then
    print -r -- "  ${head} is held by a deleted worktree at ${wt} — pruning stale worktree entries"
    git worktree prune -v
    wt=""
  fi
  if [[ -n "$wt" ]]; then
    print -r -- "  ${head} is already checked out in ${wt} — starting Claude there"
    (cd "$wt" && claude "$prompt")
  else
    claude --worktree "$name" "$prompt"
  fi
}

# GitHub PRs → Claude: select PR and address workflow/review feedback
# Flags: -w/--worktree (isolated worktree), -r/--resume (resume linked session via --from-pr)
ghpc() {
  local pr_num worktree=false resume=false

  # Parse flags before positional arg
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -w|--worktree) worktree=true; shift ;;
      -r|--resume)   resume=true; shift ;;
      *) break ;;
    esac
  done

  if [[ $# -eq 0 ]]; then
    # No args: interactive fzf selection
    local selection
    selection=$(gh pr list --limit 100 --json number,title,headRefName,isDraft,statusCheckRollup,reviewDecision,updatedAt \
      --jq "${_GH_JQ_PR_DEFS}"'.[] | [
        "#\(.number)",
        (if .isDraft then "draft" else "ready" end),
        ci,
        rev,
        .headRefName[:25],
        .title[:45]
      ] | @tsv' | \
      column -t -s $'\t' | \
      _gh_paint | \
      fzf --ansi \
          --header '#       State  CI    Review  Branch                    Title' \
          --preview 'GH_FORCE_TTY=1 gh pr view {1} && echo && echo "--- Checks ---" && GH_FORCE_TTY=1 gh pr checks {1}' \
          --preview-window right:60%:wrap \
          --bind 'ctrl-t:toggle-preview' \
          --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up')

    [[ -z "$selection" ]] && return 0
    pr_num="${${selection#\#}%% *}"
  else
    # Args provided: strip completion suffix (e.g. "123[branch]" -> "123")
    pr_num="${1%%\[*}"
  fi

  if $resume; then
    echo "Resuming PR #$pr_num session with Claude..."
    claude --from-pr "$pr_num"
  elif $worktree; then
    echo "Addressing PR #$pr_num feedback with Claude in worktree..."
    _claude_pr_worktree "$pr_num" "pr-${pr_num}-feedback" "Check the PR #$pr_num workflow results and read the PR comments and address substantive feedback and suggestions"
  else
    echo "Addressing PR #$pr_num feedback with Claude..."
    claude "Check the PR #$pr_num workflow results and read the PR comments and address substantive feedback and suggestions"
  fi
}

# ---- recommended merge method (ghm, and the ghrp mismatch warning) ----
# METHOD from claude-plugins' git-plugin/scripts/pr-merge-method.py: the rule
# table behind the merge-method check run and the git-plugin `gh pr merge` hook
# (git-plugin/skills/github-pr-title/merge-strategies.md). The newest installed
# git-plugin's copy is used; without one, the PR's merge:rebase / merge:squash
# label (set by the check, or by a human as an override) decides.
#   _gh_merge_method <repo|""> <num> → prints rebase|squash, or nothing
_gh_merge_method() {
  # (Nn) below is a glob qualifier; Claude Code's shell sets nobareglobqual.
  setopt local_options bare_glob_qual
  local repo="$1" num="$2" m=
  local -a repo_flag script
  [[ -n "$repo" ]] && repo_flag=(--repo "$repo")
  script=($HOME/.claude/plugins/cache/*/git-plugin/*/scripts/pr-merge-method.py(Nn))
  if (( ${#script} )) && (( $+commands[python3] )); then
    m=$(python3 "${script[-1]}" "${repo_flag[@]}" --pr "$num" </dev/null 2>/dev/null | sed -n 's/^METHOD=//p')
  fi
  if [[ "$m" != rebase && "$m" != squash ]]; then
    m=$(gh pr view "$num" "${repo_flag[@]}" --json labels \
          --jq '[.labels[].name | select(. == "merge:rebase" or . == "merge:squash")][0] // "" | ltrimstr("merge:")' \
          </dev/null 2>/dev/null)
  fi
  [[ "$m" == rebase || "$m" == squash ]] && print -r -- "$m"
}

# Ask for the method when _gh_merge_method has none (no git-plugin, no merge:*
# label, or the script failed). Prompt on stderr so callers can capture stdout.
#   _gh_ask_method <id> → prints rebase|squash, or nothing (= skip)
_gh_ask_method() {
  local id="$1" ans
  local $_GH_COLORS; _gh_palette 2
  read -k 1 "ans?  ${yellow}?${rst} ${cyan}${id}${rst}: no merge method (no pr-merge-method.py, no merge:* label) — [${green}r${rst}=rebase/${green}s${rst}=squash/${dim}k${rst}=skip] "
  print -u2
  case "$ans" in
    r|R) print -r -- rebase ;;
    s|S) print -r -- squash ;;
  esac
}

# Warn when an explicit --squash / --rebase disagrees with the recommendation,
# and ask before merging anyway. Returns 1 to skip the PR.
#   _gh_method_check <repo|""> <num> <rebase|squash>
_gh_method_check() {
  local repo="$1" num="$2" want="$3" rec ans
  local $_GH_COLORS; _gh_palette 1
  rec=$(_gh_merge_method "$repo" "$num")
  [[ -z "$rec" || "$rec" == "$want" ]] && return 0
  read -k 1 "ans?  ${yellow}⚠${rst} ${cyan}#${num}${rst} is recommended for ${bold}--${rec}${rst}, not --${want} (ghm picks it per PR). Merge with --${want} anyway? [y/N] "; print
  [[ "$ans" == [yY] ]]
}

# ---- shared multi-merge engine (ghm / ghrp) ------------------------
# GitHub recomputes a repo's other open PRs' mergeability after each merge and
# refuses to merge a PR while its status is UNKNOWN. So merge sequentially and,
# per PR, poll until mergeability settles, then merge.
#
# A PR whose base already took a merge earlier in the batch is brought up to
# date (gh pr update-branch) and its CI re-run before it merges: its green CI
# only ran against the old base, so a PR that merges cleanly could still break
# it. So is one already BEHIND when the run starts, if the base's ruleset
# requires up-to-date branches — gh pr merge refuses it otherwise.
# update-branch cannot fix a real conflict, so a CONFLICTING PR is reported to
# the caller, which offers to hand it to Claude once the merges are done.
#
#   _gh_poll_merge <repo|""> <num> <moved> <auto|rebase|squash> [gh pr merge flags...]
#   <repo>   "" = the current repo.
#   <moved>  space-separated "repo:base" keys that took a merge this run.
#   <method> auto = this PR's recommended method (ghm), so one batch can mix
#            rebase and squash merges; with no recommendation, ask.
#            rebase|squash = that method (ghrp), confirmed first if it differs
#            from the recommendation.
#   Exit status: 0 merged · 1 failed · 2 conflicting · 3 skipped.
#   For 0 and 2 it also sets the array reply=(<base branch> <rebase|squash>):
#   the caller needs the base to track what moved, and the method so the Claude
#   handoff for a conflict rebases or merges to match.
_gh_poll_merge() {
  local repo="$1" num="$2" moved="$3" want="$4"; shift 4
  reply=()
  local -a repo_flag; [[ -n "$repo" ]] && repo_flag=(--repo "$repo")
  local id="${repo}#${num}"
  local $_GH_COLORS; _gh_palette 1

  # Contributor-trust gate FIRST, before the draft prompt or any merge: a
  # stranger's PR must not even reach "mark ready & merge". This is also what
  # makes `a`=all in _gh_batch_merge safe — `a` skips the per-PR y/N prompt but
  # still lands here, and an external PR demands a typed word regardless.
  _gh_trust_gate "$repo" "$num" || return 3

  local method
  if [[ "$want" == auto ]]; then
    method=$(_gh_merge_method "$repo" "$num")
    [[ -n "$method" ]] || method=$(_gh_ask_method "$id")
    if [[ -z "$method" ]]; then
      print -r -- "  ${dim}– skipped ${id} (no merge method)${rst}"; return 3
    fi
    print -r -- "  ${dim}${id}: --${method}${rst}"
  else
    _gh_method_check "$repo" "$num" "$want" || return 3
    method="$want"
  fi

  local meta draft base
  meta=$(gh pr view "$num" "${repo_flag[@]}" --json isDraft,baseRefName \
           --jq '"\(.isDraft)\t\(.baseRefName)"' </dev/null 2>/dev/null)
  draft="${meta%%$'\t'*}" base="${meta#*$'\t'}"

  # Draft PRs report mergeable=MERGEABLE (that field tracks conflicts, not draft
  # state), so the poll loop below never catches them — `gh pr merge` just fails.
  # Detect the draft up front and prompt: mark ready & merge, or skip.
  if [[ "$draft" == true ]]; then
    local dans
    read -k 1 "dans?  ${magenta}draft${rst} ${cyan}${id}${rst} — [${green}r${rst}=ready&merge/${dim}s${rst}=skip] "; print
    case "$dans" in
      r|R)
        if gh pr ready "$num" "${repo_flag[@]}" </dev/null; then
          print -r -- "  ${green}✓${rst} ${cyan}${id}${rst} marked ready for review"
        else
          print -r -- "  ${red}✗${rst} ${cyan}${id}${rst}: couldn't mark ready — skipped"; return 1
        fi ;;
      *) print -r -- "  ${dim}– skipped draft ${id}${rst}"; return 3 ;;
    esac
  fi

  local state
  state=$(_gh_wait_mergeable "$repo" "$num" "$id")
  if [[ "$state" == CONFLICTING ]]; then
    print -r -- "  ${red}✗${rst} ${cyan}${id}${rst}: ${red}conflicting${rst} — left open"
    reply=("$base" "$method"); return 2
  fi

  # BEHIND = the base ruleset requires up-to-date branches (strict status
  # checks) and this head is stale. It shows up only under that rule, so an
  # unprotected base keeps the moved-this-run-only behaviour.
  local -a pin
  local mss
  mss=$(gh pr view "$num" "${repo_flag[@]}" --json mergeStateStatus --jq .mergeStateStatus </dev/null 2>/dev/null)
  if [[ " $moved " == *" ${repo}:${base} "* || "$mss" == BEHIND ]]; then
    local -a upd; [[ "$method" == rebase ]] && upd=(--rebase)
    _gh_update_and_wait "$repo" "$num" "$id" "${upd[@]}"
    case $? in
      0) ;;
      2) print -r -- "  ${red}✗${rst} ${cyan}${id}${rst}: ${red}conflicting${rst} — left open"
         reply=("$base" "$method"); return 2 ;;
      *) return 1 ;;
    esac
    # Merge exactly the head CI just passed on (REPLY, from _gh_update_and_wait);
    # a push landing in between fails the merge instead of slipping through
    # untested.
    [[ -n "$REPLY" ]] && pin=(--match-head-commit "$REPLY")
    _gh_wait_mergeable "$repo" "$num" "$id" >/dev/null
  fi

  if gh pr merge "$num" "${repo_flag[@]}" "${pin[@]}" "--$method" "$@" </dev/null; then
    print -r -- "  ${green}✓ merged${rst} ${cyan}${id}${rst}"
    reply=("$base" "$method")
  else
    print -r -- "  ${red}✗${rst} ${cyan}${id}${rst}: ${red}merge failed${rst} (left open — re-run to retry)"; return 1
  fi
}

# Poll until GitHub settles a PR's mergeability; prints the final state.
#   _gh_wait_mergeable <repo|""> <num> <id>
_gh_wait_mergeable() {
  local repo="$1" num="$2" id="$3"
  local -a repo_flag; [[ -n "$repo" ]] && repo_flag=(--repo "$repo")
  local $_GH_COLORS; _gh_palette 2
  local state tries=0
  while (( tries < 20 )); do
    state=$(gh pr view "$num" "${repo_flag[@]}" --json mergeable --jq '.mergeable' </dev/null 2>/dev/null)
    [[ -n "$state" && "$state" != UNKNOWN ]] && break
    (( tries == 0 )) && print -r -- "  ${yellow}…${rst} waiting for ${cyan}${id}${rst} mergeability to settle" >&2
    sleep 2; (( tries++ ))
  done
  print -r -- "$state"
}

# Bring a PR up to date with its base, then block until CI on the new head
# finishes. --rebase rebases the branch; the default merges the base in.
#   _gh_update_and_wait <repo|""> <num> <id> [--rebase]
#   → 0 + REPLY=<new head SHA> (REPLY="" if already up to date)
#     2 conflicting · 1 update failed or CI failed
_gh_update_and_wait() {
  local repo="$1" num="$2" id="$3"; shift 3
  local -a repo_flag upd=("$@"); [[ -n "$repo" ]] && repo_flag=(--repo "$repo")
  local $_GH_COLORS; _gh_palette 1
  REPLY=
  local old new out tries
  old=$(gh pr view "$num" "${repo_flag[@]}" --json headRefOid --jq .headRefOid </dev/null 2>/dev/null)
  print -r -- "  ${yellow}⟳${rst} ${cyan}${id}${rst}: base moved this run — ${dim}gh pr update-branch${upd:+ ${upd[*]}}${rst}"
  if ! out=$(gh pr update-branch "$num" "${repo_flag[@]}" "${upd[@]}" </dev/null 2>&1); then
    # gh prints "Cannot update PR branch due to conflicts" for both of its own
    # conflict checks (see update_branch.go); anything else is a real failure.
    [[ "$out" == *conflict* ]] && return 2
    print -r -- "  ${red}✗${rst} ${cyan}${id}${rst}: update-branch failed — ${out}"; return 1
  fi
  [[ "$out" == *up-to-date* ]] && { print -r -- "    ${dim}already up to date${rst}"; return 0 }

  tries=0
  while (( tries++ < 15 )); do
    new=$(gh pr view "$num" "${repo_flag[@]}" --json headRefOid --jq .headRefOid </dev/null 2>/dev/null)
    [[ -n "$new" && "$new" != "$old" ]] && break
    sleep 2
  done
  if [[ -z "$new" || "$new" == "$old" ]]; then
    print -r -- "  ${red}✗${rst} ${cyan}${id}${rst}: head did not move after update-branch — left open"; return 1
  fi

  # `gh pr checks --watch` errors out at once when no check has registered yet
  # (checks.go: "no checks reported"), so wait for the first one to appear.
  print -r -- "    ${dim}waiting for CI on ${new[1,7]}${rst}"
  tries=0
  until gh pr checks "$num" "${repo_flag[@]}" --json name --jq length </dev/null >/dev/null 2>&1; do
    if (( ++tries > 30 )); then
      print -r -- "    ${yellow}!${rst} no checks registered after 60s — merging without a CI wait"
      REPLY="$new"; return 0
    fi
    sleep 2
  done
  if ! gh pr checks "$num" "${repo_flag[@]}" --watch --fail-fast </dev/null; then
    print -r -- "  ${red}✗${rst} ${cyan}${id}${rst}: ${red}CI failed${rst} on the updated branch — left open"; return 1
  fi
  print -r -- "    ${green}✓${rst} CI passed on ${new[1,7]}"
  REPLY="$new"
}

# Offer to start Claude on each PR the batch left CONFLICTING. Runs after the
# batch, so Claude resolves against the base as it ends up, not mid-run.
# Claude runs in the foreground, one PR at a time, in a fresh worktree.
#   _gh_conflict_handoff <"repo\tnum\tbase\tmethod" lines>   (method = rebase|squash)
_gh_conflict_handoff() {
  local blob="$1"
  [[ -n "$blob" ]] || return 0
  local $_GH_COLORS; _gh_palette 1
  local here; here=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
  local r n b m id ans how
  print
  print -r -- "${bold}Conflicting PRs${rst} — gh pr update-branch can't resolve these:"
  # The list is read from fd 3 so stdin stays the terminal for read -k and
  # claude. Not </dev/tty: macOS kqueue rejects the /dev/tty alias with EINVAL,
  # and claude (Bun) crashes watching it ("EINVAL: invalid argument, kqueue").
  while IFS=$'\t' read -r -u 3 r n b m; do
    [[ -n "$n" ]] || continue
    id="${r}#${n}"
    if [[ -n "$r" && "$r" != "$here" ]]; then
      print -r -- "  ${yellow}!${rst} ${cyan}${id}${rst}: not this checkout's repo — resolve it from a checkout of ${r}"
      continue
    fi
    read -k 1 "ans?  Hand ${cyan}${id}${rst} to Claude to resolve? [y/${bold}N${rst}] "; print
    [[ "$ans" == [yY] ]] || { print -r -- "  ${dim}– left ${id} for later${rst}"; continue }
    if [[ "$m" == rebase ]]; then
      how="rebase it onto origin/${b}, resolve the conflicts, and push with --force-with-lease"
    else
      how="merge origin/${b} into it, resolve the conflicts, and push"
    fi
    _claude_pr_worktree "$n" "pr-${n}-conflicts" "PR #${n} conflicts with ${b} after other PRs merged into it. Work on its branch (gh pr checkout ${n}, unless this checkout is already on it), ${how}. Keep the intent of both sides, run the project's lint and tests before pushing, and do not merge the PR."
  done 3<<< "$blob"
}

# Confirm a selected set, then merge sequentially in selection order.
# y = this · N/other = skip · a = all remaining · q = stop.
#   _gh_batch_merge "<repo\tnum\ttitle lines>" <auto|rebase|squash> [gh pr merge flags...]
# The method and flags go to _gh_poll_merge unchanged.
_gh_batch_merge() {
  local blob="$1" method="$2"; shift 2
  local -a flags=("$@") repos nums titles
  local line r n t
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    IFS=$'\t' read -r r n t <<< "$line"
    [[ "$n" == <-> ]] || continue   # num must be digits; skip any misparse
    repos+=("$r"); nums+=("$n"); titles+=("$t")
  done <<< "$blob"
  local count=${#nums}
  (( count == 0 )) && { print -r -- "Nothing selected."; return 0 }

  local $_GH_COLORS; _gh_palette 1

  local i lbl maxw=0
  # Pre-compute the widest label so the summary's title column lines up.
  for (( i = 1; i <= count; i++ )); do
    lbl="${repos[$i]}#${nums[$i]}"
    (( ${#lbl} > maxw )) && maxw=${#lbl}
  done
  print -r -- "${bold}Selected $count PR(s)${rst} — will merge (${yellow}${method}${flags:+ ${flags[*]}}${rst}) in this order:"
  for (( i = 1; i <= count; i++ )); do
    lbl="${repos[$i]}#${nums[$i]}"
    printf "  %s%2d.%s %s%-*s%s  %s\n" "$dim" "$i" "$rst" "$cyan" "$maxw" "$lbl" "$rst" "${titles[$i]}"
  done
  print

  # moved: "repo:base" keys that took a merge this run (later PRs on the same
  # base get updated before merging). conflicts: "repo\tnum\tbase\tmethod" lines
  # for the Claude handoff after the loop.
  local all=false ans moved= conflicts= key
  for (( i = 1; i <= count; i++ )); do
    lbl="${repos[$i]}#${nums[$i]}"
    if ! $all; then
      read -k 1 "ans?Merge ${cyan}${lbl}${rst}? [${green}y${rst}/${bold}N${rst}/${yellow}a${rst}=all/${red}q${rst}=quit] "; print
      case "$ans" in
        a|A) all=true ;;
        y|Y) ;;
        q|Q) print -r -- "${yellow}Stopped${rst} — remaining left unmerged."; break ;;
        *)   print -r -- "  ${dim}– skipped ${lbl}${rst}"; continue ;;
      esac
    fi
    _gh_poll_merge "${repos[$i]}" "${nums[$i]}" "$moved" "$method" "${flags[@]}"
    case $? in
      0) key="${repos[$i]}:${reply[1]}"
         [[ " $moved " == *" $key "* ]] || moved+=" $key" ;;
      2) conflicts+="${repos[$i]}"$'\t'"${nums[$i]}"$'\t'"${reply[1]}"$'\t'"${reply[2]}"$'\n' ;;
    esac
  done
  _gh_conflict_handoff "$conflicts"
}

# fzf multi-select over current-repo PRs → TSV "repo<tab>num<tab>title" lines
# for the batch engine. List is sorted oldest→newest (safer bet for clean
# rebase/squash order). $1 = header verb; $2 = "1" to include external
# contributors' PRs (ghm -x), empty to hide them; remaining args = extra fzf
# flags (callers pass --layout=reverse so the cursor starts on the oldest PR, at
# the top, matching the sort direction).
#
# External PRs are EXCLUDED from the list by default, so ^a (select-all) cannot
# reach them at all. A banner on stderr reports what was withheld, so nothing is
# silently forgotten — hiding a contribution must not mean ghosting it. All
# stdout is the TSV the caller captures, hence stderr for the banner.
_gh_pr_multi_select() {
  local verb="$1" show_ext="$2"; shift 2
  local -a fzf_extra=("$@")
  local repo me
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
  _gh_me; me=$_GH_ME

  # jq emits the raw author (login + is_bot) as fields 2-3; the awk pass below
  # turns them into a trust verdict. Classifying in awk rather than jq is
  # deliberate: gh has no --arg, so $me cannot be passed into the jq program.
  local rows
  rows=$(gh pr list --limit 100 \
      --json number,title,headRefName,isDraft,statusCheckRollup,reviewDecision,createdAt,author,labels \
      --jq "${_GH_JQ_PR_DEFS}"'sort_by(.createdAt) | .[] | [
        "#\(.number)",
        (.author.login // "?"),
        (if .author.is_bot then "bot" else "user" end),
        ([.labels[].name | select(. == "merge:rebase" or . == "merge:squash")][0] // "merge:?" | ltrimstr("merge:")),
        (if .isDraft then "draft" else "ready" end),
        ci,
        rev,
        .headRefName[:25],
        .title[:50]
      ] | @tsv' 2>/dev/null)
  [[ -z "$rows" ]] && return 0

  # → "#num  <me|bot|EXT>  login  method  state  CI  rev  branch  title"
  # method = the merge:* label (rebase|squash), "?" without one; ghm then asks
  # unless pr-merge-method.py decides. The label alone keeps the list to one gh
  # call; running the script per listed PR would stall the picker.
  local classed
  classed=$(print -r -- "$rows" | awk -F'\t' -v me="$me" '
    { login = $2
      if (me != "" && login == me)                                          t = "me"
      else if ($3 == "bot" || login ~ /\[bot\]$/ || login ~ /^app\//)        t = "bot"
      else                                                                  t = "EXT"
      printf "%s\t%s\t%s", $1, t, login
      for (i = 4; i <= NF; i++) printf "\t%s", $i
      printf "\n" }')

  local ext_rows vis_rows
  ext_rows=$(print -r -- "$classed" | awk -F'\t' '$2 == "EXT"')
  vis_rows=$(print -r -- "$classed" | awk -F'\t' '$2 != "EXT"')

  local $_GH_COLORS; _gh_palette 2

  local shown="$classed"
  if [[ -z "$show_ext" ]]; then
    shown="$vis_rows"
    if [[ -n "$ext_rows" ]]; then
      local n caller; n=$(print -r -- "$ext_rows" | grep -c .)
      # funcstack[1] is this function, [2] its caller — so the hint names the
      # command the user actually typed.
      caller="${funcstack[2]:-ghm}"
      print -r -- "  ${alarm} ⚠ ${n} external PR(s) hidden ${rst} ${dim}— ${rst}${bold}${caller} -x${rst}${dim} to include${rst}" >&2
      print -r -- "$ext_rows" | awk -F'\t' '{ printf "      %s  %s  %s\n", $1, $3, $NF }' >&2
      print >&2
    fi
  fi
  if [[ -z "$shown" ]]; then
    print -r -- "  ${dim}No PRs to ${verb}-merge.${rst}" >&2
    return 0
  fi

  # Drop the raw login column, folding it into the trust token so the table stays
  # one-token-per-column (a `column -t` requirement — see the extraction caveat
  # in .claude/rules/fzf-picker-colorize-align.md). ⚠ is what _gh_paint reddens.
  print -r -- "$shown" | \
    awk -F'\t' '{ who = ($2 == "EXT") ? "⚠" $3 : $2
                  printf "%s\t%s", $1, who
                  for (i = 4; i <= NF; i++) printf "\t%s", $i
                  printf "\n" }' | \
    column -t -s $'\t' | \
    _gh_paint | \
    fzf --ansi --multi "${fzf_extra[@]}" \
        --header "Tab mark · ^a all · ⏎ confirm ${verb}-merge · ^t toggle preview · ^d/u scroll${show_ext:+ · ⚠ = EXTERNAL, needs typed confirm}" \
        --bind 'tab:toggle+down,btab:toggle+up' \
        --bind 'ctrl-a:select-all' \
        --bind 'ctrl-t:toggle-preview' \
        --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
        --preview 'GH_FORCE_TTY=1 gh pr view {1} && echo && echo "── Files ──" && gh pr diff {1} | git apply --stat 2>/dev/null' \
        --preview-window right:60%:wrap | \
    awk -v repo="$repo" '{num=$1; sub(/^#/,"",num); $1=$2=$3=$4=$5=$6=$7=""; sub(/^ +/,""); printf "%s\t%s\t%s\n", repo, num, $0}'
}

# ---- post-merge "go home" helper (ghm) -----------------------------
# When you merge the PR of the branch you're standing on, land on the (now
# updated) base branch. gh's --delete-branch already moves HEAD off the deleted
# local branch, but it does NOT pull, so the base is left behind origin. The PR
# number must be captured BEFORE the merge (gh moves HEAD during --delete-branch,
# after which `gh pr view` with no arg would resolve the base branch's PR, not
# yours).
_gh_current_pr() {
  git rev-parse --git-dir >/dev/null 2>&1 || return
  gh pr view --json number --jq .number </dev/null 2>/dev/null
}

# Act only if that PR is authoritatively MERGED — so this no-ops when you merge
# only other people's PRs, or skip your own at the confirm prompt.
#
# The guard is "this branch's PR is merged", NOT "…was merged by this run": it
# fires just as well when you were already standing on a branch merged days ago,
# since the branch is equally stale either way. That is deliberate but
# surprising, so the move is narrated rather than merely performed:
#   what  the switch + pull about to run
#   why   the PR authorising it, and whether THIS run merged it ($2 = the PR
#         numbers this invocation acted on) or it had already merged
#   kept  that the local branch survives, plus the command to delete it
# what/why print BEFORE the switch, so git's own "your branch is behind" chatter
# lands under an explanation instead of ahead of one.
_gh_home_if_merged() {
  local cur_pr="$1" acted="$2"
  [[ -n "$cur_pr" ]] || { _gh_pull_if_base_of_merged "$acted"; return }
  local info state base merged_at
  info=$(gh pr view "$cur_pr" --json state,baseRefName,mergedAt \
           --jq '"\(.state)\t\(.baseRefName)\t\(.mergedAt // "")"' </dev/null 2>/dev/null)
  state="${info%%$'\t'*}"; info="${info#*$'\t'}"
  base="${info%%$'\t'*}"; merged_at="${info#*$'\t'}"
  [[ "$state" == MERGED && -n "$base" ]] || { _gh_pull_if_base_of_merged "$acted"; return }
  local $_GH_COLORS; _gh_palette 1
  local cur; cur=$(git symbolic-ref --short -q HEAD 2>/dev/null)

  # "by this run" is decided by membership in the acted-on set, never by clocks:
  # local-vs-GitHub skew would misdate a merge landing seconds either side of the
  # run. The picker only ever lists OPEN PRs, so "was selected AND is now MERGED"
  # means this run merged it. The timestamp prints either way, as the ground
  # truth behind the label.
  local when
  if [[ -n "$acted" && " ${acted//$'\n'/ } " == *" ${cur_pr} "* ]]; then
    when="merged by this run"
  else
    when="already merged before this run"
  fi
  [[ -n "$merged_at" ]] && when="${when}, ${merged_at%%T*} ${${merged_at#*T}%:*}Z"

  if [[ "$cur" == "$base" ]]; then
    print -r -- "  ${green}⇣${rst} ${bold}what${rst}  already on ${cyan}${base}${rst} — ${dim}git pull --ff-only${rst}"
    print -r -- "    ${bold}why${rst}   PR ${cyan}#${cur_pr}${rst} is ${green}MERGED${rst} (${when}), so ${cyan}${base}${rst} has moved ahead"
    git pull --ff-only
    return
  fi

  print -r -- "  ${green}⇣${rst} ${bold}what${rst}  ${cyan}${cur:-detached HEAD}${rst} → ${cyan}${base}${rst} — ${dim}git switch ${base} && git pull --ff-only${rst}"
  print -r -- "    ${bold}why${rst}   this branch's PR ${cyan}#${cur_pr}${rst} is ${green}MERGED${rst} (${when}) — its commits are already on ${cyan}${base}${rst}"
  git switch "$base" 2>/dev/null || git checkout "$base" 2>/dev/null || {
    print -r -- "    ${yellow}!${rst}     couldn't switch (uncommitted changes?) — staying on ${cyan}${cur}${rst}"
    return 1
  }
  if [[ -n "$cur" ]] && git show-ref --verify --quiet "refs/heads/${cur}"; then
    print -r -- "    ${bold}kept${rst}  local branch ${cyan}${cur}${rst} — delete with ${dim}git branch -d ${cur}${rst}"
  fi
  git pull --ff-only
}

# Fallback for _gh_home_if_merged when the branch you're on has no merged PR:
# pull if it is the BASE of a PR this run merged. That is the usual case with
# worktrees — the PR's branch lives in a worktree and ghm runs from the main
# checkout on `main`, where `gh pr view` finds no PR at all. $1 = the PR numbers
# this invocation acted on; a selected PR that is now MERGED was merged by this
# run (the picker only lists OPEN PRs), so skipped ones never trigger a pull.
_gh_pull_if_base_of_merged() {
  local acted="$1" cur n base
  cur=$(git symbolic-ref --short -q HEAD 2>/dev/null) || return 0
  local $_GH_COLORS; _gh_palette 1
  for n in ${=acted}; do
    base=$(gh pr view "$n" --json state,baseRefName \
             --jq 'select(.state == "MERGED") | .baseRefName' </dev/null 2>/dev/null)
    [[ "$base" == "$cur" ]] || continue
    print -r -- "  ${green}⇣${rst} ${bold}what${rst}  on ${cyan}${cur}${rst} — ${dim}git pull --ff-only${rst}"
    print -r -- "    ${bold}why${rst}   this run merged PR ${cyan}#${n}${rst} into ${cyan}${cur}${rst}, so it has moved ahead"
    git pull --ff-only
    return
  done
}

# Interactive PR merge with each PR's recommended method (_gh_merge_method):
# rebase for two or more independent conventional commits, squash otherwise; a
# human-applied merge:* label overrides. When neither the script nor a label
# decides, ask (_gh_ask_method). A batch can mix both methods. To force a method,
# put a merge:* label on the PR; the git-plugin hook and check honour it too.
#
# No args → multi-select picker (Tab to mark several) → sequential merge in
# selection order. Arg form (ghm 123, via completion) merges that single PR
# through the same engine, without the per-PR y/N prompt. If the branch you're on has a merged PR — merged by this run or
# already merged when you started — you're left on an updated base branch, with
# the what/why printed first (see _gh_home_if_merged). If you're on the base of
# a PR this run merged, it pulls (see _gh_pull_if_base_of_merged).
#
# -x/--external includes external contributors' PRs in the picker (hidden by
# default). Either way, merging one requires a typed confirmation — including on
# the arg form, which skips the picker; the gate is in _gh_poll_merge.
ghm() {
  local cur_pr acted show_ext=
  while [[ "$1" == -x || "$1" == --external ]]; do show_ext=1; shift; done
  _gh_me   # before the picker's $(...), which needs the login to classify authors
  if [[ $# -eq 0 ]]; then
    local tsv; tsv=$(_gh_pr_multi_select rebase/squash "$show_ext" --layout=reverse)
    [[ -z "$tsv" ]] && return
    cur_pr=$(_gh_current_pr)
    acted=$(print -r -- "$tsv" | awk -F'\t' '{print $2}')
    _gh_batch_merge "$tsv" auto --delete-branch
  else
    # Same engine as the picker path, minus the y/N/a/q prompt: naming the PR
    # is the confirmation. So the trust gate, the draft prompt, the
    # mergeability wait, the update of a BEHIND branch and the conflict handoff
    # all apply here too.
    local num="${1%%\[*}"
    cur_pr=$(_gh_current_pr)
    acted="$num"
    _gh_poll_merge "" "$num" "" auto --delete-branch
    if (( $? == 2 )); then
      # The handoff reads tab-separated fields, and a leading empty one would
      # collapse, so name the repo.
      local here; here=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
      _gh_conflict_handoff "${here}"$'\t'"${num}"$'\t'"${reply[1]}"$'\t'"${reply[2]}"
    fi
  fi
  _gh_home_if_merged "$cur_pr" "$acted"
}

# ---- Read-only gh wrappers (view/diff/checkout/checks/run) -----------
# Shared pickers print the selected number/ID (empty string if cancelled).
# Each wrapper: no arg → interactive picker; arg → strip "123[label]" → "123".

# Pick an open PR; prints its number.
_gh_pr_pick() {
  gh pr list --limit 100 \
      --json number,title,headRefName,isDraft,statusCheckRollup,reviewDecision \
      --jq "${_GH_JQ_PR_DEFS}"'.[] | [
        "#\(.number)",
        (if .isDraft then "draft" else "ready" end),
        ci,
        rev,
        .headRefName[:25],
        .title[:50]
      ] | @tsv' | \
    column -t -s $'\t' | \
    _gh_paint | \
    fzf --ansi --tac \
        --preview 'GH_FORCE_TTY=1 gh pr view {1} && echo && echo "── Files ──" && gh pr diff {1} | git apply --stat 2>/dev/null' \
        --preview-window right:60%:wrap \
        --bind 'ctrl-t:toggle-preview' \
        --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
        --header '⏎ select PR | ^t toggle preview | ^d/u scroll' | \
    awk '{n=$1; sub(/^#/,"",n); print n}'
}

# Pick an open issue; prints its number.
_gh_issue_pick() {
  gh issue list --limit 100 \
      --json number,title,labels,updatedAt \
      --jq '.[] | [
        "#\(.number)",
        (if (.labels | length) > 0 then (.labels | map(.name) | join(","))[:20] else "-" end),
        (.updatedAt | fromdateiso8601 | strftime("%Y-%m-%d")),
        .title[:60]
      ] | @tsv' | \
    column -t -s $'\t' | \
    _gh_paint | \
    fzf --ansi \
        --preview 'GH_FORCE_TTY=1 gh issue view {1}' \
        --preview-window right:60%:wrap \
        --bind 'ctrl-t:toggle-preview' \
        --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
        --header '⏎ select issue | ^t toggle preview | ^d/u scroll' | \
    awk '{n=$1; sub(/^#/,"",n); print n}'
}

# Pick a recent workflow run; prints its databaseId (ID is field 1).
_gh_run_pick() {
  gh run list --limit 50 \
      --json databaseId,status,conclusion,workflowName,headBranch,displayTitle \
      --jq '.[] | [
        (.databaseId|tostring),
        (if .status != "completed" then "⏳\(.status)"
         elif .conclusion == "success" then "✓ok"
         elif .conclusion == "failure" then "✗fail"
         else "•\(.conclusion // .status)" end),
        .workflowName[:25],
        .headBranch[:20],
        .displayTitle[:45]
      ] | @tsv' 2>/dev/null | \
    column -t -s $'\t' | \
    _gh_paint | \
    fzf --ansi \
        --preview 'GH_FORCE_TTY=1 gh run view {1}' \
        --preview-window right:65%:wrap \
        --bind 'ctrl-t:toggle-preview' \
        --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
        --header '⏎ select run | ^t toggle preview | ^d/u scroll' | \
    awk '{print $1}'
}

# Pick a workflow (gh ships no dynamic completion for the name/id argument);
# prints its id (id is field 1).
_gh_workflow_pick() {
  gh workflow list --limit 100 \
      --json id,name,state \
      --jq '.[] | [
        (.id|tostring),
        (if .state == "active" then "✓active" else "✗\(.state)" end),
        .name[:50]
      ] | @tsv' 2>/dev/null | \
    column -t -s $'\t' | \
    _gh_paint | \
    fzf --ansi \
        --preview 'GH_FORCE_TTY=1 gh workflow view {1}' \
        --preview-window right:65%:wrap \
        --bind 'ctrl-t:toggle-preview' \
        --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
        --header '⏎ select workflow | ^t toggle preview | ^d/u scroll' | \
    awk '{print $1}'
}

# Resolve a wrapper's target: $1 = picker fn, $2 = optional CLI arg.
_gh_pick_arg() { if [[ -z "$2" ]]; then "$1"; else print -r -- "${2%%\[*}"; fi }

ghv()  { local p=$(_gh_pick_arg _gh_pr_pick    "$1"); [[ -n "$p" ]] && gh pr view "$p"; }       # gh pr view
ghd()  { local p=$(_gh_pick_arg _gh_pr_pick    "$1"); [[ -n "$p" ]] && gh pr diff "$p"; }       # gh pr diff
ghco() { local p=$(_gh_pick_arg _gh_pr_pick    "$1"); [[ -n "$p" ]] && gh pr checkout "$p"; }   # gh pr checkout
ghck() { local p=$(_gh_pick_arg _gh_pr_pick    "$1"); [[ -n "$p" ]] && gh pr checks "$p"; }     # gh pr checks
ghub() { local p=$(_gh_pick_arg _gh_pr_pick    "$1"); [[ -n "$p" ]] && gh pr update-branch "$p"; } # gh pr update-branch
ghiv() { local p=$(_gh_pick_arg _gh_issue_pick "$1"); [[ -n "$p" ]] && gh issue view "$p"; }    # gh issue view (cf. ghi → Claude)
ghr()  { local p=$(_gh_pick_arg _gh_run_pick   "$1"); [[ -n "$p" ]] && gh run view "$p"; }      # gh run view
ghw()  { local p=$(_gh_pick_arg _gh_run_pick   "$1"); [[ -n "$p" ]] && gh run watch "$p"; }     # gh run watch

# gh workflow run: no positional workflow → fzf-pick; a leading non-flag arg is
# taken as the workflow (id/name/file). Trailing flags (--ref, -f k=v, -F …)
# pass straight through to `gh workflow run`.
ghwr() {
  local wf
  if [[ -n "$1" && "$1" != -* ]]; then
    wf="${1%%\[*}"; shift
  else
    wf=$(_gh_workflow_pick)
  fi
  [[ -z "$wf" ]] && return 0
  gh workflow run "$wf" "$@"
}

# Renovate rebase/retry from the terminal: tick the PR body's
# "<!-- rebase-check -->" box — the same box the PR page shows — so the next
# Renovate run rebases the branch. No arg → fzf multi-select over this repo's
# open PRs that carry an unticked box (^a = all); args → those PR numbers.
# The box acts only when Renovate next runs. -r also dispatches the self-hosted
# runner's renovate.yml — $GH_RENOVATE_RUNNER, else picked by this repo's owner
# (laurigates → laurigates/gitops, ForumViriumHelsinki → .../infrastructure);
# that run covers every repo of the owner (20–45 min, billed), hence opt-in.
ghrr() {
  local run=
  while [[ "$1" == -r || "$1" == --run ]]; do run=1; shift; done
  local unticked='- [ ] <!-- rebase-check -->' ticked='- [x] <!-- rebase-check -->'
  local $_GH_COLORS; _gh_palette 1
  local -a nums
  if (( $# )); then
    nums=("${@%%\[*}")
  else
    nums=(${(f)"$(gh pr list --limit 100 --json number,title,headRefName,body \
        --jq '.[] | select(.body | contains("- [ ] <!-- rebase-check -->"))
              | "#\(.number)\t\(.headRefName[:40])\t\(.title[:60])"' 2>/dev/null |
      column -t -s $'\t' |
      fzf --multi --layout=reverse \
          --header 'Tab mark · ^a all · ⏎ tick Renovate rebase box' \
          --bind 'tab:toggle+down,btab:toggle+up,ctrl-a:select-all' \
          --preview 'GH_FORCE_TTY=1 gh pr view {1}' --preview-window right:60%:wrap |
      awk '{ sub(/^#/, "", $1); print $1 }')"})
  fi
  (( ${#nums} )) || { print -r -- "  ${dim}No unticked Renovate PRs selected.${rst}"; return 0 }
  local n body
  for n in $nums; do
    body=$(gh pr view "$n" --json body --jq .body </dev/null) || continue
    if [[ "$body" != *"$unticked"* ]]; then
      print -r -- "  ${dim}– #${n}: no unticked rebase box (not Renovate, or already requested)${rst}"
      continue
    fi
    if print -r -- "${body/"$unticked"/$ticked}" | gh pr edit "$n" --body-file - >/dev/null; then
      print -r -- "  ${green}✓${rst} ${cyan}#${n}${rst}: rebase requested"
    else
      print -r -- "  ${red}✗${rst} ${cyan}#${n}${rst}: body edit failed"
    fi
  done
  # Each owner has its own self-hosted runner and bot; dispatching the wrong
  # one bills a full run that never touches this repo.
  local owner runner="$GH_RENOVATE_RUNNER"
  if [[ -z "$runner" ]]; then
    owner=$(gh repo view --json owner --jq .owner.login 2>/dev/null)
    case "$owner" in
      laurigates)          runner=laurigates/gitops ;;
      ForumViriumHelsinki) runner=ForumViriumHelsinki/infrastructure ;;
      *) print -r -- "  ${dim}no known Renovate runner for '${owner}' — set GH_RENOVATE_RUNNER${rst}"
         return 0 ;;
    esac
  fi
  if [[ -n "$run" ]]; then
    gh workflow run renovate.yml -R "$runner" && \
      print -r -- "  ${green}⟳${rst} dispatched renovate.yml on ${runner}"
  else
    print -r -- "  ${dim}acts on the next Renovate run — ghrr -r to dispatch ${runner} now${rst}"
  fi
}

# release-please across your repos + orgs: list open release PRs (label
# 'autorelease: pending' — release-please's own marker, precise across the
# different release bots), preview the release notes (PR body), multi-select
# with Tab, then squash-merge sequentially in selection order. Extra args add
# --owner scopes.
ghrp() {
  local -a owners owner_args
  local o
  for o in "${(@f)$(gh api user --jq '.login' 2>/dev/null)}" \
           "${(@f)$(gh api user/orgs --jq '.[].login' 2>/dev/null)}" "$@"; do
    [[ -n "$o" ]] && { owners+=("$o"); owner_args+=(--owner "$o") }
  done

  # These are bot PRs by construction (the release-please label), but the scope
  # spans every org you belong to — where someone else can label a PR. So carry
  # an author column here too. NOTE: in `gh search prs` output an App bot reports
  # is_bot=FALSE and type="Bot" (unlike `gh pr list`, which reports is_bot=true
  # and login "app/<name>"), which is why the awk below keys on type as well.
  # Merging is gated regardless, in _gh_poll_merge.
  local me list
  _gh_me; me=$_GH_ME
  list=$(gh search prs --state open --label 'autorelease: pending' \
           "${owner_args[@]}" --limit 100 \
           --json repository,number,title,author \
           --jq '.[] | [.repository.nameWithOwner, "#\(.number)",
                        (.author.login // "?"), (.author.type // "User"), .title] | @tsv' 2>/dev/null)
  if [[ -z "$list" ]]; then
    echo "No open release-please PRs found in: ${(j:, :)owners}"
    return 0
  fi

  # → "repo  #num  <me|bot|⚠login>  title"  (⚠ is what _gh_paint reddens)
  local display
  display=$(print -r -- "$list" | awk -F'\t' -v me="$me" '
    { login = $3
      if (me != "" && login == me)                                     who = "me"
      else if ($4 == "Bot" || login ~ /\[bot\]$/ || login ~ /^app\//)   who = "bot"
      else                                                             who = "⚠" login
      printf "%s\t%s\t%s", $1, $2, who
      for (i = 5; i <= NF; i++) printf "\t%s", $i
      printf "\n" }')

  local selections
  selections=$(print -r -- "$display" | column -t -s $'\t' | _gh_paint | \
      fzf --ansi --multi --tac \
          --header 'Tab mark · ^a all · ⏎ confirm squash-merge · ^t toggle preview · ^d/u scroll · ⚠ = EXTERNAL' \
          --bind 'tab:toggle+down,btab:toggle+up' \
          --bind 'ctrl-a:select-all' \
          --bind 'ctrl-t:toggle-preview' \
          --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
          --preview 'GH_FORCE_TTY=1 gh pr view {2} --repo {1}' \
          --preview-window right:60%:wrap)
  [[ -z "$selections" ]] && { print -r -- "Nothing selected."; return 0 }

  # columned selection → "repo<TAB>num<TAB>title" for the batch engine
  local tsv
  tsv=$(print -r -- "$selections" | \
    awk '{repo=$1; num=$2; sub(/^#/,"",num); $1=$2=$3=""; sub(/^ +/,""); printf "%s\t%s\t%s\n", repo, num, $0}')
  _gh_batch_merge "$tsv" squash
}
