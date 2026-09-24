# Git Hazards — Verify the Content, Not the Exit Code

Promoted to a skill: invoke `git-plugin:git-local-hazards` when a local git
result looks wrong, or before follow-up work on a squash-merged branch — it
carries the six traps (orphans after a squash-merge, stray local-`main`
commits, clean merges and rebases that break the build, atomic `git add`
aborts, a coworker's mid-flight commit, `reset --hard` recovery from
pre-commit stashes), each with its check and fix. Sibling:
`pr-merge-hazards.md` (GitHub PR/merge).

The law: **a green git command is not proof the result is correct** — exit 0
is a claim about mechanics, not content. Gates to apply inline:

- **Cut PR branches from the remote, always:**
  `git fetch origin && git switch -c <branch> origin/main`.
- **Before the second push to any branch in a long session**, run
  `gh pr list --head "$(git branch --show-current)" --json number,state` — a
  merged PR cannot take new commits.
- **One pathspec per `git add`**, or only confirmed-present paths; a bad
  pathspec stages nothing.
- **`git status` before `reset --hard`/`checkout`/`restore`/`clean`**;
  `git stash -u` anything present.
- **A staged file "vanished"** → `git log --oneline -3` and
  `git log -1 -- <path>` first; a coworker probably committed it. Don't
  blind-restore.
