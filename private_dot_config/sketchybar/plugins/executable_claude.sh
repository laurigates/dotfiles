#!/bin/bash

# SketchyBar Claude Status Plugin
# Displays current Claude AI status using safe ~/.claude data parsing

set -euo pipefail

# Source the shared parsing library
CLAUDE_DIR="$HOME/.claude"
PARSER_LIB="$CLAUDE_DIR/lib/claude-session-parser.sh"

# Colors
COLOR_IDLE="0xffffffff"      # White
COLOR_ACTIVE="0xff90ff90"    # Green
COLOR_NEEDS_INPUT="0xffff5f5f" # Red
COLOR_DIMMED="0xff666666"    # Gray

# Get Claude status using the new parsing system
get_claude_status() {
    local icon="🤖"
    local label=""
    local color="$COLOR_DIMMED"

    # Check if parser library exists
    if [[ ! -f "$PARSER_LIB" ]]; then
        echo "$icon||$COLOR_DIMMED"
        return
    fi

    # Source the parser library
    source "$PARSER_LIB" 2>/dev/null || {
        echo "$icon||$COLOR_DIMMED"
        return
    }

    # Get status summary
    local summary
    summary=$(get_status_summary 2>/dev/null || echo "0|0|0|0|unknown")
    IFS='|' read -r total active needs_input idle overall <<< "$summary"

    # No sessions active
    if [[ $total -eq 0 ]]; then
        echo "$icon||$COLOR_DIMMED"
        return
    fi

    # Format display based on overall status and counts
    case "$overall" in
        "needs_input")
            if [[ $needs_input -eq 1 ]]; then
                label="Input"
            else
                label="${needs_input} Input"
            fi
            color="$COLOR_NEEDS_INPUT"
            ;;
        "active")
            if [[ $active -eq 1 && $total -eq 1 ]]; then
                label="Active"
            else
                label="${total} Active"
            fi
            color="$COLOR_ACTIVE"
            ;;
        "idle")
            if [[ $total -eq 1 ]]; then
                label="Idle"
            else
                label="${total} Idle"
            fi
            color="$COLOR_IDLE"
            ;;
        *)
            # Unknown status
            if [[ $total -eq 1 ]]; then
                label="?"
            else
                label="${total} ?"
            fi
            color="$COLOR_DIMMED"
            ;;
    esac

    echo "$icon|$label|$color|$total|$active|$needs_input|$idle"
}

# Show overlay dashboard
show_overlay() {
    if [[ -x "$CLAUDE_DIR/show-status-overlay.sh" ]]; then
        if command -v kitty >/dev/null 2>&1; then
            # Use kitty overlay if available
            kitty @ launch --type=overlay --title="Claude Sessions" \
                "$CLAUDE_DIR/show-status-overlay.sh" 2>/dev/null || {
                # Fallback to new kitty window
                kitty @ launch --type=window --title="Claude Sessions" \
                    "$CLAUDE_DIR/show-status-overlay.sh" 2>/dev/null || true
            }
        else
            # Fallback to terminal window
            open -a Terminal "$CLAUDE_DIR/show-status-overlay.sh" 2>/dev/null || true
        fi
    fi
}

# Handle different actions
handle_action() {
    case "${1:-update}" in
        "click"|"left_click")
            # Left click - show overlay
            show_overlay
            ;;
        "right_click")
            # Right click - show overlay (could add menu later)
            show_overlay
            ;;
        "update"|*)
            # Default update action
            local result
            result=$(get_claude_status)

            # Parse the result
            IFS='|' read -r icon label color total active needs_input idle <<< "$result"

            # Create tooltip text
            local tooltip="Claude Code Sessions"
            if [[ ${total:-0} -gt 0 ]]; then
                tooltip+="\nTotal: ${total:-0} sessions"
                tooltip+="\nActive: ${active:-0}"
                tooltip+="\nNeed Input: ${needs_input:-0}"
                tooltip+="\nIdle: ${idle:-0}"
                tooltip+="\n\nClick to show detailed status"
            else
                tooltip+="\nNo active sessions"
            fi

            # Update SketchyBar item
            sketchybar --set "${NAME:-claude}" \
                icon="$icon" \
                label="$label" \
                icon.color="$color" \
                label.color="$color"
            ;;
    esac
}

# Run main function
handle_action "$@"
