#!/usr/bin/env bash
# Generate allowed tools string from configuration
# Usage: ./generate-allowed-tools.sh [preset_name]
# Default preset: full_access

set -euo pipefail

CONFIG_FILE="${1:-.github/claude-tools-config.json}"
PRESET="${2:-full_access}"

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Generate allowed tools string
generate_tools() {
    local preset="$1"
    local tools=()

    # Check if preset exists
    if ! jq -e ".presets.${preset}" "$CONFIG_FILE" > /dev/null 2>&1; then
        echo "Error: Preset '${preset}' not found in configuration" >&2
        exit 1
    fi

    # Get preset categories
    local categories
    categories=$(jq -r ".presets.${preset}[]" "$CONFIG_FILE")

    # For each category, get the tools
    while IFS= read -r item; do
        # Check if it's a category or a direct tool
        if jq -e ".categories.${item}" "$CONFIG_FILE" > /dev/null 2>&1; then
            # It's a category - get all tools from it
            while IFS= read -r tool; do
                tools+=("$tool")
            done < <(jq -r ".categories.${item}[]" "$CONFIG_FILE")
        else
            # It's a direct tool specification
            tools+=("$item")
        fi
    done <<< "$categories"

    # Join tools with commas
    local IFS=','
    echo "${tools[*]}"
}

# Generate and output the tools string
generate_tools "$PRESET"
