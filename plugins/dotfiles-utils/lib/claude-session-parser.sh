#!/bin/bash

# Claude Session Parser Library
# Shared functions for parsing ~/.claude session logs and todo files
# Used by monitoring scripts, hooks, and status displays

set -euo pipefail

# Constants
CLAUDE_DIR="$HOME/.claude"
PROJECTS_DIR="$CLAUDE_DIR/projects"
TODOS_DIR="$CLAUDE_DIR/todos"

# Decode project path from ~/.claude/projects directory name
decode_project_path() {
    local encoded_path="$1"
    # Convert -Users-lgates--local-share-chezmoi-dot-claude to /Users/lgates/.local/share/chezmoi/dot_claude
    local decoded_path
    decoded_path=$(echo "$encoded_path" | sed 's/^-//' | sed 's/--/\/./g' | sed 's/-/\//g')
    # Ensure absolute path
    if [[ "$decoded_path" != /* ]]; then
        decoded_path="/$decoded_path"
    fi
    echo "$decoded_path"
}

# Extract project name from decoded path
get_project_name() {
    local project_path="$1"
    basename "$project_path"
}

# Get running Claude CLI processes and their working directories
get_running_claude_processes() {
    # Find all Claude CLI processes (excluding Claude desktop app)
    local claude_pids
    claude_pids=$(ps aux | grep -E '[[:space:]]claude[[:space:]]*$' | awk '{print $2}')

    if [[ -z "$claude_pids" ]]; then
        return 0
    fi

    for pid in $claude_pids; do
        # Get the working directory for this PID
        local cwd
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS - use lsof
            cwd=$(lsof -p "$pid" 2>/dev/null | grep -E "^[^[:space:]]+[[:space:]]+${pid}[[:space:]]+[^[:space:]]+[[:space:]]+cwd" | awk '{print $NF}')
        else
            # Linux - use /proc
            cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null)
        fi

        if [[ -n "$cwd" ]]; then
            echo "$cwd"
        fi
    done
}

# Get all Claude sessions (historical - used for backward compatibility)
get_all_sessions() {
    if [[ ! -d "$PROJECTS_DIR" ]]; then
        return 0
    fi

    find "$PROJECTS_DIR" -name "*.jsonl" -type f | while read -r jsonl_file; do
        local project_dir
        project_dir=$(dirname "$jsonl_file")
        local encoded_project
        encoded_project=$(basename "$project_dir")
        local session_id
        session_id=$(basename "$jsonl_file" .jsonl)

        local project_path
        project_path=$(decode_project_path "$encoded_project")
        local project_name
        project_name=$(get_project_name "$project_path")

        echo "$session_id|$project_name|$project_path|$jsonl_file"
    done
}

# Get only sessions where Claude is currently running
get_running_sessions() {
    if [[ ! -d "$PROJECTS_DIR" ]]; then
        return 0
    fi

    # Get list of directories where Claude is currently running
    local running_dirs
    running_dirs=$(get_running_claude_processes)

    if [[ -z "$running_dirs" ]]; then
        return 0
    fi

    # Convert running directories to a lookup array for efficiency
    local -A running_lookup
    while IFS= read -r dir; do
        if [[ -n "$dir" ]]; then
            running_lookup["$dir"]=1
        fi
    done <<< "$running_dirs"

    find "$PROJECTS_DIR" -name "*.jsonl" -type f | while read -r jsonl_file; do
        local project_dir
        project_dir=$(dirname "$jsonl_file")
        local encoded_project
        encoded_project=$(basename "$project_dir")
        local session_id
        session_id=$(basename "$jsonl_file" .jsonl)

        local project_path
        project_path=$(decode_project_path "$encoded_project")
        local project_name
        project_name=$(get_project_name "$project_path")

        # Only return sessions where Claude is currently running
        if [[ -n "${running_lookup[$project_path]:-}" ]]; then
            echo "$session_id|$project_name|$project_path|$jsonl_file"
        fi
    done
}

# Get active sessions (now points to running sessions for the overlay)
get_active_sessions() {
    get_running_sessions
}

# Parse the latest entry from a session .jsonl file
get_session_info() {
    local jsonl_file="$1"

    if [[ ! -f "$jsonl_file" ]]; then
        echo "unknown|unknown|unknown|0"
        return
    fi

    # Get the last entry (most recent)
    local last_entry
    last_entry=$(tail -n 1 "$jsonl_file")

    if [[ -z "$last_entry" ]]; then
        echo "unknown|unknown|unknown|0"
        return
    fi

    # Parse JSON fields using basic shell tools (avoiding jq dependency)
    local git_branch cwd timestamp session_id
    git_branch=$(echo "$last_entry" | sed -n 's/.*"gitBranch":"\([^"]*\)".*/\1/p')
    cwd=$(echo "$last_entry" | sed -n 's/.*"cwd":"\([^"]*\)".*/\1/p')
    session_id=$(echo "$last_entry" | sed -n 's/.*"sessionId":"\([^"]*\)".*/\1/p')
    timestamp=$(echo "$last_entry" | sed -n 's/.*"timestamp":"\([^"]*\)".*/\1/p')

    # Default values if parsing fails
    git_branch=${git_branch:-"unknown"}
    cwd=${cwd:-"unknown"}
    session_id=${session_id:-"unknown"}
    timestamp=${timestamp:-"1970-01-01T00:00:00.000Z"}

    echo "$git_branch|$cwd|$session_id|$timestamp"
}

# Get todo information for a session
get_session_todos() {
    local session_id="$1"

    # Find todo file for this session
    local todo_file
    todo_file=$(find "$TODOS_DIR" -name "${session_id}-agent-${session_id}.json" -type f 2>/dev/null | head -1)

    if [[ ! -f "$todo_file" ]]; then
        echo "0|0|0"
        return
    fi

    # Count todos by status (avoiding jq dependency)
    local total pending completed
    total=$(grep -o '"id":' "$todo_file" 2>/dev/null | wc -l | tr -d ' ')
    pending=$(grep -c '"status":"pending"' "$todo_file" 2>/dev/null || echo "0")
    completed=$(grep -c '"status":"completed"' "$todo_file" 2>/dev/null || echo "0")

    echo "$total|$pending|$completed"
}

# Determine session status based on recent activity
get_session_status() {
    local jsonl_file="$1"
    local session_id="$2"

    if [[ ! -f "$jsonl_file" ]]; then
        echo "unknown"
        return
    fi

    # Get file modification time
    local file_age_seconds
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        file_age_seconds=$(( $(date +%s) - $(stat -f %m "$jsonl_file") ))
    else
        # Linux
        file_age_seconds=$(( $(date +%s) - $(stat -c %Y "$jsonl_file") ))
    fi

    # Determine status based on activity
    if [[ $file_age_seconds -lt 120 ]]; then
        # Less than 2 minutes - likely active
        echo "active"
    elif [[ $file_age_seconds -lt 600 ]]; then
        # Less than 10 minutes - check if waiting for input
        # Look at recent entries to see if last was user message
        local recent_entries
        recent_entries=$(tail -n 3 "$jsonl_file")

        if echo "$recent_entries" | grep -q '"type":"user"' && \
           ! echo "$recent_entries" | tail -n 1 | grep -q '"type":"assistant"'; then
            echo "needs_input"
        else
            echo "active"
        fi
    else
        # More than 10 minutes old
        echo "idle"
    fi
}

# Format time difference for display
format_time_ago() {
    local timestamp="$1"

    # Convert ISO timestamp to epoch (basic parsing)
    local epoch_time
    if command -v date >/dev/null 2>&1; then
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS date command
            epoch_time=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${timestamp%.*}" +%s 2>/dev/null || echo "0")
        else
            # Linux date command
            epoch_time=$(date -d "$timestamp" +%s 2>/dev/null || echo "0")
        fi
    else
        epoch_time=0
    fi

    local current_time
    current_time=$(date +%s)
    local diff_seconds=$((current_time - epoch_time))

    if [[ $diff_seconds -lt 60 ]]; then
        echo "${diff_seconds}s"
    elif [[ $diff_seconds -lt 3600 ]]; then
        echo "$((diff_seconds / 60))m"
    elif [[ $diff_seconds -lt 86400 ]]; then
        echo "$((diff_seconds / 3600))h"
    else
        echo "$((diff_seconds / 86400))d"
    fi
}

# Get complete session status for monitoring
get_full_session_status() {
    local session_line="$1"

    IFS='|' read -r session_id project_name project_path jsonl_file <<< "$session_line"

    local session_info todo_info status time_ago
    session_info=$(get_session_info "$jsonl_file")
    todo_info=$(get_session_todos "$session_id")
    status=$(get_session_status "$jsonl_file" "$session_id")

    IFS='|' read -r git_branch cwd _ timestamp <<< "$session_info"
    IFS='|' read -r total_todos pending_todos completed_todos <<< "$todo_info"

    time_ago=$(format_time_ago "$timestamp")

    # Format: project_name|git_branch|status|total_todos|pending_todos|completed_todos|time_ago|session_id
    echo "$project_name|$git_branch|$status|$total_todos|$pending_todos|$completed_todos|$time_ago|$session_id"
}

# Get status summary for SketchyBar
get_status_summary() {
    local total_sessions=0
    local active_sessions=0
    local needs_input_sessions=0
    local idle_sessions=0

    while IFS= read -r session_line; do
        if [[ -n "$session_line" ]]; then
            local full_status
            full_status=$(get_full_session_status "$session_line")
            IFS='|' read -r _ _ status _ _ _ _ _ <<< "$full_status"

            ((total_sessions++))
            case "$status" in
                "active") ((active_sessions++)) ;;
                "needs_input") ((needs_input_sessions++)) ;;
                "idle") ((idle_sessions++)) ;;
            esac
        fi
    done < <(get_active_sessions)

    # Overall status priority: needs_input > active > idle
    local overall_status="idle"
    if [[ $needs_input_sessions -gt 0 ]]; then
        overall_status="needs_input"
    elif [[ $active_sessions -gt 0 ]]; then
        overall_status="active"
    fi

    echo "$total_sessions|$active_sessions|$needs_input_sessions|$idle_sessions|$overall_status"
}

# Export functions for use by other scripts
if [[ "${BASH_SOURCE[0]:-}" != "${0}" ]]; then
    # Script is being sourced
    export -f decode_project_path get_project_name get_running_claude_processes
    export -f get_all_sessions get_running_sessions get_active_sessions
    export -f get_session_info get_session_todos get_session_status
    export -f format_time_ago get_full_session_status get_status_summary
fi
