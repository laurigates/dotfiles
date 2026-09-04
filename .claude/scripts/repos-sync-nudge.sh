#!/usr/bin/env bash
# repos-sync-nudge.sh — SessionStart freshness check for a shared-config repo.
#
# Installed in repos that hold CLAUDE.md guidance and .claude/ rules inherited
# by every project underneath them (~/repos, laurigates/comfyui-nodes). A stale
# checkout silently runs old rules, and unpushed edits silently never reach the
# other sessions/machines, so the commit → PR → merge → pull cycle has to stay
# prompt. This hook is the nudge that keeps it prompt.
#
# Repo-agnostic: it locates its own repo from BASH_SOURCE, so the same file is
# dropped into each such repo (self-contained on purpose — these repos are
# cloned to other hosts where a cross-repo path would not resolve).
#
# Behaviour:
#   * Debounced `git fetch` (default 15 min) so most session starts cost nothing.
#   * When the tree is CLEAN, on main, with no unpushed commits and no coworker
#     markers, it fast-forwards automatically (`git merge --ff-only`, no network)
#     and says so. This is the half that needs no judgment.
#   * Every other state — dirty tree, unpushed commits, other branch, coworker
#     marker present — is REPORTED ONLY. A dirty tree is exactly the "another
#     agent is mid-work here" signal, and nothing is touched then.
#   * After a SUCCESSFUL fast-forward only, an optional per-repo hook
#     .claude/scripts/post-sync.sh is run and its output printed. A pull is not
#     the same thing as the pulled content being in effect — the chezmoi source
#     repo uses this to run `chezmoi apply`, since a rule that is pulled but
#     never applied does nothing. Keeping the hook generic is what lets this
#     script stay byte-identical across every repo it is dropped into.
#
# Pulled files land for the NEXT session; an already-running session does not
# re-read them. Same model as claude-plugins-refresh.sh.
#
#   --force   ignore the debounce stamp (manual runs / verification)
#
# Env knobs:
#   REPOS_SYNC_NUDGE_INTERVAL_MINUTES  fetch debounce window (default 15)
#   REPOS_SYNC_NUDGE_NO_PULL=1         report only; never fast-forward
set -uo pipefail

INTERVAL_MIN="${REPOS_SYNC_NUDGE_INTERVAL_MINUTES:-15}"

# Repo root = two levels up from .claude/scripts/. Never `cd`; use `git -C`.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${HERE}/../.." && pwd)"
LABEL="$(basename "$REPO")"
STAMP="${HOME}/.cache/repos-sync-nudge.${LABEL}.stamp"

force=0
[ "${1:-}" = "--force" ] && force=1

git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || exit 0

# --- debounced fetch (network) ------------------------------------------------
now=$(date +%s)
interval_s=$(( INTERVAL_MIN * 60 ))
do_fetch=1
if [ "$force" -eq 0 ] && [ -f "$STAMP" ]; then
  last="$(cat "$STAMP" 2>/dev/null || echo 0)"
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  [ $(( now - last )) -lt "$interval_s" ] && do_fetch=0
fi
if [ "$do_fetch" -eq 1 ]; then
  mkdir -p "$(dirname "$STAMP")"
  printf '%s\n' "$now" > "$STAMP"   # stamp first: concurrent starts don't all fetch
  timeout 20 git -C "$REPO" fetch --quiet origin main >/dev/null 2>&1 || true
fi

# --- read state ---------------------------------------------------------------
branch="$(git -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
dirty="$(git -C "$REPO" status --porcelain 2>/dev/null)"
git -C "$REPO" rev-parse --verify --quiet origin/main >/dev/null 2>&1 || exit 0
behind="$(git -C "$REPO" rev-list --count HEAD..origin/main 2>/dev/null || echo 0)"
ahead="$(git -C "$REPO" rev-list --count origin/main..HEAD 2>/dev/null || echo 0)"

# Coworker marker (the .git/.claude-session-* convention used by
# git-plugin:git-coworker-check). Present = another agent claims this checkout.
gitdir="$(git -C "$REPO" rev-parse --absolute-git-dir 2>/dev/null || echo '')"
coworker=0
if [ -n "$gitdir" ] && compgen -G "${gitdir}/.claude-session-*" >/dev/null 2>&1; then
  coworker=1
fi

# --- act, or report -----------------------------------------------------------
# Auto fast-forward only when nothing could be lost and nobody else is working.
if [ "$branch" = "main" ] && [ -z "$dirty" ] && [ "$ahead" -eq 0 ] \
   && [ "$behind" -gt 0 ] && [ "$coworker" -eq 0 ] \
   && [ "${REPOS_SYNC_NUDGE_NO_PULL:-0}" != "1" ]; then
  if git -C "$REPO" merge --ff-only origin/main >/dev/null 2>&1; then
    echo "${LABEL}/: fast-forwarded ${behind} commit(s) from origin/main — inherited rules refreshed (effective next session)."
    post="${REPO}/.claude/scripts/post-sync.sh"
    if [ -x "$post" ]; then
      if out="$(timeout 60 bash "$post" 2>&1)"; then
        [ -n "$out" ] && printf '%s\n' "$out"
      else
        echo "${LABEL}/: post-sync.sh exited non-zero — the pull landed, but the repo's post-sync step did not complete."
        [ -n "$out" ] && printf '%s\n' "$out"
      fi
    fi
    exit 0
  fi
  echo "${LABEL}/: ${behind} commit(s) behind origin/main; auto fast-forward failed — run: git -C ${REPO} pull --ff-only"
  exit 0
fi

msgs=()
[ "$behind" -gt 0 ] && msgs+=("${behind} commit(s) behind origin/main — run: git -C ${REPO} pull --ff-only")
[ "$ahead" -gt 0 ] && msgs+=("${ahead} unpushed commit(s) on ${branch} — push and open a PR so other projects inherit them")
if [ -n "$dirty" ]; then
  files="$(printf '%s\n' "$dirty" | awk '{print $NF}' | paste -sd' ' -)"
  msgs+=("uncommitted changes (${files}) — commit → PR → merge → pull promptly; shared rules only take effect once merged")
fi

[ "${#msgs[@]}" -eq 0 ] && exit 0

if [ "$coworker" -eq 1 ]; then
  echo "${LABEL}/ (another Claude session has claimed this checkout — do not stash/reset; report only):"
else
  echo "${LABEL}/ shared-config repo:"
fi
for m in "${msgs[@]}"; do echo "  - ${m}"; done
exit 0
