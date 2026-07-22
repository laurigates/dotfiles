#!/usr/bin/env bash
# home-audit.sh — deterministic $HOME top-level hygiene sweep.
#
# Enumerates the in-scope top-level entries of $HOME, reports the DELTA since the
# last run, and flags known-junk patterns. It NEVER deletes anything — judgment
# (classify / delete / relocate) stays with the human or a full agent sweep.
# This is the deterministic substrate behind the quarterly hygiene reminder;
# companion to the 2026-07 breadth-first audit (taskwarrior project:home-cleanup).
#
# The baseline snapshot is machine-local state under $XDG_STATE_HOME/home-audit/.
# Out-of-scope names below (caches, macOS dirs, active config, repos/Downloads)
# are each their own separate audit scope and mirror the 2026-07 exclusions.
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/home-audit"
baseline="$state_dir/baseline.txt"
mkdir -p "$state_dir"

excl_file="$(mktemp)"
cur_file="$(mktemp)"
junk_file="$(mktemp)"
new_file="$(mktemp)"
gone_file="$(mktemp)"
trap 'rm -f "$excl_file" "$cur_file" "$junk_file" "$new_file" "$gone_file"' EXIT

cat > "$excl_file" <<'EOF'
repos
Downloads
Library
Desktop
Documents
Movies
Music
Pictures
Public
Applications
.Trash
.config
.cache
.cargo
.rustup
.npm
.bun
.m2
.gradle
.asdf
.local
.ollama
.espressif
.platformio
go
.yarn
.gsutil
.gem
.thumbnails
.zcompcache
.zcompdump
.rbenv
.nvm
.pyenv
EOF

cd "$HOME"
shopt -s dotglob nullglob
for name in *; do printf '%s\n' "$name"; done | sort | grep -vxF -f "$excl_file" > "$cur_file" || true

total="$(grep -c . "$cur_file" || true)"
echo "=== HOME AUDIT $(date +%Y-%m-%d) ==="
echo "IN_SCOPE=$total"

if [ ! -f "$baseline" ]; then
  cp "$cur_file" "$baseline"
  echo "STATUS=BASELINE_INITIALISED"
  echo "Baseline written to $baseline ($total entries). Re-run next cycle for drift."
  exit 0
fi

comm -13 "$baseline" "$cur_file" > "$new_file" || true
comm -23 "$baseline" "$cur_file" > "$gone_file" || true
new_count="$(grep -c . "$new_file" || true)"
gone_count="$(grep -c . "$gone_file" || true)"
echo "NEW_SINCE_BASELINE=$new_count"
echo "GONE_SINCE_BASELINE=$gone_count"

# Known-junk patterns — re-flagged every run until removed, independent of baseline.
while IFS= read -r name; do
  [ -z "$name" ] && continue
  # Intentionally-empty / sentinel files that must never be flagged as junk.
  case "$name" in
    .hushlogin | .gitkeep | .keep | .metadata_never_index) continue ;;
  esac
  p="$HOME/$name"
  case "$name" in
    node_modules | .DS_Store)
      printf '  %s\t(regenerable / OS junk)\n' "$name" >> "$junk_file" ;;
  esac
  case "$name" in
    *.bak | *.bak.* | *.backup | *.backup.* | *-backup | *.old | *~)
      printf '  %s\t(backup-suffixed)\n' "$name" >> "$junk_file" ;;
  esac
  if [ -d "$p" ] && [ -n "$(find "$p" -maxdepth 0 -empty -print 2>/dev/null)" ]; then
    printf '  %s\t(empty dir)\n' "$name" >> "$junk_file"
  elif [ -f "$p" ] && [ ! -s "$p" ]; then
    printf '  %s\t(zero-byte file)\n' "$name" >> "$junk_file"
  fi
done < "$cur_file"
junk_count="$(grep -c . "$junk_file" || true)"
echo "KNOWN_JUNK=$junk_count"

if [ "$new_count" -gt 0 ]; then
  echo "--- NEW ENTRIES (triage: keep? relocate? junk?) ---"
  sed 's/^/  + /' "$new_file"
fi
if [ "$junk_count" -gt 0 ]; then
  echo "--- KNOWN-JUNK PATTERNS (candidate deletes) ---"
  cat "$junk_file"
fi
if [ "$gone_count" -gt 0 ]; then
  echo "--- GONE SINCE BASELINE (cleaned up) ---"
  sed 's/^/  - /' "$gone_file"
fi

cp "$cur_file" "$baseline"  # refresh so the next run diffs against today

if [ "$new_count" -gt 0 ] || [ "$junk_count" -gt 0 ]; then
  echo "STATUS=REVIEW"
else
  echo "STATUS=OK"
fi
