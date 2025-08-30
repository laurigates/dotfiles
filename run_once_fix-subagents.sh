#!/usr/bin/env bash

# Fix Claude subagent definitions for consistency
# This script standardizes format across all agents

set -euo pipefail

AGENTS_DIR="dot_claude/agents"
BACKUP_DIR="dot_claude/agents_backup_$(date +%Y%m%d_%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔧 Fixing Claude subagent definitions..."

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo -e "📁 Created backup directory: ${BLUE}$BACKUP_DIR${NC}"

# Copy all agents to backup
cp -r "$AGENTS_DIR"/* "$BACKUP_DIR/"
echo -e "💾 All agents backed up"

# Color assignments for consistent theming
declare -A AGENT_COLORS=(
    # Development Languages
    ["python-developer"]="#3776AB"
    ["cpp-developer"]="#00599C" 
    ["nodejs-developer"]="#339933"
    
    # Infrastructure & DevOps
    ["container-maestro"]="#2496ED"
    ["k8s-captain"]="#326CE5"
    ["infra-sculptor"]="#FF6B35"
    ["pipeline-engineer"]="#4A90E2"
    
    # Code Quality & Review
    ["code-reviewer"]="#FF6B6B"
    ["security-auditor"]="#E74C3C"
    ["test-architect"]="#2ECC71"
    ["refactoring-specialist"]="#9B59B6"
    
    # Specialized Tools
    ["git-expert"]="#4ECDC4"
    ["neovim-expert"]="#57A143"
    ["makefile-expert"]="#427819"
    ["command-expert"]="#95A5A6"
    
    # Documentation & Communication
    ["docs-expert"]="#4A90E2"
    ["research-assistant"]="#16A085"
    ["digital-scribe"]="#8E44AD"
    ["prd-writer"]="#E67E22"
    
    # Analysis & Management
    ["debug-specialist"]="#FF4757"
    ["code-analysis-expert"]="#FD79A8"
    ["memory-keeper"]="#A29BFE"
    ["agent-expert"]="#9B59B6"
    
    # Domain Specific
    ["api-explorer"]="#00D2D3"
    ["embedded-expert"]="#C0392B"
    ["service-design-expert"]="#1ABC9C"
    ["dotfiles-manager"]="#F39C12"
    ["commit-reviewer"]="#6C5CE7"
    ["plan-roaster"]="#FDCB6E"
)

fix_frontmatter() {
    local file="$1"
    local agent_name=$(basename "$file" .md)
    local temp_file=$(mktemp)
    
    echo -e "  🔧 Fixing frontmatter for: ${YELLOW}$agent_name${NC}"
    
    # Extract current frontmatter
    local has_frontmatter=false
    local after_frontmatter=""
    
    if head -n 1 "$file" | grep -q "^---$"; then
        has_frontmatter=true
        # Get line number where second --- appears
        local end_line=$(sed -n '2,${/^---$/=; }' "$file" | head -1)
        if [[ -n "$end_line" ]]; then
            after_frontmatter=$(tail -n +$((end_line + 1)) "$file")
        fi
    else
        after_frontmatter=$(cat "$file")
    fi
    
    # Get current values if they exist
    local current_name=""
    local current_description=""
    local current_color=""
    
    if [[ "$has_frontmatter" == true ]]; then
        current_name=$(awk '/^---$/{flag=!flag;next}flag && /^name:/{gsub(/^name: */, ""); gsub(/^"/, ""); gsub(/"$/, ""); print; exit}' "$file")
        current_description=$(awk '/^---$/{flag=!flag;next}flag && /^description:/{gsub(/^description: */, ""); print; exit}' "$file")
        current_color=$(awk '/^---$/{flag=!flag;next}flag && /^color:/{gsub(/^color: */, ""); gsub(/^"/, ""); gsub(/"$/, ""); print; exit}' "$file")
    fi
    
    # Set defaults if missing
    if [[ -z "$current_name" ]]; then
        current_name=$(echo "$agent_name" | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
    fi
    
    if [[ -z "$current_color" && -n "${AGENT_COLORS[$agent_name]:-}" ]]; then
        current_color="${AGENT_COLORS[$agent_name]}"
    elif [[ -z "$current_color" ]]; then
        current_color="#6C5CE7"  # Default purple
    fi
    
    if [[ -z "$current_description" ]]; then
        current_description="Specialized agent for $agent_name operations and best practices."
    fi
    
    # Write new frontmatter
    cat > "$temp_file" << EOF
---
name: "$current_name"
color: "$current_color"
description: $current_description
execution_log: true
---

$after_frontmatter
EOF
    
    # Replace original file
    mv "$temp_file" "$file"
}

add_response_protocol() {
    local file="$1"
    local agent_name=$(basename "$file" .md)
    
    echo -e "  📋 Adding response protocol to: ${YELLOW}$agent_name${NC}"
    
    # Check if response protocol already exists
    if grep -q -i "response protocol\|mandatory.*response" "$file"; then
        echo -e "    ✅ Response protocol already exists"
        return 0
    fi
    
    # Add response protocol section before the end of file
    local temp_file=$(mktemp)
    
    cat >> "$temp_file" << 'EOF'

## Response Protocol (MANDATORY)
**Use standardized response format from ~/.claude/workflows/response_template.md**
- Log all commands and outputs with complete details
- Include verification steps and success criteria
- Store execution data in Graphiti Memory with appropriate group_id
- Report any issues or conflicts encountered
- Provide clear task completion summary

**FILE-BASED CONTEXT SHARING:**
- READ before starting: `.claude/tasks/current-workflow.md`, related agent outputs
- UPDATE during execution: `.claude/status/AGENT_NAME-progress.md` with progress
- CREATE after completion: `.claude/docs/AGENT_NAME-output.md` with results
- SHARE for next agents: Key context, environment details, dependencies
EOF
    
    # Replace AGENT_NAME placeholder
    sed -i "s/AGENT_NAME/$agent_name/g" "$temp_file"
    
    # Append to original file
    cat "$file" "$temp_file" > "${file}.new"
    mv "${file}.new" "$file"
    rm "$temp_file"
}

convert_xml_to_markdown() {
    local file="$1"
    local agent_name=$(basename "$file" .md)
    
    echo -e "  🔄 Converting XML tags to markdown: ${YELLOW}$agent_name${NC}"
    
    # Convert XML-style tags to markdown headers
    sed -i 's/<role>/## Role/g' "$file"
    sed -i 's/<\/role>//g' "$file"
    sed -i 's/<core-expertise>/## Core Expertise/g' "$file"
    sed -i 's/<\/core-expertise>//g' "$file"
    sed -i 's/<key-capabilities>/## Key Capabilities/g' "$file"
    sed -i 's/<\/key-capabilities>//g' "$file"
    sed -i 's/<workflow>/## Workflow/g' "$file"
    sed -i 's/<\/workflow>//g' "$file"
    sed -i 's/<best-practices>/## Best Practices/g' "$file"
    sed -i 's/<\/best-practices>//g' "$file"
    sed -i 's/<priority-areas>/## Priority Areas/g' "$file"
    sed -i 's/<\/priority-areas>//g' "$file"
    sed -i 's/<response-protocol>/## Response Protocol/g' "$file"
    sed -i 's/<\/response-protocol>//g' "$file"
}

# Process all agent files
total_fixed=0
for agent_file in "$AGENTS_DIR"/*.md; do
    if [[ -f "$agent_file" ]]; then
        agent_name=$(basename "$agent_file" .md)
        echo -e "\n🔧 Processing: ${BLUE}$agent_name${NC}"
        
        # Apply fixes
        fix_frontmatter "$agent_file"
        convert_xml_to_markdown "$agent_file"
        add_response_protocol "$agent_file"
        
        ((total_fixed++))
        echo -e "  ✅ Fixed: $agent_name"
    fi
done

echo -e "\n📊 Fix Summary:"
echo -e "  🔧 Total agents fixed: $total_fixed"
echo -e "  💾 Backup location: ${BLUE}$BACKUP_DIR${NC}"

echo -e "\n🎉 All agents have been standardized!"
echo -e "\n💡 Next steps:"
echo -e "  1. Review the changes in each agent file"
echo -e "  2. Run the validation script to verify compliance"
echo -e "  3. Commit the standardized agents"
echo -e "  4. Remove backup directory when satisfied: rm -rf $BACKUP_DIR"