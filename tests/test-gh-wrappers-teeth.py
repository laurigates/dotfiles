#!/usr/bin/env python3
"""Teeth check for tests/test-gh-wrappers.zsh.

Breaks one guard at a time in private_dot_config/zsh/gh-wrappers.zsh and
requires the suite to notice. A mutation the suite still passes on means an
assertion was weakened or removed.

Usage: tests/test-gh-wrappers-teeth.py [--zsh <path to zsh>]

How a run goes
--------------
The tracked source file is only read. Each mutant is written to a temporary
directory, and the suite sources it through GH_WRAPPERS_SRC.

1. The suite runs on an unmutated copy and must be green. If it is not, no
   mutation result would mean anything, so the check stops there.
2. For each mutation, the target text must occur exactly once in the source.
   Any other count is a failure: after a refactor the mutation has to be
   re-pointed, not dropped.
3. The suite runs on the mutant. The mutation is KILLED when the assertion
   named in its `expect` field is among the failures. The other outcomes fail
   the check:
     SURVIVED  no assertion failed
     MISSED    assertions failed, but not the expected one
     BROKEN    the suite stopped without reporting any assertion, e.g. the
               mutant does not parse

Exit status: 0 when every mutation is KILLED, 1 otherwise.

It runs the suite once per mutation, so it is a separate mise task
(`mise run test:gh-wrappers-teeth`) and not part of `mise run test`.
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SOURCE = REPO / "private_dot_config/zsh/gh-wrappers.zsh"
SUITE = REPO / "tests/test-gh-wrappers.zsh"

# (name, target text, replacement, fragment of an assertion that must fail)
MUTATIONS = [
    ("trust gate lets everyone through",
     '    *)        _gh_confirm_external "$repo" "$num" "$login" "$trust" "$title" ;;',
     '    *)        return 0 ;;',
     "external PR: a keypress-style 'y' does not merge"),
    ("trust gate stops bots too",
     '    self|bot) return 0 ;;',
     '    self) return 0 ;;',
     "bot release PRs merge without the typed confirmation"),
    ("merge not pinned to the tested head",
     '    [[ -n "$REPLY" ]] && pin=(--match-head-commit "$REPLY")',
     '    :',
     "second PR merges pinned to the head CI ran on"),
    ("no update when the base moved or is BEHIND",
     '  if [[ " $moved " == *" ${repo}:${base} "* || "$mss" == BEHIND ]]; then',
     '  if false; then',
     "second PR, same base: branch updated first"),
    ("the moved-base check ignores the repo",
     '  if [[ " $moved " == *" ${repo}:${base} "* || "$mss" == BEHIND ]]; then',
     '  if [[ " $moved " == *":${base} "* || "$mss" == BEHIND ]]; then',
     "a merge in one repo does not update a PR in another"),
    ("external PRs not hidden from the picker",
     '    shown="$vis_rows"',
     '    shown="$classed"',
     "external PR is hidden by default"),
    ("conflicting state ignored",
     '  if [[ "$state" == CONFLICTING ]]; then',
     '  if [[ "$state" == NEVER ]]; then',
     "conflicting: not merged"),
    ("draft state ignored",
     '  if [[ "$draft" == true ]]; then',
     '  if [[ "$draft" == never ]]; then',
     "draft, 's': not merged"),
    ("CI result on the updated head ignored",
     '  if ! gh pr checks "$num" "${repo_flag[@]}" --watch --fail-fast </dev/null; then',
     '  if false; then',
     "CI fails on the updated head: not merged"),
    ("method always squash",
     '    method=$(_gh_merge_method "$repo" "$num")',
     '    method=squash',
     "merge:rebase label merges with --rebase"),
    ("a merge is not recorded as moving the base",
     '         [[ " $moved " == *" $key "* ]] || moved+=" $key" ;;',
     '         : ;;',
     "second PR, same base: branch updated first"),
    ("explicit method not checked against the recommendation",
     '    _gh_method_check "$repo" "$num" "$want" || return 3',
     '    :',
     "explicit method against the recommendation, 'n': not merged"),
    ("ghrp merges with rebase",
     '  _gh_batch_merge "$tsv" squash',
     '  _gh_batch_merge "$tsv" rebase',
     "release PR in an org repo: --repo and --squash"),
    ("ghrp: a bot in search results is not recognised",
     '      else if ($4 == "Bot" || login ~ /\\[bot\\]$/ || login ~ /^app\\//)   who = "bot"',
     '      else if (login ~ /^app\\//)   who = "bot"',
     "a bot row carries no warning marker"),
    ("ghrp: a non-bot author is not marked",
     '      else                                                             who = "⚠" login',
     '      else                                                             who = login',
     "a non-bot author is listed with the warning marker"),
    ("ghrp: own login is not recognised",
     '      if (me != "" && login == me)                                     who = "me"',
     '      if (0)                                                           who = "me"',
     "own PR is listed as me"),
    ("ghrp: the selected row loses its repo",
     'printf "%s\\t%s\\t%s\\n", repo, num, $0}\')',
     'printf "%s\\t%s\\t%s\\n", "", num, $0}\')',
     "release PR in the user's repo: --repo and --squash"),
    ("ghrp: the author column stays in the title",
     '    awk \'{repo=$1; num=$2; sub(/^#/,"",num); $1=$2=$3="";',
     '    awk \'{repo=$1; num=$2; sub(/^#/,"",num); $1=$2="";',
     "the selected row's title reaches the summary whole"),
    ("ghrp: the release label is not searched for",
     "  list=$(gh search prs --state open --label 'autorelease: pending' \\",
     "  list=$(gh search prs --state open \\",
     "a PR without the release label is not listed"),
    ("ghrp: the owner scopes are not passed",
     '    [[ -n "$o" ]] && { owners+=("$o"); owner_args+=(--owner "$o") }',
     '    [[ -n "$o" ]] && { owners+=("$o") }',
     "a PR outside the user's login and orgs is not found"),
    ("ghrp: owners given as arguments are dropped",
     '''"${(@f)$(gh api user/orgs --jq '.[].login' 2>/dev/null)}" "$@"; do''',
     '''"${(@f)$(gh api user/orgs --jq '.[].login' 2>/dev/null)}"; do''',
     "an owner given as an argument is searched too"),
    ("ghrp: an empty search opens the picker",
     '  if [[ -z "$list" ]]; then',
     '  if false; then',
     "empty search: the picker is not opened"),
    # The two colour mutations change one of several identical declaration
    # lines, so each target includes the lines above it to occur once.
    ("a colour declaration expands an unset parameter (#612)",
     '  reply=()\n'
     '  local -a repo_flag; [[ -n "$repo" ]] && repo_flag=(--repo "$repo")\n'
     '  local id="${repo}#${num}"\n'
     '  local green red yellow cyan magenta dim bold rst alarm; _gh_palette 1',
     '  reply=()\n'
     '  local -a repo_flag; [[ -n "$repo" ]] && repo_flag=(--repo "$repo")\n'
     '  local id="${repo}#${num}"\n'
     '  local $_GH_COLORS; _gh_palette 1',
     "without the file's globals: ghm does not print the shell's parameters"),
    ("a colour is missing from one declaration",
     '  local repo="$1" num="$2" want="$3" rec ans\n'
     '  local green red yellow cyan magenta dim bold rst alarm; _gh_palette 1',
     '  local repo="$1" num="$2" want="$3" rec ans\n'
     '  local green red yellow cyan magenta dim bold rst; _gh_palette 1',
     "every _gh_palette call follows a literal declaration of all colours"),
]

SUMMARY = re.compile(r"^Passed: (\d+)  Failed: (\d+)$", re.M)


def run_suite(zsh, source):
    """Run the suite against `source`. Returns (exit status, failed assertions, output)."""
    env = dict(os.environ, GH_WRAPPERS_SRC=str(source))
    r = subprocess.run([zsh, str(SUITE)], capture_output=True, env=env, timeout=600)
    out = r.stdout.decode("utf-8", "replace") + r.stderr.decode("utf-8", "replace")
    failed = [line.strip() for line in out.splitlines() if line.startswith("  ✗")]
    return r.returncode, failed, out


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--zsh", default="zsh", help="zsh to run the suite with (default: zsh on PATH)")
    args = ap.parse_args()

    orig = SOURCE.read_text(encoding="utf-8")
    problems = 0
    with tempfile.TemporaryDirectory(prefix="gh-wrappers-teeth.") as tmp:
        copy = Path(tmp) / "gh-wrappers.zsh"

        copy.write_text(orig, encoding="utf-8")
        status, failed, out = run_suite(args.zsh, copy)
        summary = SUMMARY.search(out)
        if status != 0 or failed or not summary or summary.group(2) != "0":
            print("The suite is not green on the unmutated source; no mutation was run.")
            print(out.rstrip())
            return 1
        print(f"unmutated: {summary.group(0)}")

        for name, old, new, expect in MUTATIONS:
            count = orig.count(old)
            if count != 1:
                print(f"NOTARGET  {name}: target occurs {count} times, expected 1")
                problems += 1
                continue
            copy.write_text(orig.replace(old, new), encoding="utf-8")
            status, failed, out = run_suite(args.zsh, copy)
            if not SUMMARY.search(out):
                verdict = "BROKEN"
            elif not failed:
                verdict = "SURVIVED"
            elif not any(expect in line for line in failed):
                verdict = "MISSED"
            else:
                verdict = "KILLED"
            if verdict != "KILLED":
                problems += 1
            print(f"{verdict}  {name}  (exit {status}, {len(failed)} failing)")
            if verdict == "MISSED":
                print(f"        expected to fail: {expect}")
            if verdict == "BROKEN":
                for line in out.rstrip().splitlines()[-5:]:
                    print(f"        {line[:110]}")
            for line in failed:
                print(f"        {line[:110]}")

    print()
    if problems:
        print(f"{problems} of {len(MUTATIONS)} mutations were not killed.")
        return 1
    print(f"All {len(MUTATIONS)} mutations killed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
