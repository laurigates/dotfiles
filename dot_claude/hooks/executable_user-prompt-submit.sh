#!/bin/bash

# Claude Code Hook: user-prompt-submit
# Called when user submits a prompt to Claude
# Simple kitty tab update and SketchyBar trigger

set -euo pipefail

# Source the kitty protocol filter library
if [[ -f "$HOME/.claude/lib/kitty-protocol-filter.sh" ]]; then
    source "$HOME/.claude/lib/kitty-protocol-filter.sh"
fi

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

    # Use safe kitty command wrapper if available, otherwise fallback to direct command
    if declare -f safe_set_tab_title >/dev/null 2>&1; then
        safe_set_tab_title "$repo_name | Processing..."
    elif [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty >/dev/null 2>&1 && [[ -c /dev/tty ]]; then
        # Fallback: Redirect all kitty remote control output to prevent protocol leakage
        kitty @ set-tab-title "$repo_name | Processing..." >/dev/null 2>&1 < /dev/null || true
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
