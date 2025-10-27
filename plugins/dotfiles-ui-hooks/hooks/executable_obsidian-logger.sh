#!/bin/bash

# Claude Code Hook: obsidian-logger
# Logs activities to Obsidian vault for daily note processing

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Python path (prefer python3)
PYTHON=$(command -v python3 || command -v python || echo "python")

# Check if logger is enabled
if [[ "${OBSIDIAN_LOGGER_ENABLED:-true}" != "true" ]]; then
    exit 0
fi

# Parse context and log to Obsidian
if [[ -f "${SCRIPT_DIR}/event_context_parser.py" ]]; then
    # Use event context parser if available
    cat | "${PYTHON}" "${SCRIPT_DIR}/event_context_parser.py" 2>/dev/null | \
        "${PYTHON}" "${SCRIPT_DIR}/obsidian-logger/obsidian_logger.py" 2>/dev/null || true
else
    # Direct logging without parser
    cat | "${PYTHON}" "${SCRIPT_DIR}/obsidian-logger/obsidian_logger.py" 2>/dev/null || true
fi

# Always exit successfully to not block Claude Code
exit 0
