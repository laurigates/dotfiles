#!/bin/bash
# ~/.claude/statusline-command.sh
# Powerline / Starship-inspired status line for Claude Code
# Segment colors and order match ~/.config/starship.toml
#
# Extra features beyond the base Starship style:
#   - Gemini PR review badge: count of UNRESOLVED gemini-code-assist[bot]
#     review threads on the current PR (cached, refreshed in the background
#     so rendering never blocks on a network call).
#   - Cache-warmth indicator: whether the Anthropic prompt cache for this
#     session is still warm, based on the 5-minute (300s) cache TTL measured
#     from the transcript file's last-modified time.

input=$(cat)

# Truecolor RGB values matching starship.toml segment palette
PURPLE="154;52;142"   # #9A348E — opening segment (username/os in Starship)
ORANGE="252;161;125"  # #FCA17D — git branch in Starship
TEAL="6;150;154"      # #06969A — docker context in Starship (PR info here)
BLUE="134;187;216"    # #86BBD8 — language runtimes in Starship (model name here)
DARKBLUE="51;101;138" # #33658A — time segment in Starship
BLACK="0;0;0"
WHITE="255;255;255"
GEMINI="138;180;248"  # #8AB4F8 — Google blue, gemini badge fg
WARM="255;176;102"    # warm amber — cache-warm glyph
COLD="150;180;205"    # cool dim — cache-cold glyph

# U+E0B0 Powerline solid right arrow (requires Nerd Font; kitty + Starship implies this)
ARROW=$(printf '\xee\x82\xb0')

# Extract JSON fields
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model_name=$(echo "$input" | jq -r '.model.display_name')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
pr_number=$(echo "$input" | jq -r '.pr.number // empty')
pr_state=$(echo "$input" | jq -r '.pr.review_state // empty')
repo_owner=$(echo "$input" | jq -r '.workspace.repo.owner // empty')
repo_name=$(echo "$input" | jq -r '.workspace.repo.name // empty')

now=$(date +%s)
cache_dir="${TMPDIR:-/tmp}/cc-statusline"
mkdir -p "$cache_dir" 2>/dev/null

# Directory: replace HOME with ~ then truncate to last 3 components
# (mirrors Starship's truncation_length = 3 and truncation_symbol = "…/")
dir="${current_dir/$HOME/~}"
dir=$(echo "$dir" | awk -F'/' '{
  if (NF > 3) { print "…/" $(NF-2) "/" $(NF-1) "/" $NF }
  else         { print $0 }
}')

# Git branch + dirty indicator (local only, no network)
git_branch=""
git_dirty=""
if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$current_dir" branch --show-current 2>/dev/null || echo "")
  if [[ -n "$git_branch" ]]; then
    git_porcelain=$(git -C "$current_dir" status --porcelain 2>/dev/null || echo "")
    [[ -n "$git_porcelain" ]] && git_dirty="*"
  fi
fi

# Model name: strip "Claude " prefix for brevity
short_model="${model_name#Claude }"

# ── Gemini PR review badge ────────────────────────────────────────────────────
# Counts UNRESOLVED review threads opened by gemini-code-assist[bot] on the
# current PR. The gh GraphQL call is slow, so we never run it inline: each
# render reads a cached count, and if the cache is stale it kicks off a
# detached background refresh (single-flight, guarded by a lock) for next time.
gemini_unresolved=""
if [[ -n "$pr_number" && -n "$repo_owner" && -n "$repo_name" ]] && command -v gh >/dev/null 2>&1; then
  cache_file="$cache_dir/gemini-${repo_owner}-${repo_name}-${pr_number}"
  lock_file="${cache_file}.lock"
  fresh_secs=90

  # Use whatever count we already have for this render.
  [[ -f "$cache_file" ]] && gemini_unresolved=$(cat "$cache_file" 2>/dev/null)

  # Decide whether to spawn a refresh: cache missing/stale AND no recent lock.
  cache_age=999999
  if [[ -f "$cache_file" ]]; then
    cache_mtime=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
    cache_age=$((now - cache_mtime))
  fi
  lock_age=999999
  if [[ -f "$lock_file" ]]; then
    lock_mtime=$(stat -f %m "$lock_file" 2>/dev/null || echo 0)
    lock_age=$((now - lock_mtime))
  fi

  if [[ "$cache_age" -ge "$fresh_secs" && "$lock_age" -ge 60 ]]; then
    : > "$lock_file"
    (
      gql='query($owner:String!,$name:String!,$pr:Int!){repository(owner:$owner,name:$name){pullRequest(number:$pr){reviewThreads(first:100){nodes{isResolved comments(first:1){nodes{author{login}}}}}}}}'
      count=$(gh api graphql -f query="$gql" \
        -F owner="$repo_owner" -F name="$repo_name" -F pr="$pr_number" \
        --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select((.comments.nodes[0].author.login // "") | test("gemini")) | select(.isResolved==false)] | length' 2>/dev/null)
      [[ -z "$count" ]] && count=0
      printf '%s' "$count" > "${cache_file}.tmp" 2>/dev/null && mv "${cache_file}.tmp" "$cache_file" 2>/dev/null
      rm -f "$lock_file" 2>/dev/null
    ) >/dev/null 2>&1 &
    disown 2>/dev/null || true
  fi
fi

# ── Cache-warmth indicator ────────────────────────────────────────────────────
# The Anthropic prompt cache has a 5-minute (300s) TTL, refreshed on each turn.
# The transcript file is appended every turn, so time since its last write is a
# good proxy for how much of the cache window remains.
cache_glyph=""
cache_fg="$COLD"
cache_remaining=""
if [[ -n "$transcript" && -f "$transcript" ]]; then
  t_mtime=$(stat -f %m "$transcript" 2>/dev/null || echo 0)
  elapsed=$((now - t_mtime))
  ttl=300
  remaining=$((ttl - elapsed))
  if [[ "$remaining" -gt 0 ]]; then
    cache_glyph="♨"      # warm: cache still alive
    cache_fg="$WARM"
    cache_remaining=$(printf '%d:%02d' $((remaining / 60)) $((remaining % 60)))
  else
    cache_glyph="❄"      # cold: cache window has expired
    cache_fg="$COLD"
  fi
fi

# ── Powerline segments ────────────────────────────────────────────────────────
prev_bg="$PURPLE"

# Segment 1: Purple — directory (Starship: username + directory)
printf "\033[48;2;%sm\033[38;2;%sm  %s " "$PURPLE" "$WHITE" "$dir"

# Segment 2: Orange — git branch + dirty flag (Starship: git_branch + git_status)
if [[ -n "$git_branch" ]]; then
  printf "\033[38;2;%sm\033[48;2;%sm%s\033[38;2;%sm  %s%s " \
    "$prev_bg" "$ORANGE" "$ARROW" "$BLACK" "$git_branch" "$git_dirty"
  prev_bg="$ORANGE"
fi

# Segment 3: Teal — PR info + gemini review badge (Starship: docker_context)
if [[ -n "$pr_number" ]]; then
  printf "\033[38;2;%sm\033[48;2;%sm%s\033[38;2;%sm  PR#%s" \
    "$prev_bg" "$TEAL" "$ARROW" "$WHITE" "$pr_number"
  case "$pr_state" in
    approved)          printf " [ok]" ;;
    changes_requested) printf " [!]" ;;
    draft)             printf " [draft]" ;;
  esac
  # Gemini badge: only when there are unresolved gemini threads
  if [[ -n "$gemini_unresolved" && "$gemini_unresolved" -gt 0 ]] 2>/dev/null; then
    printf "\033[38;2;%sm ✦%s\033[38;2;%sm" "$GEMINI" "$gemini_unresolved" "$WHITE"
  fi
  printf " "
  prev_bg="$TEAL"
fi

# Segment 4: Blue — model name (Starship: language runtimes)
printf "\033[38;2;%sm\033[48;2;%sm%s\033[38;2;%sm  %s " \
  "$prev_bg" "$BLUE" "$ARROW" "$BLACK" "$short_model"
prev_bg="$BLUE"

# Segment 5: Dark blue — context % + cache warmth + heart + time
printf "\033[38;2;%sm\033[48;2;%sm%s\033[38;2;%sm " \
  "$prev_bg" "$DARKBLUE" "$ARROW" "$WHITE"
[[ -n "$used_pct" ]] && printf "%.0f%% " "$used_pct"
if [[ -n "$cache_glyph" ]]; then
  printf "\033[38;2;%sm%s\033[38;2;%sm" "$cache_fg" "$cache_glyph" "$WHITE"
  [[ -n "$cache_remaining" ]] && printf "%s" "$cache_remaining"
  printf " "
fi
printf "♥ %s " "$(date +%H:%M)"

# Closing arrow back to terminal default background
printf "\033[0m\033[38;2;%sm%s\033[0m\n" "$DARKBLUE" "$ARROW"
