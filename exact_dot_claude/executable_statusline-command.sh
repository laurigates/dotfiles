#!/bin/bash
# ~/.claude/statusline-command.sh
# Minimal colored-text status line for Claude Code.
# Foreground colors on the terminal's own background (no filled blocks), so a
# mid-line truncation just drops trailing text — it can never leave a color
# escape unclosed and bleed into the rest of the UI. Accent palette is borrowed
# from ~/.config/starship.toml.
#
# Extra features beyond plain dir/branch/model:
#   - Gemini PR review badge: count of UNRESOLVED gemini-code-assist[bot]
#     review threads on the current PR (cached, refreshed in the background
#     so rendering never blocks on a network call).
#   - Cache-warmth indicator: whether the Anthropic prompt cache for this
#     session is still warm, based on the 5-minute (300s) cache TTL measured
#     from the transcript file's last-modified time.

input=$(cat)

# Truecolor RGB accent palette (used as foreground; brightened from the
# starship.toml hexes where needed for legibility on a dark background)
PURPLE="186;104;200"  # directory
ORANGE="252;161;125"  # git branch (#FCA17D)
TEAL="38;186;190"     # PR info
BLUE="134;187;216"    # model name (#86BBD8)
GEMINI="138;180;248"  # #8AB4F8 — Google blue, gemini badge
WARM="255;176;102"    # warm amber — cache-warm glyph
COLD="150;180;205"    # cool dim — cache-cold glyph
HEART="235;110;120"   # soft red — time heart
DIM="150;160;170"     # context % / token totals
SEP="90;95;105"       # separator dots
GREEN="126;200;130"   # CI passing
RED="235;110;120"     # CI failing
AMBER="230;190;110"   # CI pending
WT="180;160;230"      # lavender — linked-worktree marker

# Format a token count with a K suffix (8500→8.5K, 84000→84K)
fmt_tokens() {
  awk -v n="$1" 'BEGIN{
    if (n >= 10000)     printf "%.0fK", n/1000
    else if (n >= 1000) printf "%.1fK", n/1000
    else                printf "%d", n
  }'
}

# Extract JSON fields
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model_name=$(echo "$input" | jq -r '.model.display_name')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
pr_number=$(echo "$input" | jq -r '.pr.number // empty')
pr_state=$(echo "$input" | jq -r '.pr.review_state // empty')
repo_owner=$(echo "$input" | jq -r '.workspace.repo.owner // empty')
repo_name=$(echo "$input" | jq -r '.workspace.repo.name // empty')
wt_name=$(echo "$input" | jq -r '.workspace.git_worktree // .worktree.name // empty')

now=$(date +%s)
cache_dir="${TMPDIR:-/tmp}/cc-statusline"
mkdir -p "$cache_dir" 2>/dev/null

# Location: prefer owner/repo (present when there's a GitHub origin remote),
# otherwise fall back to the HOME-relative path truncated to its last 2 parts.
if [[ -n "$repo_owner" && -n "$repo_name" ]]; then
  loc="$repo_owner/$repo_name"
else
  loc="${current_dir/$HOME/~}"
  loc=$(echo "$loc" | awk -F'/' '{
    if (NF > 2) { print "…/" $(NF-1) "/" $NF }
    else         { print $0 }
  }')
fi

# Git branch + dirty + worktree indicator (local only, no network). Long branch
# names are middle-truncated so they cannot dominate the line width.
git_branch=""
git_dirty=""
git_worktree=""
if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$current_dir" branch --show-current 2>/dev/null || echo "")
  if [[ -n "$git_branch" ]]; then
    git_porcelain=$(git -C "$current_dir" status --porcelain 2>/dev/null || echo "")
    [[ -n "$git_porcelain" ]] && git_dirty="*"
    if [[ "${#git_branch}" -gt 20 ]]; then
      git_branch="${git_branch:0:5}…${git_branch: -11}"
    fi
  fi
  # Linked worktree: JSON hint, or an absolute git-dir under .../worktrees/<name>
  # (the main working tree's git-dir is plain .../.git, with no worktrees/ path).
  if [[ -n "$wt_name" ]]; then
    git_worktree=1
  else
    git_dir_abs=$(git -C "$current_dir" rev-parse --absolute-git-dir 2>/dev/null || echo "")
    [[ "$git_dir_abs" == */worktrees/* ]] && git_worktree=1
  fi
fi

# Model name: strip "Claude " prefix for brevity
short_model="${model_name#Claude }"

# ── PR network data: Gemini reviews + CI checks ───────────────────────────────
# Both need slow gh calls, so we never run them inline: each render reads a
# cached line, and if it's stale it kicks off a single detached background
# refresh (single-flight, lock-guarded) that fetches both and writes one line:
#   "<gemini_unresolved>;<ci_pass>;<ci_fail>;<ci_pending>"
gemini_unresolved=""
ci_pass=""; ci_fail=""; ci_pend=""
if [[ -n "$pr_number" && -n "$repo_owner" && -n "$repo_name" ]] && command -v gh >/dev/null 2>&1; then
  cache_file="$cache_dir/pr-${repo_owner}-${repo_name}-${pr_number}"
  lock_file="${cache_file}.lock"
  fresh_secs=90

  # Use whatever we already have for this render.
  if [[ -f "$cache_file" ]]; then
    IFS=';' read -r gemini_unresolved ci_pass ci_fail ci_pend < "$cache_file"
  fi

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
      # Unresolved gemini-code-assist review threads
      gql='query($owner:String!,$name:String!,$pr:Int!){repository(owner:$owner,name:$name){pullRequest(number:$pr){reviewThreads(first:100){nodes{isResolved comments(first:1){nodes{author{login}}}}}}}}'
      gem=$(gh api graphql -f query="$gql" \
        -F owner="$repo_owner" -F name="$repo_name" -F pr="$pr_number" \
        --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select((.comments.nodes[0].author.login // "") | test("gemini")) | select(.isResolved==false)] | length' 2>/dev/null)
      [[ -z "$gem" ]] && gem=0
      # CI check buckets (pass/fail/pending) for the PR's latest commit
      checks=$(gh pr checks "$pr_number" -R "${repo_owner}/${repo_name}" --json bucket 2>/dev/null)
      if [[ -n "$checks" ]]; then
        cp=$(jq '[.[]|select(.bucket=="pass")]|length' <<<"$checks" 2>/dev/null)
        cf=$(jq '[.[]|select(.bucket=="fail" or .bucket=="cancel")]|length' <<<"$checks" 2>/dev/null)
        cq=$(jq '[.[]|select(.bucket=="pending")]|length' <<<"$checks" 2>/dev/null)
      fi
      printf '%s;%s;%s;%s' "$gem" "${cp:-0}" "${cf:-0}" "${cq:-0}" > "${cache_file}.tmp" 2>/dev/null \
        && mv "${cache_file}.tmp" "$cache_file" 2>/dev/null
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

# ── Render: two colored rows ──────────────────────────────────────────────────
# Each part carries its own color + reset, so any truncation is harmless.
# Multi-line is supported (each printed line is a status row). Row 1 is identity
# (where am I / what PR); row 2 is session metrics.
line1=()  # directory · branch · PR (+CI +gemini)
line2=()  # model · context/tokens · cache · time

# Row 1 — Location (owner/repo, or path fallback)
printf -v p '\033[38;2;%sm%s\033[0m' "$PURPLE" "$loc"
line1+=("$p")

# Row 1 — Git branch + dirty flag, prefixed with ⑂ when on a linked worktree
if [[ -n "$git_branch" ]]; then
  p=""
  [[ -n "$git_worktree" ]] && printf -v p '\033[38;2;%sm⑂\033[0m' "$WT"
  printf -v b '\033[38;2;%sm%s%s\033[0m' "$ORANGE" "$git_branch" "$git_dirty"
  p+="$b"
  line1+=("$p")
fi

# Row 1 — PR info + CI check counts + gemini review badge
if [[ -n "$pr_number" ]]; then
  printf -v p '\033[38;2;%smPR#%s\033[0m' "$TEAL" "$pr_number"
  [[ "$pr_state" == "draft" ]] && printf -v d '\033[38;2;%sm draft\033[0m' "$DIM" && p+="$d"
  # CI checks: green pass / red fail / amber pending, each shown only when > 0
  if [[ "${ci_pass:-0}" -gt 0 ]] 2>/dev/null; then
    printf -v c '\033[38;2;%sm %s✓\033[0m' "$GREEN" "$ci_pass"; p+="$c"
  fi
  if [[ "${ci_fail:-0}" -gt 0 ]] 2>/dev/null; then
    printf -v c '\033[38;2;%sm %s✗\033[0m' "$RED" "$ci_fail"; p+="$c"
  fi
  if [[ "${ci_pend:-0}" -gt 0 ]] 2>/dev/null; then
    printf -v c '\033[38;2;%sm %s⏳\033[0m' "$AMBER" "$ci_pend"; p+="$c"
  fi
  # Gemini badge: only when there are unresolved gemini threads
  if [[ "${gemini_unresolved:-0}" -gt 0 ]] 2>/dev/null; then
    printf -v g '\033[38;2;%sm ✦%s\033[0m' "$GEMINI" "$gemini_unresolved"; p+="$g"
  fi
  line1+=("$p")
fi

# Row 2 — Model name
printf -v p '\033[38;2;%sm%s\033[0m' "$BLUE" "$short_model"
line2+=("$p")

# Row 2 — Context % + session token totals + cache warmth + heart + time
p=""
[[ -n "$used_pct" ]] && printf -v p '\033[38;2;%sm%.0f%%\033[0m ' "$DIM" "$used_pct"
if [[ -n "$total_in" && -n "$total_out" ]]; then
  printf -v tok '\033[38;2;%sm%s↓/%s↑\033[0m ' "$DIM" "$(fmt_tokens "$total_in")" "$(fmt_tokens "$total_out")"
  p+="$tok"
fi
if [[ -n "$cache_glyph" ]]; then
  printf -v c '\033[38;2;%sm%s%s\033[0m ' "$cache_fg" "$cache_glyph" "$cache_remaining"
  p+="$c"
fi
printf -v t '\033[38;2;%sm♥\033[0m\033[38;2;%sm%s\033[0m' "$HEART" "$DIM" "$(date +%H:%M)"
p+="$t"
line2+=("$p")

# Join a row's parts with a dim separator and print it (bash 3.2 safe — no namerefs)
printf -v sep '\033[38;2;%sm · \033[0m' "$SEP"
join_row() {
  local out="" i=0 part
  for part in "$@"; do
    [[ "$i" -gt 0 ]] && out+="$sep"
    out+="$part"
    i=$((i + 1))
  done
  printf '%s\n' "$out"
}
join_row "${line1[@]}"
join_row "${line2[@]}"
