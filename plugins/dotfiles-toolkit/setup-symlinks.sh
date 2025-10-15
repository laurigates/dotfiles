#!/usr/bin/env bash
# Setup symlinks for dotfiles-toolkit plugin to point to dot_claude directories

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Create symlinks to existing dot_claude directories
ln -sf "$REPO_ROOT/dot_claude/agents" "$SCRIPT_DIR/agents"
ln -sf "$REPO_ROOT/dot_claude/commands" "$SCRIPT_DIR/commands"

echo "✓ Symlinks created for dotfiles-toolkit plugin"
echo "  agents/ -> ../../dot_claude/agents"
echo "  commands/ -> ../../dot_claude/commands"
