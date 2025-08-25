#!/bin/bash

# Claude Code Hook: assistant-response-complete
# Called when Claude finishes responding
# Enhanced with event context capture and casual summaries

set -euo pipefail

# Capture stdin data containing Claude's response
CLAUDE_RESPONSE=""
if [ -t 0 ]; then
    # No stdin available
    CLAUDE_RESPONSE=""
else
    # Read stdin
    CLAUDE_RESPONSE=$(cat)
fi

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

    # Only update if we're in kitty and can access the terminal properly
    if [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty >/dev/null 2>&1 && [[ -c /dev/tty ]]; then
        kitty @ set-tab-title "$repo_name | ✓ Ready" >/dev/null 2>&1 || true
    fi
}

# Trigger SketchyBar update (status system will handle detailed status)
trigger_sketchybar_update() {
    if command -v sketchybar >/dev/null 2>&1; then
        sketchybar --trigger claude_status 2>/dev/null || true
    fi
}

# Voice notification with context-aware casual summaries
trigger_voice_notification() {
    local repo_name
    repo_name=$(get_repo_name)

    # Check if we have the enhanced voice notification scripts
    local hooks_dir="$HOME/.claude/hooks"
    local voice_project_dir="$HOME/.claude/voice-notify-project"

    # Try enhanced notification first
    if [[ -f "$hooks_dir/event_context_parser.py" ]] && \
       [[ -f "$hooks_dir/casual_summarizer.py" ]] && \
       [[ -f "$hooks_dir/voice-notify.py" ]] && \
       command -v python3 >/dev/null 2>&1; then

        # Process event context and generate casual summary
        if [[ -n "$CLAUDE_RESPONSE" ]]; then
            # Parse the response to extract context
            local context_json
            context_json=$(echo "$CLAUDE_RESPONSE" | python3 "$hooks_dir/event_context_parser.py" 2>/dev/null || echo "{}")

            # Generate casual summary
            local casual_message
            casual_message=$(echo "$context_json" | python3 "$hooks_dir/casual_summarizer.py" 2>/dev/null || echo "Task completed!")

            # Get event type for voice style
            local event_type
            event_type=$(echo "$context_json" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('event_type', 'general'))" 2>/dev/null || echo "general")

            # Trigger enhanced voice notification
            if [[ -n "$casual_message" ]]; then
                python3 "$hooks_dir/voice-notify.py" "$casual_message" "$repo_name" "$event_type" 2>/dev/null &
                return
            fi
        fi
    fi

    # Fall back to original voice notification if enhanced version fails
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
    elif [[ -f "$hooks_dir/voice-notify.py" ]] && command -v python3 >/dev/null 2>&1; then
        # Try direct Python invocation
        python3 "$hooks_dir/voice-notify.py" "Task completed!" "$repo_name" "success" 2>/dev/null &
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
