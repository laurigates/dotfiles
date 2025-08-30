#!/bin/bash

# Claude Code Hook: assistant-response-start
# Called when Claude starts responding
# Simple kitty tab update

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

# Update kitty tab title to responding state
update_tab_title() {
    local repo_name
    repo_name=$(get_repo_name)

    # Use safe kitty command wrapper if available, otherwise fallback to direct command
    if declare -f safe_set_tab_title >/dev/null 2>&1; then
        safe_set_tab_title "$repo_name | 🤖 Responding..."
    elif [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty >/dev/null 2>&1 && [[ -c /dev/tty ]]; then
        # Fallback: Redirect all kitty remote control output to prevent protocol leakage
        kitty @ set-tab-title "$repo_name | 🤖 Responding..." >/dev/null 2>&1 < /dev/null || true
    fi
}

# Main execution
main() {
    update_tab_title
}

# Run main function
main "$@"
