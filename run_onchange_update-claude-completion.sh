#!/usr/bin/env bash
# run_onchange_update-claude-completion.sh
# This script automatically updates the Claude CLI zsh completion when triggered by chezmoi
# It will run whenever this script changes or when manually triggered

set -euo pipefail

# Colors for output
readonly BLUE='\033[0;34m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log() {
    echo -e "${BLUE}[chezmoi]${NC} $*" >&2
}

success() {
    echo -e "${GREEN}[chezmoi]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[chezmoi]${NC} $*" >&2
}

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPLETION_GENERATOR="${SCRIPT_DIR}/scripts/generate-claude-completion-simple.sh"

# Check if the generation script exists
if [[ ! -x "$COMPLETION_GENERATOR" ]]; then
    warn "Claude completion generator not found or not executable: $COMPLETION_GENERATOR"
    exit 0
fi

# Check if claude CLI is available
if ! command -v claude >/dev/null 2>&1; then
    warn "Claude CLI not found in PATH, skipping completion update"
    exit 0
fi

log "Updating Claude CLI zsh completion..."

# Run the completion generator
if "$COMPLETION_GENERATOR"; then
    success "Claude CLI completion updated successfully"
else
    warn "Failed to update Claude CLI completion"
    exit 1
fi

# If we're in a chezmoi context, make sure the completion file is properly tracked
if [[ -n "${CHEZMOI_SOURCE_DIR:-}" ]]; then
    COMPLETION_FILE="${CHEZMOI_SOURCE_DIR}/dot_zfunc/_claude"
    if [[ -f "$COMPLETION_FILE" ]]; then
        log "Claude completion available at: ${COMPLETION_FILE#${CHEZMOI_SOURCE_DIR}/}"
    fi
fi
