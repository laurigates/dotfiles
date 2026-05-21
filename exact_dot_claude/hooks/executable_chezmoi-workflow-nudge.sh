#!/usr/bin/env bash
# PostToolUse — remind to run `chezmoi apply` (or `chezmoi diff` first) after
# editing a chezmoi source that affects runtime targets.
#
# Fires when an Edit/Write/MultiEdit/NotebookEdit tool call touches:
#   - exact_dot_claude/**  → reminds about `chezmoi apply -v ~/.claude`
#   - .chezmoidata.toml or .chezmoidata/** → reminds about run_onchange scripts
#
# Silent on every other path.
set -euo pipefail

input=$(cat)

tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null || echo "")
case "$tool" in
    Edit|Write|MultiEdit|NotebookEdit) ;;
    *) exit 0 ;;
esac

file_path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input" 2>/dev/null || echo "")
[ -z "$file_path" ] && exit 0

src_root="${HOME}/.local/share/chezmoi"

case "$file_path" in
    "$src_root"/exact_dot_claude/*)
        msg="You edited a chezmoi source under exact_dot_claude/. Run \`chezmoi apply -v ~/.claude\` to sync the change to the runtime ~/.claude/ tree before relying on it."
        ;;
    "$src_root"/.chezmoidata.toml|"$src_root"/.chezmoidata/*)
        msg="You edited chezmoi template data. The next \`chezmoi apply\` will trigger run_onchange scripts (e.g. shell completions, MCP config regeneration). Preview with \`chezmoi diff\` first."
        ;;
    *) exit 0 ;;
esac

jq -nc --arg r "$msg" '{decision: "block", reason: $r}'
