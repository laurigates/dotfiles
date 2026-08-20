# Repo Deletion Safety

Promoted to a skill: invoke `git-plugin:git-repo-delete-check` before `rm -rf`'ing
a git checkout — it carries the `git remote -v` preflight, the local-only stop
condition, the three backup options in increasing destructiveness (push to a new
remote / date-stamped tar / delete outright) plus the tar default for a generic
"go", and the uncommitted-changes / unpushed-commits / stashes / upstream-less-branches
conditions to surface even when a remote does exist.

Enforced automatically by `hooks-plugin:repo-deletion-safety.sh` (PreToolUse on
Bash, exit 2 on `rm -rf` of a repo with no remote or an unpushed one). It
self-extinguishes — pushing, or writing the dated tar backup, clears the block
on the retry — so there is nothing to override; opt out only via
`CLAUDE_HOOKS_DISABLE_REPO_DELETION_SAFETY=1` exported from the operator's own
shell, never as an inline prefix. The hook is the automatic backstop; the skill
is the surface to invoke deliberately once a deletion is planned.
