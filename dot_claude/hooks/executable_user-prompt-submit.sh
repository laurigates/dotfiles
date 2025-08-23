#!/bin/bash

# Claude Code Hook: user-prompt-submit
# Called when user submits a prompt to Claude
# Simple kitty tab update and SketchyBar trigger

set -euo pipefail

# Get basic repository name
get_repo_name() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        basename "$(git rev-parse --show-toplevel)"
    else
        basename "$(pwd)"
    fi
}

# Update kitty tab title to processing state
update_tab_title() {
    local repo_name
    repo_name=$(get_repo_name)

    # Only update if we're in kitty
    if [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty >/dev/null 2>&1; then
        kitty @ set-tab-title "$repo_name | Processing..." 2>/dev/null || true
    fi
}

# Trigger SketchyBar update (status system will handle the heavy lifting)
trigger_sketchybar_update() {
    if command -v sketchybar >/dev/null 2>&1; then
        sketchybar --trigger claude_status 2>/dev/null || true
    fi
}

# Main execution
main() {
    update_tab_title
    trigger_sketchybar_update
}

# Run main function
main "$@"
