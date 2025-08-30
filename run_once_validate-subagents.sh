#!/usr/bin/env bash

# Validate and fix Claude subagent definitions for consistency
# This script checks all agents in dot_claude/agents/ for format compliance

set -euo pipefail

AGENTS_DIR="dot_claude/agents"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validating Claude subagent definitions..."

# Check if agents directory exists
if [[ ! -d "$AGENTS_DIR" ]]; then
    echo -e "${RED}❌ Agents directory not found: $AGENTS_DIR${NC}"
    exit 1
fi

# Initialize counters
total_agents=0
valid_agents=0
fixed_agents=0

validate_agent() {
    local agent_file="$1"
    local agent_name=$(basename "$agent_file" .md)
    local issues=()
    
    echo -e "\n📋 Checking: ${YELLOW}$agent_name${NC}"
    
    # Check if file has YAML frontmatter
    if ! head -n 1 "$agent_file" | grep -q "^---$"; then
        issues+=("Missing YAML frontmatter")
    else
        # Extract frontmatter
        local frontmatter=$(awk '/^---$/{flag=!flag;next}flag' "$agent_file" | head -n 20)
        
        # Check required fields
        if ! echo "$frontmatter" | grep -q "^name:"; then
            issues+=("Missing 'name' field in frontmatter")
        fi
        
        if ! echo "$frontmatter" | grep -q "^color:"; then
            issues+=("Missing 'color' field in frontmatter")
        fi
        
        if ! echo "$frontmatter" | grep -q "^description:"; then
            issues+=("Missing 'description' field in frontmatter")
        fi
        
        if ! echo "$frontmatter" | grep -q "^execution_log:"; then
            issues+=("Missing 'execution_log' field in frontmatter")
        fi
        
        # Check name format (should be quoted)
        local name_line=$(echo "$frontmatter" | grep "^name:" || echo "")
        if [[ -n "$name_line" && ! "$name_line" =~ name:\ \".*\" ]]; then
            issues+=("Name should be quoted in frontmatter")
        fi
        
        # Check color format (should be hex)
        local color_line=$(echo "$frontmatter" | grep "^color:" || echo "")
        if [[ -n "$color_line" && ! "$color_line" =~ color:\ \"#[0-9A-Fa-f]{6}\" ]]; then
            issues+=("Color should be hex format (#RRGGBB) and quoted")
        fi
    fi
    
    # Check for response protocol section
    if ! grep -q -i "response protocol\|mandatory.*response" "$agent_file"; then
        issues+=("Missing response protocol section")
    fi
    
    # Check for file-based context section
    if ! grep -q -i "file.*context\|context.*sharing" "$agent_file"; then
        issues+=("Missing file-based context operations section")
    fi
    
    # Check for XML-style tags (should use markdown instead)
    if grep -q "<role>\|<core-expertise>\|<key-capabilities>" "$agent_file"; then
        issues+=("Uses XML tags instead of markdown headers")
    fi
    
    # Report results
    if [[ ${#issues[@]} -eq 0 ]]; then
        echo -e "  ✅ Valid format"
        ((valid_agents++))
    else
        echo -e "  ❌ Issues found:"
        for issue in "${issues[@]}"; do
            echo -e "    - $issue"
        done
    fi
    
    ((total_agents++))
}

# Function to fix common issues
fix_agent() {
    local agent_file="$1"
    local agent_name=$(basename "$agent_file" .md)
    
    echo -e "\n🔧 Fixing: ${YELLOW}$agent_name${NC}"
    
    # Create backup
    cp "$agent_file" "$agent_file.backup"
    
    # TODO: Implement automated fixes based on patterns identified
    # For now, just report what would be fixed
    echo -e "  📝 Backup created: $agent_file.backup"
    echo -e "  ⚠️  Manual fixes required - see validation output above"
    
    ((fixed_agents++))
}

# Process all agent files
for agent_file in "$AGENTS_DIR"/*.md; do
    if [[ -f "$agent_file" ]]; then
        validate_agent "$agent_file"
    fi
done

echo -e "\n📊 Validation Summary:"
echo -e "  📁 Total agents: $total_agents"
echo -e "  ✅ Valid agents: $valid_agents"
echo -e "  ❌ Invalid agents: $((total_agents - valid_agents))"

if [[ $valid_agents -eq $total_agents ]]; then
    echo -e "\n🎉 All agents are compliant!"
    exit 0
else
    echo -e "\n⚠️  Some agents need standardization"
    echo -e "\n💡 Recommended actions:"
    echo -e "  1. Review the issues listed above"
    echo -e "  2. Update agent frontmatter with required fields"
    echo -e "  3. Add response protocol sections"
    echo -e "  4. Replace XML tags with markdown headers"
    echo -e "  5. Run this script again to verify fixes"
    exit 1
fi