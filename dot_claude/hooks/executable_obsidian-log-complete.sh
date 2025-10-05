#!/bin/bash

# Claude Code Hook: obsidian-log-complete
# Logs completion context to Obsidian vault
# Single purpose: Obsidian activity logging

set -euo pipefail

# Debug mode
DEBUG="${CLAUDE_HOOKS_DEBUG:-false}"
DEBUG_LOG="/tmp/claude_hooks_debug.log"

debug_log() {
    if [[ "$DEBUG" == "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] obsidian-log-complete: $*" >> "$DEBUG_LOG"
    fi
}

# Check if logger is enabled
if [[ "${OBSIDIAN_LOGGER_ENABLED:-true}" != "true" ]]; then
    exit 0
fi

# Get repository name for context
get_repo_name() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        basename "$(git rev-parse --show-toplevel)"
    else
        basename "$(pwd)"
    fi
}

# Process Obsidian logging
process_obsidian_logging() {
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

    # Extract context and send to Obsidian logger
    local context_json=""
    if [[ -n "$transcript_path" ]] && [[ -f "$transcript_path" ]] && [[ -f "$hooks_dir/context_extractor.py" ]]; then
        debug_log "Extracting context from transcript"
        local extractor_input="{\"transcript_path\": \"$transcript_path\"}"
        context_json=$(echo "$extractor_input" | python3 "$hooks_dir/context_extractor.py" 2>/dev/null)
    fi

    # Default context if extraction failed or no transcript
    if [[ -z "$context_json" ]] || [[ "$context_json" == "{}" ]]; then
        context_json="{\"event\": \"assistant-response-complete\", \"success\": true}"
    fi

    # Add project name to context
    context_json=$(echo "$context_json" | jq --arg repo "$repo_name" '. + {project_name: $repo}' 2>/dev/null || echo "$context_json")

    # Send to Obsidian logger
    if [[ -f "$hooks_dir/obsidian-logger/obsidian_logger.py" ]]; then
        debug_log "Sending to Obsidian logger"
        echo "$context_json" | python3 "$hooks_dir/obsidian-logger/obsidian_logger.py" 2>/dev/null &
    fi
}

# Main execution
process_obsidian_logging

# Always exit successfully to not block Claude Code
exit 0
