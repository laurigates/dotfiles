#!/bin/bash
# Session logging hook for Claude Code
# Appends session summaries to CSV file on session end
set -euo pipefail

# Generate a brief summary of the session using Claude CLI
generate_summary() {
    local transcript_path="$1"

    # Check if claude CLI is available
    if ! command -v claude &>/dev/null; then
        echo ""
        return
    fi

    # Check if transcript exists and has content
    if [[ ! -f "$transcript_path" || ! -s "$transcript_path" ]]; then
        echo ""
        return
    fi

    # Extract user messages from transcript (they contain the actual requests)
    local user_content
    user_content=$(jq -r '
        select(.type == "user") |
        .message.content[] |
        select(.type == "text") |
        .text
    ' "$transcript_path" 2>/dev/null | head -c 4000)

    if [[ -z "$user_content" ]]; then
        echo ""
        return
    fi

    # Generate summary with haiku (fast and cheap)
    local summary
    summary=$(echo "$user_content" | claude -p --model haiku \
        "Summarize this Claude Code session in one brief sentence (max 100 chars). Focus on the main task accomplished. Output only the summary, nothing else." \
        2>/dev/null | tr '\n' ' ' | head -c 150 | sed 's/[[:space:]]*$//')

    echo "$summary"
}

# Read hook input from stdin
INPUT=$(cat)

# Extract fields from JSON input
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Additional context from environment
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$CWD}"
IS_REMOTE="${CLAUDE_CODE_REMOTE:-false}"

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Calculate metrics from transcript if available
TRANSCRIPT_LINES=0
TOOL_CALLS=0
USER_MESSAGES=0
ASSISTANT_MESSAGES=0

if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
    TRANSCRIPT_LINES=$(wc -l < "$TRANSCRIPT_PATH" 2>/dev/null | tr -d ' ' || echo 0)
    # Count tool uses (approximate from JSON structure)
    TOOL_CALLS=$(grep -c '"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
    # Count user and assistant messages
    USER_MESSAGES=$(grep -c '"role":"user"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
    ASSISTANT_MESSAGES=$(grep -c '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
fi

# Generate session summary using Claude CLI with haiku (fast and cheap)
SESSION_SUMMARY=""
if [[ -n "$TRANSCRIPT_PATH" ]]; then
    SESSION_SUMMARY=$(generate_summary "$TRANSCRIPT_PATH" || echo "")
fi

# Get project name from directory
PROJECT_NAME=$(basename "$PROJECT_DIR")

# CSV file location
CSV_FILE="${HOME}/.claude/session-logs.csv"

# Ensure directory exists
mkdir -p "$(dirname "$CSV_FILE")"

# Create CSV header if file doesn't exist
if [[ ! -f "$CSV_FILE" ]]; then
    echo "timestamp,session_id,exit_reason,project_name,project_dir,is_remote,transcript_lines,tool_calls,user_messages,assistant_messages,summary" > "$CSV_FILE"
fi

# Escape CSV fields (handle commas and quotes in project paths)
escape_csv() {
    local field="$1"
    # If field contains comma, quote, or newline, wrap in quotes and escape internal quotes
    if [[ "$field" == *","* || "$field" == *'"'* || "$field" == *$'\n'* ]]; then
        field="${field//\"/\"\"}"  # Escape quotes by doubling
        field="\"$field\""
    fi
    echo "$field"
}

# Build CSV line with proper escaping
CSV_LINE="${TIMESTAMP},${SESSION_ID},${REASON},$(escape_csv "$PROJECT_NAME"),$(escape_csv "$PROJECT_DIR"),${IS_REMOTE},${TRANSCRIPT_LINES},${TOOL_CALLS},${USER_MESSAGES},${ASSISTANT_MESSAGES},$(escape_csv "$SESSION_SUMMARY")"

# Use lockfile to prevent race conditions when multiple sessions end simultaneously
# macOS-compatible locking using mkdir (atomic operation)
LOCK_DIR="${CSV_FILE}.lock"
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    sleep 0.1
done
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

echo "$CSV_LINE" >> "$CSV_FILE"

rmdir "$LOCK_DIR" 2>/dev/null
trap - EXIT

# Exit successfully
exit 0
