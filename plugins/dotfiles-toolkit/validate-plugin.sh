#!/bin/bash
# validate-plugin.sh - Validate plugin structure and configuration

set -e

echo "🔍 Validating plugin structure..."
echo ""

# Validate JSON files
echo "📄 Validating JSON files..."
if jq empty .claude-plugin/marketplace.json 2>/dev/null; then
    echo "  ✓ marketplace.json is valid"
else
    echo "  ✗ marketplace.json is invalid"
    exit 1
fi

if jq empty plugins/dotfiles-toolkit/.claude-plugin/plugin.json 2>/dev/null; then
    echo "  ✓ plugin.json is valid"
else
    echo "  ✗ plugin.json is invalid"
    exit 1
fi

# Check required directories exist
echo ""
echo "📁 Checking directory structure..."
for dir in "plugins/dotfiles-toolkit/agents" "plugins/dotfiles-toolkit/commands"; do
    if [ -d "$dir" ]; then
        echo "  ✓ $dir exists"
    else
        echo "  ✗ $dir is missing"
        exit 1
    fi
done

# Count agents and commands
echo ""
echo "📊 Plugin contents:"
agent_count=$(find plugins/dotfiles-toolkit/agents -name "*.md" 2>/dev/null | wc -l)
command_count=$(find plugins/dotfiles-toolkit/commands -name "*.md" 2>/dev/null | wc -l)
echo "  • Agents: $agent_count"
echo "  • Commands: $command_count"

# Validate version consistency
echo ""
echo "🏷️  Checking version consistency..."
marketplace_version=$(jq -r '.version' .claude-plugin/marketplace.json)
plugin_version=$(jq -r '.version' plugins/dotfiles-toolkit/.claude-plugin/plugin.json)

echo "  • Marketplace version: $marketplace_version"
echo "  • Plugin version: $plugin_version"

if [ "$marketplace_version" = "$plugin_version" ]; then
    echo "  ✓ Versions match"
else
    echo "  ⚠️  Warning: Version mismatch between marketplace.json and plugin.json"
fi

echo ""
echo "✅ Plugin validation complete!"
