#!/bin/bash

# Read Claude Code session data
input=$(cat)

# Extract data from JSON
model_name=$(echo "$input" | jq -r '.model.display_name')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
output_style=$(echo "$input" | jq -r '.output_style.name')

# Extract context window metrics
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Current usage (last API call)
current_input=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
current_output=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
cache_creation=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

# Get basic info
time_str=$(date +%H:%M)

# Check if we're in a git repository first
git_info=""
repo_display=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    # We're in a git repo - try to get owner/repo from remote
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ -n "$remote_url" ]]; then
        # Extract owner/repo from GitHub URL (handles both SSH and HTTPS)
        if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
            owner="${BASH_REMATCH[1]}"
            repo="${BASH_REMATCH[2]}"
            repo_display="$owner/$repo"
        fi
    fi

    # If we couldn't get owner/repo, fall back to just repo name from directory
    if [[ -z "$repo_display" ]]; then
        repo_display=$(basename "$current_dir")
    fi

    # Get git branch and status
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -n "$branch" ]]; then
        # Get git status (simplified)
        status_output=$(git status --porcelain 2>/dev/null)
        if [[ -n "$status_output" ]]; then
            git_status="*"
        else
            git_status=""
        fi
        git_info=" $branch$git_status"
    fi
else
    # Not in a git repo - use directory formatting (similar to starship's truncation)
    repo_display="$current_dir"
    if [[ ${#repo_display} -gt 50 ]]; then
        repo_display="...${repo_display: -47}"
    fi
    # Replace home directory with ~
    repo_display="${repo_display/$HOME/~}"
fi

# GitHub PR context (only if in git repo and gh is available)
pr_info=""
if git rev-parse --git-dir >/dev/null 2>&1 && command -v gh >/dev/null 2>&1; then
    # Check if current branch has an open PR (with timeout and error suppression)
    pr_number=$(timeout 2 gh pr view --json number --jq '.number' 2>/dev/null || echo "")
    if [[ -n "$pr_number" && "$pr_number" != "null" ]]; then
        pr_info=" PR#$pr_number"

        # Get check run status for the PR (with timeout and error suppression)
        check_data=$(timeout 3 gh pr checks --json state,name 2>/dev/null || echo "")
        if [[ -n "$check_data" && "$check_data" != "[]" ]]; then
            # Count checks by status
            passing=$(echo "$check_data" | jq -r '.[] | select(.state=="SUCCESS") | .state' 2>/dev/null | wc -l | tr -d ' ')
            failing=$(echo "$check_data" | jq -r '.[] | select(.state=="FAILURE") | .state' 2>/dev/null | wc -l | tr -d ' ')
            pending=$(echo "$check_data" | jq -r '.[] | select(.state=="PENDING" or .state=="IN_PROGRESS" or .state=="QUEUED") | .state' 2>/dev/null | wc -l | tr -d ' ')

            # Only show checks if there are any
            total_checks=$((passing + failing + pending))
            if [[ $total_checks -gt 0 ]]; then
                check_status=""
                [[ $passing -gt 0 ]] && check_status="${passing}✅"
                [[ $failing -gt 0 ]] && check_status="${check_status:+$check_status/}${failing}❌"
                [[ $pending -gt 0 ]] && check_status="${check_status:+$check_status/}${pending}⏳"
                pr_info="$pr_info $check_status"
            fi
        fi
    fi
fi

# Test status indicator (check for cached test results)
test_info=""
if [[ -f ".test_cache" ]]; then
    test_status=$(cat .test_cache 2>/dev/null | head -1)
    case "$test_status" in
        "pass"|"passed"|"✅") test_info=" ✅" ;;
        "fail"|"failed"|"❌") test_info=" ❌" ;;
        "running"|"⏳") test_info=" ⏳" ;;
    esac
elif [[ -f ".pytest_cache/v/cache/lastfailed" ]] && [[ ! -s ".pytest_cache/v/cache/lastfailed" ]]; then
    # pytest cache exists and lastfailed is empty (all tests passed)
    test_info=" ✅"
elif [[ -f ".pytest_cache/v/cache/lastfailed" ]] && [[ -s ".pytest_cache/v/cache/lastfailed" ]]; then
    # pytest cache exists and lastfailed has content (some tests failed)
    test_info=" ❌"
fi

# Context window metrics
context_info=""
if [[ -n "$used_pct" ]]; then
    # Format numbers with K suffix for readability
    format_tokens() {
        local num=$1
        if [[ $num -ge 1000 ]]; then
            printf "%.1fK" "$(echo "scale=1; $num / 1000" | bc)"
        else
            printf "%d" "$num"
        fi
    }

    total_in_fmt=$(format_tokens $total_input)
    total_out_fmt=$(format_tokens $total_output)

    # Build context info string
    context_info=" 🧠 ${used_pct}%"

    # Add session totals
    context_info="${context_info} [${total_in_fmt}↓/${total_out_fmt}↑]"

    # Add current usage details if available (non-zero)
    if [[ $current_input -gt 0 || $current_output -gt 0 ]]; then
        curr_in_fmt=$(format_tokens $current_input)
        curr_out_fmt=$(format_tokens $current_output)
        context_info="${context_info} (${curr_in_fmt}↓/${curr_out_fmt}↑"

        # Add cache info if present
        if [[ $cache_creation -gt 0 || $cache_read -gt 0 ]]; then
            cache_info=""
            if [[ $cache_read -gt 0 ]]; then
                cache_read_fmt=$(format_tokens $cache_read)
                cache_info="💾${cache_read_fmt}"
            fi
            if [[ $cache_creation -gt 0 ]]; then
                cache_create_fmt=$(format_tokens $cache_creation)
                cache_info="${cache_info:+$cache_info/}📝${cache_create_fmt}"
            fi
            context_info="${context_info} ${cache_info}"
        fi
        context_info="${context_info})"
    fi
fi

# Build the status line (simplified colors for terminal display)
printf " \033[31m%s\033[0m" "$repo_display" # Red directory/repo
if [[ -n "$git_info" ]]; then
    printf " \033[33m\033[0m%s" "$git_info" # Yellow git info with branch symbol
fi
if [[ -n "$pr_info" ]]; then
    printf " \033[95m%s\033[0m" "$pr_info" # Magenta PR info
fi
if [[ -n "$test_info" ]]; then
    printf "%s" "$test_info" # Test status (no color, emoji provides the visual cue)
fi
if [[ -n "$context_info" ]]; then
    printf " \033[92m%s\033[0m" "$context_info" # Green context window info
fi
printf " \033[36m♥ %s\033[0m" "$time_str" # Cyan time with heart symbol
printf " \033[90m[%s]\033[0m" "$model_name" # Dim model name
if [[ "$output_style" != "default" ]]; then
    printf " \033[90m(%s)\033[0m" "$output_style" # Dim output style if not default
fi
echo
