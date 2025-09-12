#!/bin/bash

# Read Claude Code session data
input=$(cat)

# Extract data from JSON
model_name=$(echo "$input" | jq -r '.model.display_name')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
output_style=$(echo "$input" | jq -r '.output_style.name')

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

# Kubernetes context (only if kubectl is available and context is set)
k8s_info=""
if command -v kubectl >/dev/null 2>&1; then
    current_context=$(timeout 1 kubectl config current-context 2>/dev/null || echo "")
    if [[ -n "$current_context" ]]; then
        k8s_info=" ☸️ $current_context"
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

# Build the status line (simplified colors for terminal display)
printf " \033[31m%s\033[0m" "$repo_display" # Red directory/repo
if [[ -n "$git_info" ]]; then
    printf " \033[33m\033[0m%s" "$git_info" # Yellow git info with branch symbol
fi
if [[ -n "$pr_info" ]]; then
    printf " \033[95m%s\033[0m" "$pr_info" # Magenta PR info
fi
if [[ -n "$k8s_info" ]]; then
    printf " \033[94m%s\033[0m" "$k8s_info" # Blue Kubernetes info
fi
if [[ -n "$test_info" ]]; then
    printf "%s" "$test_info" # Test status (no color, emoji provides the visual cue)
fi
printf " \033[36m♥ %s\033[0m" "$time_str" # Cyan time with heart symbol
printf " \033[90m[%s]\033[0m" "$model_name" # Dim model name
if [[ "$output_style" != "default" ]]; then
    printf " \033[90m(%s)\033[0m" "$output_style" # Dim output style if not default
fi
echo
