#!/bin/bash

# Claude Code Hook: kitty-tab-processing
# Updates kitty tab title to show processing state
# Single purpose: Terminal tab status update

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

    # Only update if we're in kitty terminal
    if [[ "${TERM}" == "xterm-kitty" ]]; then
        # Check if kitty remote control is available via socket
        if [[ -n "${KITTY_LISTEN_ON:-}" ]]; then
            # Use remote control if socket is available
            kitty @ --to "$KITTY_LISTEN_ON" set-tab-title "$repo_name | Processing..." >/dev/null 2>&1 || true
        else
            # Fall back to OSC escape sequence for tab title
            printf '\033]2;%s\033\\' "$repo_name | Processing..." >/dev/null 2>&1 || true
        fi
    fi
}

# Main execution
update_tab_title
