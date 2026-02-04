#!/bin/bash

# GitHub Repos plugin for sketchybar
# Shows recently pushed repos with PR/issue counts in a popup menu

# Configuration (environment-overridable)
MAX_REPOS="${GITHUB_REPOS_MAX:-5}"
CACHE_TTL="${GITHUB_REPOS_CACHE_TTL:-300}"
CACHE_FILE="${TMPDIR}/sketchybar_github_repos.json"

# Check if gh CLI is authenticated
check_auth() {
    gh auth status &>/dev/null
}

# Check if cache is still valid
is_cache_valid() {
    [[ -f "$CACHE_FILE" ]] || return 1
    local cache_age
    cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0) ))
    (( cache_age < CACHE_TTL ))
}

# Get current GitHub username
get_username() {
    gh api user --jq '.login'
}

# Fetch repos with recent activity from user events
fetch_repos() {
    local username
    username=$(get_username) || return 1

    # Get unique repos from recent events (most recent activity first)
    local repos
    repos=$(gh api "users/${username}/events?per_page=100" \
        --jq '[.[].repo.name] | unique | .[:'"$MAX_REPOS"'][]') || return 1

    # For each repo, get PR and issue counts via GraphQL
    local result="["
    local first=true
    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue
        local owner name
        owner="${repo%%/*}"
        name="${repo#*/}"

        local counts
        counts=$(gh api graphql -f query='
          query($owner: String!, $name: String!) {
            repository(owner: $owner, name: $name) {
              pullRequests(states: OPEN) { totalCount }
              issues(states: OPEN) { totalCount }
            }
          }
        ' -f owner="$owner" -f name="$name" \
            --jq '{prs: .data.repository.pullRequests.totalCount, issues: .data.repository.issues.totalCount}' 2>/dev/null) || counts='{"prs":0,"issues":0}'

        local prs issues
        prs=$(echo "$counts" | jq -r '.prs // 0')
        issues=$(echo "$counts" | jq -r '.issues // 0')

        $first || result+=","
        first=false
        result+="{\"repo\":\"$repo\",\"prs\":$prs,\"issues\":$issues}"
    done <<< "$repos"
    result+="]"

    echo "$result"
}

# Get data with caching
get_data() {
    if is_cache_valid; then
        cat "$CACHE_FILE"
        return 0
    fi

    local data
    if data=$(fetch_repos 2>/dev/null); then
        echo "$data" > "$CACHE_FILE"
        echo "$data"
        return 0
    fi

    # Fallback to stale cache if available
    if [[ -f "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
        return 0
    fi

    return 1
}

# Clear all popup items
clear_popup() {
    local items
    items=$(sketchybar --query github_repos | jq -r '.popup.items[]?' 2>/dev/null)
    for item in $items; do
        sketchybar --remove "$item" 2>/dev/null
    done
}

# Update popup with repo items
update_popup() {
    local data="$1"
    local count
    count=$(echo "$data" | jq 'length')

    clear_popup

    local i=0
    while (( i < count )); do
        local repo prs issues
        repo=$(echo "$data" | jq -r ".[$i].repo")
        prs=$(echo "$data" | jq -r ".[$i].prs")
        issues=$(echo "$data" | jq -r ".[$i].issues")

        # Repo name row
        sketchybar --add item "github_repos.repo_$i" popup.github_repos \
            --set "github_repos.repo_$i" \
                icon.drawing=off \
                label="$repo" \
                label.font="Hack Nerd Font:Bold:13.0" \
                click_script="open 'https://github.com/$repo'; sketchybar --set github_repos popup.drawing=off"

        # Stats row
        sketchybar --add item "github_repos.stats_$i" popup.github_repos \
            --set "github_repos.stats_$i" \
                icon.drawing=off \
                label="  $prs PRs · $issues Issues" \
                label.font="Hack Nerd Font:Regular:11.0" \
                label.color=0x99ffffff \
                click_script="open 'https://github.com/$repo'; sketchybar --set github_repos popup.drawing=off"

        (( i++ ))
    done
}

# Update the bar item
update_bar() {
    sketchybar --set "$NAME" label="GitHub"
}

# Show error state
show_error() {
    local msg="$1"
    sketchybar --set "$NAME" label="$msg" label.color=0xffff6666
}

# Main execution
main() {
    case "$SENDER" in
        mouse.exited.global)
            sketchybar --set "$NAME" popup.drawing=off
            return
            ;;
        routine|forced)
            # Force cache refresh
            rm -f "$CACHE_FILE"
            ;;
    esac

    # Check authentication
    if ! check_auth; then
        show_error "auth"
        return 1
    fi

    # Fetch and display data
    local data
    if data=$(get_data); then
        update_bar "$data"
        update_popup "$data"
    else
        show_error "err"
        return 1
    fi
}

main "$@"
