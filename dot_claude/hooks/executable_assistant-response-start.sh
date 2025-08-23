#!/bin/bash

# Claude Code Hook: assistant-response-start
# Called when Claude starts responding
# Simple kitty tab update

set -euo pipefail

# Get basic repository name
get_repo_name() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        basename "$(git rev-parse --show-toplevel)"
    else
        basename "$(pwd)"
    fi
}

# Update kitty tab title to responding state
update_tab_title() {
    local repo_name
    repo_name=$(get_repo_name)

    # Only update if we're in kitty
    if [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty >/dev/null 2>&1; then
        kitty @ set-tab-title "$repo_name | 🤖 Responding..." 2>/dev/null || true
    fi
}

# Main execution
main() {
    update_tab_title
}

# Run main function
main "$@"
