#!/bin/bash

# Setup script for Claude Code + Kitty integration
# Creates hub tab and configures the integration

set -euo pipefail

echo "🐱 Setting up Claude Code + Kitty integration..."

# Check if we're in kitty
if [[ "${TERM}" != "xterm-kitty" ]]; then
    echo "❌ Not running in kitty terminal"
    exit 1
fi

# Check if kitty remote control is available
if ! command -v kitty >/dev/null 2>&1; then
    echo "❌ kitty command not found"
    exit 1
fi

# Test kitty remote control
if ! kitty @ ls >/dev/null 2>&1; then
    echo "❌ Kitty remote control is not enabled"
    echo "💡 Add 'allow_remote_control yes' to your kitty.conf"
    exit 1
fi

echo "✅ Kitty remote control is working"

# Create Claude Hub tab
echo "🏗️  Creating Claude Hub tab..."

# Create the hub tab
kitty @ new-tab --title "Claude Hub" --tab-title "Claude Hub" 2>/dev/null || {
    echo "ℹ️  Hub tab may already exist"
}

# Initialize the hub display
hub_file="/tmp/claude_status_hub.log"
echo "$(date '+%H:%M:%S') | setup | Hub initialized" > "$hub_file"

# Generate initial hub display
generate_initial_hub() {
    cat << 'EOF'
#!/bin/bash
clear
echo "┌────────────────────────────────────────────────────────────┐"
echo "│                     Claude Status Hub                      │"
echo "├─────────┬─────────────────────┬─────────────────────────────┤"
echo "│  Time   │      Repository     │           Status            │"
echo "├─────────┼─────────────────────┼─────────────────────────────┤"
echo "│ $(date '+%H:%M:%S') │ setup               │ Hub initialized             │"
echo "└─────────┴─────────────────────┴─────────────────────────────┘"
echo ""
echo "Last updated: $(date)"
echo ""
echo "🤖 This tab shows real-time status of all Claude Code sessions"
echo "📊 Tab titles will show: [repo-name] | [status]"
echo "🔄 This display auto-updates when Claude responds"
echo ""
echo "💡 To manually refresh, press Ctrl+C and run:"
echo "   cat /tmp/claude_status_hub.log"
EOF
}

# Send initial display to hub tab
echo "📺 Setting up hub display..."
hub_script=$(generate_initial_hub)
kitty @ send-text --match "title:Claude Hub" --stdin <<< "$hub_script" 2>/dev/null || {
    echo "⚠️  Could not send to hub tab"
}

echo ""
echo "✅ Claude Code + Kitty integration setup complete!"
echo ""
echo "🎉 Features enabled:"
echo "   • Tab titles show repository name + Claude status"
echo "   • Central hub tab displays all Claude activity"
echo "   • Real-time status updates via hooks"
echo ""
echo "📋 Next steps:"
echo "   1. Make sure kitty.conf has: allow_remote_control yes"
echo "   2. Apply dotfiles: chezmoi apply -v"
echo "   3. Start using Claude in different repositories"
echo ""
echo "🔍 Tab naming format: [repo-name] | [status]"
echo "   • Processing..."
echo "   • 🤖 Responding..."
echo "   • ✓ Ready"
