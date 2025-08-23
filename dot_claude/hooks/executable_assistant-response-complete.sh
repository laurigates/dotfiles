#!/bin/bash

# Claude Code Hook: assistant-response-complete
# Called when Claude finishes responding
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

# Update kitty tab title to ready state
update_tab_title() {
    local repo_name
    repo_name=$(get_repo_name)

    # Only update if we're in kitty
    if [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty >/dev/null 2>&1; then
        kitty @ set-tab-title "$repo_name | ✓ Ready" 2>/dev/null || true
    fi
}

# Trigger SketchyBar update (status system will handle detailed status)
trigger_sketchybar_update() {
    if command -v sketchybar >/dev/null 2>&1; then
        sketchybar --trigger claude_status 2>/dev/null || true
    fi
}

# Voice notification for completion
trigger_voice_notification() {
    local repo_name
    repo_name=$(get_repo_name)

    # Check if we can find the voice notification project
    local voice_project_dir="$HOME/.claude/voice-notify-project"
    if [[ -d "$voice_project_dir" ]] && command -v uv >/dev/null 2>&1; then
        # Generate appropriate completion message
        local messages=(
            "Task completed successfully!"
            "I'm ready for your next request."
            "All done with that task!"
            "Ready when you are!"
        )

        # Select random message
        local message="${messages[$((RANDOM % ${#messages[@]}))]}"

        # Trigger voice notification using uv in background
        (cd "$voice_project_dir" && uv run voice-notify "$message" "$repo_name" "success") 2>/dev/null &
    fi
}

# Main execution
main() {
    update_tab_title
    trigger_sketchybar_update
    trigger_voice_notification
}

# Run main function
main "$@"
