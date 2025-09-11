#!/bin/bash

# Claude Code Hook: assistant-response-complete
# Simplified version with better error handling and direct context passing

set -euo pipefail

# Debug mode
DEBUG="${CLAUDE_HOOKS_DEBUG:-false}"
DEBUG_LOG="/tmp/claude_hooks_debug.log"

debug_log() {
    if [[ "$DEBUG" == "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] assistant-response-complete: $*" >> "$DEBUG_LOG"
    fi
}

# Capture stdin (JSON from Claude Code)
HOOK_INPUT=""
if [ ! -t 0 ]; then
    HOOK_INPUT=$(cat)
    debug_log "Received input: ${HOOK_INPUT:0:200}..."
fi

# Extract transcript_path from JSON
TRANSCRIPT_PATH=""
if [[ -n "$HOOK_INPUT" ]]; then
    if command -v jq >/dev/null 2>&1; then
        TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
    else
        # Fallback without jq
        TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | grep -oP '"transcript_path"\s*:\s*"[^"]+' | cut -d'"' -f4 || echo "")
    fi
    debug_log "Extracted transcript path: $TRANSCRIPT_PATH"
fi

# Get repository name for context
get_repo_name() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        basename "$(git rev-parse --show-toplevel)"
    else
        basename "$(pwd)"
    fi
}

REPO_NAME=$(get_repo_name)
debug_log "Repository: $REPO_NAME"

# Update kitty tab title
update_tab_title() {
    if [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty >/dev/null 2>&1; then
        kitty @ set-tab-title "$REPO_NAME | ✓ Ready" 2>/dev/null || true
        debug_log "Updated kitty tab title"
    fi
}

# Trigger SketchyBar update
trigger_sketchybar() {
    if command -v sketchybar >/dev/null 2>&1; then
        sketchybar --trigger claude_status 2>/dev/null || true
        debug_log "Triggered SketchyBar update"
    fi
}

# Process notifications (voice and Obsidian logging)
process_notifications() {
    local hooks_dir="$HOME/.claude/hooks"

    # Skip if no transcript available
    if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
        debug_log "No transcript available, using fallback notifications"

        # Simple fallback voice notification
        if [[ -f "$hooks_dir/voice-notify/notify.py" ]] && command -v uv >/dev/null 2>&1; then
            (cd "$hooks_dir/voice-notify" && uv run python notify.py "Task completed!" "$REPO_NAME" "general" 2>/dev/null) &
        fi
        return
    fi

    # Extract context using unified extractor
    local context_json=""
    if [[ -f "$hooks_dir/context_extractor.py" ]]; then
        debug_log "Extracting context from transcript"

        # Create input JSON for context extractor
        local extractor_input="{\"transcript_path\": \"$TRANSCRIPT_PATH\"}"

        # Extract context
        context_json=$(echo "$extractor_input" | python3 "$hooks_dir/context_extractor.py" 2>/dev/null)

        if [[ -z "$context_json" ]] || [[ "$context_json" == "{}" ]]; then
            debug_log "Context extraction returned empty"
            context_json="{\"primary_activity\": \"general\", \"success\": true}"
        else
            debug_log "Extracted context: ${context_json:0:200}..."
        fi
    else
        debug_log "Context extractor not found"
        context_json="{\"primary_activity\": \"general\", \"success\": true}"
    fi

    # Add project name to context
    context_json=$(echo "$context_json" | jq --arg repo "$REPO_NAME" '. + {project_name: $repo}' 2>/dev/null || echo "$context_json")

    # Send context to voice notifier
    if [[ -f "$hooks_dir/voice-notify/notify_simple.py" ]]; then
        debug_log "Sending to voice notifier"
        echo "$context_json" | python3 "$hooks_dir/voice-notify/notify_simple.py" 2>/dev/null &
    elif [[ -f "$hooks_dir/voice-notify/notify.py" ]] && command -v uv >/dev/null 2>&1; then
        # Fallback to original notify.py with a generated message
        local message="Task completed in $REPO_NAME"
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
        (cd "$hooks_dir/voice-notify" && uv run python notify.py "$message" "$REPO_NAME" "$activity" 2>/dev/null) &
    fi

    # Send context to Obsidian logger
    if [[ -f "$hooks_dir/obsidian-logger/obsidian_logger.py" ]]; then
        debug_log "Sending to Obsidian logger"
        echo "$context_json" | python3 "$hooks_dir/obsidian-logger/obsidian_logger.py" 2>/dev/null &
    fi
}

# Main execution
main() {
    debug_log "Hook started"

    update_tab_title
    trigger_sketchybar
    process_notifications

    debug_log "Hook completed"
}

# Run main function
main "$@"
