#!/bin/bash
# Session logging hook for Claude Code
# Appends session summaries to CSV file on session end
set -euo pipefail

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
    TRANSCRIPT_LINES=$(wc -l < "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
    # Count tool uses (approximate from JSON structure)
    TOOL_CALLS=$(grep -c '"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
    # Count user and assistant messages
    USER_MESSAGES=$(grep -c '"role":"user"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
    ASSISTANT_MESSAGES=$(grep -c '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
fi

# Get project name from directory
PROJECT_NAME=$(basename "$PROJECT_DIR")

# CSV file location
CSV_FILE="${HOME}/.claude/session-logs.csv"

# Ensure directory exists
mkdir -p "$(dirname "$CSV_FILE")"

# Create CSV header if file doesn't exist
if [[ ! -f "$CSV_FILE" ]]; then
    echo "timestamp,session_id,exit_reason,project_name,project_dir,is_remote,transcript_lines,tool_calls,user_messages,assistant_messages" > "$CSV_FILE"
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
CSV_LINE="${TIMESTAMP},${SESSION_ID},${REASON},$(escape_csv "$PROJECT_NAME"),$(escape_csv "$PROJECT_DIR"),${IS_REMOTE},${TRANSCRIPT_LINES},${TOOL_CALLS},${USER_MESSAGES},${ASSISTANT_MESSAGES}"

# Use flock to prevent race conditions when multiple sessions end simultaneously
(
    flock -x 200
    echo "$CSV_LINE" >> "$CSV_FILE"
) 200>"${CSV_FILE}.lock"

# Clean up lock file (optional, keeps things tidy)
rm -f "${CSV_FILE}.lock"

# Exit successfully
exit 0
