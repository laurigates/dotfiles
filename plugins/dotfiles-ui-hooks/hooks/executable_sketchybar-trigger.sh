#!/bin/bash

# Claude Code Hook: sketchybar-trigger
# Triggers SketchyBar status update
# Single purpose: macOS status bar notification

set -euo pipefail

# Trigger SketchyBar update
trigger_sketchybar() {
    if command -v sketchybar >/dev/null 2>&1; then
        sketchybar --trigger claude_status 2>/dev/null || true
    fi
}

# Main execution
trigger_sketchybar
