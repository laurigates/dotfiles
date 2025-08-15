#!/bin/bash

# Claude Code Hook: assistant-response-complete
# Called when Claude finishes responding
# Updates kitty tab title to show completion

set -euo pipefail

# Get repository information
get_repo_info() {
    local repo_name="unknown"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        repo_name=$(basename "$(git rev-parse --show-toplevel)")
    fi
    echo "$repo_name"
}

# Update kitty tab title
update_tab_title() {
    local repo_name="$1"
    local status="$2"
    local title="${repo_name} | ${status}"

    # Only update if we're in kitty
    if [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty >/dev/null 2>&1; then
        kitty @ set-tab-title "$title" 2>/dev/null || true
    fi
}

# Log to status hub
log_to_hub() {
    local repo_name="$1"
    local status="$2"
    local timestamp=$(date '+%H:%M:%S')
    local hub_file="/tmp/claude_status_hub.log"

    # Create status entry
    local entry="${timestamp} | ${repo_name} | ${status}"

    # Update the log file
    echo "$entry" >> "$hub_file"

    # Keep only last 20 entries
    tail -n 20 "$hub_file" > "${hub_file}.tmp" && mv "${hub_file}.tmp" "$hub_file"

    # Send to hub tab if it exists
    send_to_hub_tab
}

# Send status update to hub tab
send_to_hub_tab() {
    local hub_file="/tmp/claude_status_hub.log"

    if [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty >/dev/null 2>&1; then
        # Try to find and update the hub tab
        local hub_content
        hub_content=$(generate_hub_display)

        # Send to hub tab (assuming it's named "Claude Hub")
        kitty @ send-text --match "title:Claude Hub" --stdin <<< "$hub_content" 2>/dev/null || true
    fi
}

# Generate the hub display content
generate_hub_display() {
    local hub_file="/tmp/claude_status_hub.log"

    cat << 'EOF'
clear
echo "┌────────────────────────────────────────────────────────────┐"
echo "│                     Claude Status Hub                      │"
echo "├─────────┬─────────────────────┬─────────────────────────────┤"
echo "│  Time   │      Repository     │           Status            │"
echo "├─────────┼─────────────────────┼─────────────────────────────┤"
EOF

    if [[ -f "$hub_file" ]]; then
        while IFS=' | ' read -r timestamp repo status; do
            printf "│ %-7s │ %-19s │ %-27s │\n" "$timestamp" "$repo" "$status"
        done < "$hub_file"
    fi

    echo "└─────────┴─────────────────────┴─────────────────────────────┘"
    echo ""
    echo "Last updated: $(date)"
}

# Main execution
main() {
    local repo_name
    repo_name=$(get_repo_info)

    # Update tab title to show we're ready
    update_tab_title "$repo_name" "✓ Ready"

    # Log the activity
    log_to_hub "$repo_name" "Response complete"
}

# Run main function
main "$@"
