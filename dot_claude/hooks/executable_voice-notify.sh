#!/bin/bash

# Claude Code Hook: voice-notify
# Sends voice notifications for task completion
# Single purpose: Voice notification system

set -euo pipefail

# Debug mode
DEBUG="${CLAUDE_HOOKS_DEBUG:-false}"
DEBUG_LOG="/tmp/claude_hooks_debug.log"

debug_log() {
    if [[ "$DEBUG" == "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] voice-notify: $*" >> "$DEBUG_LOG"
    fi
}

# Get repository name for context
get_repo_name() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        basename "$(git rev-parse --show-toplevel)"
    else
        basename "$(pwd)"
    fi
}

# Process voice notifications
process_voice_notification() {
    local hooks_dir="$HOME/.claude/hooks"
    local repo_name=$(get_repo_name)

    # Capture stdin (JSON from Claude Code)
    local hook_input=""
    if [ ! -t 0 ]; then
        hook_input=$(cat)
        debug_log "Received input: ${hook_input:0:200}..."
    fi

    # Extract transcript_path from JSON if available
    local transcript_path=""
    if [[ -n "$hook_input" ]] && command -v jq >/dev/null 2>&1; then
        transcript_path=$(echo "$hook_input" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
        debug_log "Extracted transcript path: $transcript_path"
    fi

    # Process notification with or without transcript
    if [[ -z "$transcript_path" ]] || [[ ! -f "$transcript_path" ]]; then
        # Simple fallback notification
        debug_log "No transcript available, using fallback notification"
        if [[ -f "$hooks_dir/voice-notify/notify.py" ]] && command -v uv >/dev/null 2>&1; then
            (cd "$hooks_dir/voice-notify" && uv run python notify.py "Task completed!" "$repo_name" "general" 2>/dev/null) &
        fi
    else
        # Extract context and send to voice notifier
        local context_json=""
        if [[ -f "$hooks_dir/context_extractor.py" ]]; then
            debug_log "Extracting context from transcript"
            local extractor_input="{\"transcript_path\": \"$transcript_path\"}"
            context_json=$(echo "$extractor_input" | python3 "$hooks_dir/context_extractor.py" 2>/dev/null)

            if [[ -z "$context_json" ]] || [[ "$context_json" == "{}" ]]; then
                context_json="{\"primary_activity\": \"general\", \"success\": true}"
            fi
        else
            context_json="{\"primary_activity\": \"general\", \"success\": true}"
        fi

        # Add project name to context
        context_json=$(echo "$context_json" | jq --arg repo "$repo_name" '. + {project_name: $repo}' 2>/dev/null || echo "$context_json")

        # Send to voice notifier
        if [[ -f "$hooks_dir/voice-notify/notify_simple.py" ]]; then
            debug_log "Sending to voice notifier"
            echo "$context_json" | python3 "$hooks_dir/voice-notify/notify_simple.py" 2>/dev/null &
        elif [[ -f "$hooks_dir/voice-notify/notify.py" ]] && command -v uv >/dev/null 2>&1; then
            # Fallback with generated message
            local message="Task completed in $repo_name"
            local activity=$(echo "$context_json" | jq -r '.primary_activity // "general"' 2>/dev/null || echo "general")

            case "$activity" in
                tests_passed) message="All tests passed!" ;;
                tests_failed) message="Some tests failed." ;;
                git_commit) message="Made a git commit." ;;
                modified_python) message="Updated Python code." ;;
                modified_javascript) message="Updated JavaScript code." ;;
                error_encountered) message="Encountered some errors." ;;
                *) message="Task completed!" ;;
            esac

            debug_log "Using fallback voice notification: $message"
            (cd "$hooks_dir/voice-notify" && uv run python notify.py "$message" "$repo_name" "$activity" 2>/dev/null) &
        fi
    fi
}

# Main execution
process_voice_notification
