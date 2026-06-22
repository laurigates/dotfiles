#!/usr/bin/env bash
# claude-plugins-refresh.sh — debounced, NON-BLOCKING marketplace freshness.
#
# Registered as a user-level SessionStart hook (via the chezmoi overlay
# exact_dot_claude/modify_settings.json and the repo-root .claude/settings.json).
# Claude Code's plugin auto-update is startup-only with no time interval, so
# long-lived sessions never refresh — the root cause of the manual
# `claude plugin marketplace update` habit. This hook closes that gap WITHOUT
# slowing startup:
#
#   * Debounced by a stamp file — acts at most once per refresh interval
#     (default 4h), so it costs nothing on the many session starts in between.
#   * The marketplace update runs BACKGROUNDED + detached (nohup) — startup is
#     never blocked, and the child survives the hook process exiting.
#   * When the window elapses it also prints the plugin / env-flag audit nudge.
#
# Updates take effect on the NEXT session (or /reload-plugins) — the same model
# as Claude Code's own startup auto-update. Plugin-provided SessionStart hooks
# (e.g. session-plugin's spinup nudge) are a separate source and fire alongside
# this one; this hook does not replace them.
#
#   --force   ignore the debounce stamp (manual runs / verification)
#
# Env knobs:
#   CLAUDE_PLUGINS_REFRESH_INTERVAL_HOURS  debounce window in hours (default 4)
#   CLAUDE_PLUGINS_REFRESH_SELF_UPDATE=1   also run `claude update` in the bg job
set -uo pipefail

INTERVAL_HOURS="${CLAUDE_PLUGINS_REFRESH_INTERVAL_HOURS:-4}"
STAMP="${HOME}/.cache/claude-plugins-refresh.stamp"
LOG="${TMPDIR:-/tmp}/claude-plugins-refresh.log"
MARKETPLACE="laurigates-claude-plugins"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

force=0
[ "${1:-}" = "--force" ] && force=1

# --- debounce -----------------------------------------------------------------
now=$(date +%s)
interval_s=$(( INTERVAL_HOURS * 3600 ))
if [ "$force" -eq 0 ] && [ -f "$STAMP" ]; then
  last="$(cat "$STAMP" 2>/dev/null || echo 0)"
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  if [ $(( now - last )) -lt "$interval_s" ]; then
    exit 0   # within debounce window — silent no-op
  fi
fi

# Stamp FIRST so rapid/concurrent session starts don't all fire the refresh.
mkdir -p "$(dirname "$STAMP")"
printf '%s\n' "$now" > "$STAMP"

# --- background marketplace refresh (never blocks startup) --------------------
# nohup + redirected stdio + disown detaches the child so it keeps running after
# this hook process exits at the end of SessionStart.
if command -v claude >/dev/null 2>&1; then
  # The bash -c body is single-quoted ON PURPOSE: $REFRESH_* must expand in the
  # detached child (from the exported env below), not in this parent shell.
  # shellcheck disable=SC2016
  REFRESH_MARKETPLACE="$MARKETPLACE" \
  REFRESH_LOG="$LOG" \
  REFRESH_SELF_UPDATE="${CLAUDE_PLUGINS_REFRESH_SELF_UPDATE:-0}" \
  nohup bash -c '
    {
      echo "=== $(date "+%Y-%m-%d %H:%M:%S") refresh start ==="
      CLAUDECODE= claude plugin marketplace update "$REFRESH_MARKETPLACE" 2>&1
      if [ "$REFRESH_SELF_UPDATE" = "1" ]; then
        echo "--- claude update ---"
        CLAUDECODE= claude update 2>&1
      fi
      echo "=== $(date "+%Y-%m-%d %H:%M:%S") refresh done ==="
    } >>"$REFRESH_LOG" 2>&1
  ' >/dev/null 2>&1 &
  disown 2>/dev/null || true
fi

# --- audit nudge (fast; foreground) -------------------------------------------
audit="${HERE}/claude-plugins-audit.sh"
if [ -x "$audit" ]; then
  bash "$audit" || true
fi

exit 0
