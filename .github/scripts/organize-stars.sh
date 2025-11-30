#!/bin/bash
#
# Automated GitHub star organizer
# Processes newly starred repos and categorizes them into GitHub Lists
#

set -euo pipefail

# Configuration
STATE_FILE=".github/star-organizer-state.json"
LOG_FILE="/tmp/star-organizer.log"
PROCESS_ALL="${PROCESS_ALL:-false}"

# Initialize log
log() {
  local level="$1"
  local msg="$2"
  local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
  echo "[$timestamp] $level: $msg" | tee -a "$LOG_FILE"
}

info() { log "INFO" "$1"; }
warn() { log "WARN" "$1"; }
error() { log "ERROR" "$1"; }

# Categorization function
categorize() {
  local topics="$1"
  local language="$2"
  local name="$3"

  topics_lower=$(echo "$topics" | tr '[:upper:]' '[:lower:]')

  # MCP
  if [[ "$topics_lower" =~ mcp ]] || [[ "$name" =~ -mcp ]]; then
    echo "MCP"; return
  fi

  # Stable Diffusion
  if [[ "$topics_lower" =~ stable-diffusion|diffusion|sd-webui|comfyui ]]; then
    echo "Stable Diffusion"; return
  fi

  # GenAI
  if [[ "$topics_lower" =~ openai|chatgpt|llm|machine-learning|langchain ]]; then
    echo "GenAI"; return
  fi

  # Kubernetes
  if [[ "$topics_lower" =~ kubernetes|k8s|helm|kubectl ]]; then
    echo "Kubernetes"; return
  fi

  # Infrastructure
  if [[ "$topics_lower" =~ docker|terraform|ansible|devops|github-actions|container|cicd ]]; then
    echo "Infrastructure"; return
  fi

  # Neovim plugins
  if [[ "$topics_lower" =~ neovim|nvim|vim-plugin ]] || [[ "$language" == "Vim Script" ]]; then
    echo "Neovim plugins - untested"; return
  fi

  # Obsidian
  if [[ "$topics_lower" =~ obsidian ]]; then
    echo "Obsidian"; return
  fi

  # IoT
  if [[ "$topics_lower" =~ iot|esp32|arduino|home-assistant|zigbee|mqtt|esphome ]]; then
    echo "IoT & Home Automation"; return
  fi

  # Game related
  if [[ "$topics_lower" =~ game|gamedev|game-engine|bevy|godot ]]; then
    echo "Game related"; return
  fi

  # Rust (by language)
  if [[ "$language" == "Rust" ]]; then
    echo "Rust"; return
  fi

  # Python
  if [[ "$language" == "Python" ]] && [[ "$topics_lower" =~ python ]]; then
    echo "Python"; return
  fi

  # macOS
  if [[ "$topics_lower" =~ macos|osx ]]; then
    echo "macos"; return
  fi

  # zsh/shell
  if [[ "$topics_lower" =~ zsh|fish-shell|oh-my-zsh ]]; then
    echo "zsh"; return
  fi

  # Web Development
  if [[ "$topics_lower" =~ react|vue|angular|frontend|nextjs|svelte ]]; then
    echo "Web Development"; return
  fi
  if [[ "$language" == "TypeScript" ]] || [[ "$language" == "JavaScript" ]]; then
    echo "Web Development"; return
  fi

  # CLI Tools
  if [[ "$topics_lower" =~ command-line|terminal ]]; then
    echo "CLI Tools"; return
  fi

  # Awesome lists
  if [[ "$name" =~ awesome ]]; then
    echo "Awesome lists"; return
  fi

  # Dotfiles
  if [[ "$topics_lower" =~ dotfiles ]]; then
    echo "Dotfiles"; return
  fi

  # Default
  echo "Utilities"
}

# Load state
load_state() {
  if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
  else
    echo '{"last_run": null, "last_starred_at": null}'
  fi
}

# Save state
save_state() {
  local last_starred_at="$1"
  local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  cat > "$STATE_FILE" << EOF
{
  "last_run": "$now",
  "last_starred_at": "$last_starred_at"
}
EOF
}

# Get list ID by name
get_list_id() {
  local list_name="$1"
  gh api graphql -f query='
{
  viewer {
    lists(first: 100) {
      nodes {
        id
        name
      }
    }
  }
}' | jq -r --arg name "$list_name" '.data.viewer.lists.nodes[] | select(.name == $name) | .id'
}

# Add repo to list
add_to_list() {
  local repo_id="$1"
  local list_id="$2"
  local repo_name="$3"

  gh api graphql -f query='
mutation {
  updateUserListsForItem(input: {
    itemId: "'"$repo_id"'",
    listIds: ["'"$list_id"'"]
  }) {
    item {
      ... on Repository {
        nameWithOwner
      }
    }
  }
}' > /dev/null 2>&1
}

# Main
main() {
  info "Starting GitHub star organization"

  # Load state
  local state=$(load_state)
  local last_starred_at=$(echo "$state" | jq -r '.last_starred_at // empty')

  if [[ "$PROCESS_ALL" == "true" ]]; then
    info "Processing ALL starred repos (ignoring state)"
    last_starred_at=""
  elif [[ -n "$last_starred_at" ]]; then
    info "Processing stars since: $last_starred_at"
  else
    info "No previous state - processing all stars"
  fi

  # Fetch starred repos with metadata
  info "Fetching starred repositories..."
  local repos_json=$(gh api user/starred --paginate --jq '.[] | {
    name: .full_name,
    id: .node_id,
    starred_at: .starred_at,
    language: (.language // "None"),
    topics: (.topics | join(","))
  }')

  # Filter by timestamp if needed
  if [[ -n "$last_starred_at" ]]; then
    repos_json=$(echo "$repos_json" | jq -s --arg since "$last_starred_at" '[.[] | select(.starred_at > $since)]')
  else
    repos_json=$(echo "$repos_json" | jq -s '.')
  fi

  local count=$(echo "$repos_json" | jq 'length')
  info "Found $count repos to process"

  if [[ "$count" -eq 0 ]]; then
    info "No new starred repos to process"
    return 0
  fi

  # Cache list IDs
  info "Fetching list IDs..."
  declare -A list_cache
  while IFS='|' read -r name id; do
    list_cache["$name"]="$id"
  done < <(gh api graphql -f query='
{
  viewer {
    lists(first: 100) {
      nodes {
        id
        name
      }
    }
  }
}' | jq -r '.data.viewer.lists.nodes[] | "\(.name)|\(.id)"')

  # Process repos
  local success=0
  local failed=0
  local latest_starred_at=""

  while read -r line; do
    local name=$(echo "$line" | jq -r '.name')
    local id=$(echo "$line" | jq -r '.id')
    local starred_at=$(echo "$line" | jq -r '.starred_at')
    local language=$(echo "$line" | jq -r '.language')
    local topics=$(echo "$line" | jq -r '.topics')

    local category=$(categorize "$topics" "$language" "$name")
    local list_id="${list_cache[$category]:-}"

    if [[ -z "$list_id" ]]; then
      warn "List '$category' not found for $name"
      ((failed++))
      continue
    fi

    if add_to_list "$id" "$list_id" "$name"; then
      info "Added $name to '$category'"
      ((success++))
    else
      error "Failed to add $name to '$category'"
      ((failed++))
    fi

    latest_starred_at="$starred_at"
  done < <(echo "$repos_json" | jq -c '.[]')

  # Save state
  if [[ -n "$latest_starred_at" ]]; then
    save_state "$latest_starred_at"
  fi

  # Summary
  info "=========================================="
  info "SUMMARY"
  info "=========================================="
  info "Total processed: $((success + failed))"
  info "Success: $success"
  info "Failed: $failed"
  info "Last starred at: ${latest_starred_at:-N/A}"
}

main "$@"
