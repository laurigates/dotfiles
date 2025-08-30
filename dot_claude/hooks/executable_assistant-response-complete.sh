#!/bin/bash

# Claude Code Hook: assistant-response-complete
# Called when Claude finishes responding
# Enhanced with event context capture and casual summaries

set -euo pipefail

# Source the kitty protocol filter library
if [[ -f "$HOME/.claude/lib/kitty-protocol-filter.sh" ]]; then
    source "$HOME/.claude/lib/kitty-protocol-filter.sh"
fi

# Capture stdin data containing hook input JSON
HOOK_INPUT=""
if [ -t 0 ]; then
    # No stdin available
    HOOK_INPUT=""
else
    # Read stdin - this is JSON from Claude Code
    HOOK_INPUT=$(cat)
fi

# Extract transcript_path from the JSON input
TRANSCRIPT_PATH=""
if [[ -n "$HOOK_INPUT" ]]; then
    # Use jq if available, otherwise fall back to simple grep
    if command -v jq >/dev/null 2>&1; then
        TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
    else
        # Simple extraction without jq
        TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | grep -oP '"transcript_path"\s*:\s*"[^"]+' | cut -d'"' -f4 || echo "")
    fi
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

    # Use safe kitty command wrapper if available, otherwise fallback to direct command
    if declare -f safe_set_tab_title >/dev/null 2>&1; then
        safe_set_tab_title "$repo_name | ✓ Ready"
    elif [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty >/dev/null 2>&1 && [[ -c /dev/tty ]]; then
        # Fallback: Redirect all kitty remote control output to prevent protocol leakage
        kitty @ set-tab-title "$repo_name | ✓ Ready" >/dev/null 2>&1 < /dev/null || true
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

    # Voice notification directory
    local voice_notify_dir="$HOME/.claude/hooks/voice-notify"
    local hooks_dir="$HOME/.claude/hooks"

    # Try enhanced notification with transcript context
    if [[ -d "$voice_notify_dir" ]] && \
       [[ -f "$voice_notify_dir/notify.py" ]] && \
       command -v uv >/dev/null 2>&1; then

        local context_json="{}"
        local casual_message="Task completed in $repo_name!"
        local event_type="general"

        # Extract context from transcript if available
        if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]] && \
           [[ -f "$hooks_dir/transcript_context_extractor.py" ]]; then

            # Extract context from transcript
            local transcript_input
            transcript_input=$(echo "{\"transcript_path\": \"$TRANSCRIPT_PATH\", \"project_name\": \"$repo_name\"}" | jq -c . 2>/dev/null || echo "{\"transcript_path\": \"$TRANSCRIPT_PATH\", \"project_name\": \"$repo_name\"}")

            context_json=$(echo "$transcript_input" | (cd "$hooks_dir" && uv run python transcript_context_extractor.py) 2>/dev/null || echo "{}")

            # Generate casual summary from the context
            if [[ -f "$hooks_dir/casual_summarizer.py" ]] && [[ "$context_json" != "{}" ]]; then
                casual_message=$(echo "$context_json" | (cd "$hooks_dir" && uv run python casual_summarizer.py) 2>/dev/null || echo "Task completed in $repo_name!")
            fi

            # Get event type from context
            event_type=$(echo "$context_json" | (cd "$hooks_dir" && uv run python -c "import sys, json; data = json.load(sys.stdin); print(data.get('event_type', 'general'))") 2>/dev/null || echo "general")
        fi

        # Trigger voice notification
        if [[ -n "$casual_message" ]]; then
            (cd "$voice_notify_dir" && uv run python notify.py "$casual_message" "$repo_name" "$event_type") 2>/dev/null &
        else
            # Fallback to simple message if no context available
            local messages=(
                "Task completed successfully!"
                "I'm ready for your next request."
                "All done with that task!"
                "Ready when you are!"
            )
            local message="${messages[$((RANDOM % ${#messages[@]}))]}"
            (cd "$voice_notify_dir" && uv run python notify.py "$message" "$repo_name" "success") 2>/dev/null &
        fi
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
