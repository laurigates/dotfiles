#!/usr/bin/env bash
# update-command-references.sh
# Updates references to Claude Code commands in documentation after namespace migration
# Compatible with bash 3.2+ (macOS default)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository root
REPO_ROOT="${HOME}/.local/share/chezmoi"

# Dry run flag
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--dry-run]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be changed without making changes"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Command mappings: "old|new" pairs
MAPPINGS=(
    # Slash command references: /old-name → /new-name
    "/smartcommit|/git:commit"
    "/repo-maintenance|/git:maintain"
    "/process-issues|/git:issues"
    "/process-single-issue|/git:issue"
    "/fix-pr|/git:fix-pr"
    "/codereview|/code:review"
    "/audit-agents|/meta:audit"
    "/assimilate|/meta:assimilate"
    "/new-project|/project:new"
    "/modernize|/project:modernize"
    "/tdd|/test:setup"
    "/test-analysis|/test:analyze"
    "/build-knowledge-graph|/docs:knowledge-graph"
    "/devloop|/workflow:dev"
    "/devloop-zen|/workflow:dev-zen"
    "/daily-catchup|/sync:daily"
    "/disseminate|/sync:github-podio"
    "/handoff|/deploy:handoff"
    "/vectorcode:init|/tools:vectorcode"

    # File path references: commands/<path>.md → commands/<namespace>/<new-name>.md
    ".claude/commands/smartcommit.md|.claude/commands/git/commit.md"
    ".claude/commands/repo-maintenance.md|.claude/commands/git/maintain.md"
    ".claude/commands/process-issues.md|.claude/commands/git/issues.md"
    ".claude/commands/process-single-issue.md|.claude/commands/git/issue.md"
    ".claude/commands/fix-pr.md|.claude/commands/git/fix-pr.md"
    ".claude/commands/codereview.md|.claude/commands/code/review.md"
    ".claude/commands/audit-agents.md|.claude/commands/config/audit.md"
    ".claude/commands/assimilate.md|.claude/commands/config/assimilate.md"
    ".claude/commands/new-project.md|.claude/commands/project/new.md"
    ".claude/commands/modernize.md|.claude/commands/project/modernize.md"
    ".claude/commands/tdd.md|.claude/commands/test/setup.md"
    ".claude/commands/test-analysis.md|.claude/commands/test/analyze.md"
    ".claude/commands/build-knowledge-graph.md|.claude/commands/docs/knowledge-graph.md"
    ".claude/commands/devloop.md|.claude/commands/workflow/dev.md"
    ".claude/commands/devloop-zen.md|.claude/commands/workflow/dev-zen.md"
    ".claude/commands/daily-catchup.md|.claude/commands/sync/daily.md"
    ".claude/commands/disseminate.md|.claude/commands/sync/github-podio.md"
    ".claude/commands/handoff.md|.claude/commands/deploy/handoff.md"

    # Existing namespaced commands
    ".claude/commands/github/process-issues.md|.claude/commands/git/issues.md"
    ".claude/commands/github/process-single-issue.md|.claude/commands/git/issue.md"
    ".claude/commands/github/fix-pr.md|.claude/commands/git/fix-pr.md"
    ".claude/commands/chore/modernize.md|.claude/commands/project/modernize.md"
    ".claude/commands/chore/refactor.md|.claude/commands/code/refactor.md"
    ".claude/commands/experimental/devloop.md|.claude/commands/workflow/dev.md"
    ".claude/commands/experimental/devloop-zen.md|.claude/commands/workflow/dev-zen.md"
    ".claude/commands/setup/new-project.md|.claude/commands/project/new.md"
    ".claude/commands/vectorcode/init.md|.claude/commands/tools/vectorcode.md"
)

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Update Command References in Documentation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

# Check if repository exists
if [[ ! -d "$REPO_ROOT" ]]; then
    echo -e "${RED}❌ Error: Repository not found: $REPO_ROOT${NC}"
    exit 1
fi

# Find all markdown files
echo -e "${BLUE}📄 Finding markdown files...${NC}"

# Create temp file for file list
temp_filelist=$(mktemp)
find "$REPO_ROOT" \
    -type f \
    -name "*.md" \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/vendor/*" > "$temp_filelist"

file_count=$(wc -l < "$temp_filelist" | tr -d ' ')
echo -e "  Found $file_count markdown files"
echo ""

# Track statistics
total_files=0
files_modified=0
total_replacements=0

echo -e "${BLUE}🔄 Processing files...${NC}"

while IFS= read -r file; do
    ((total_files++))
    file_modified=false
    file_replacements=0

    # Create temporary file for modifications
    temp_file=$(mktemp)
    cp "$file" "$temp_file"

    # Process each mapping
    for mapping in "${MAPPINGS[@]}"; do
        IFS='|' read -r old new <<< "$mapping"

        # Check if file contains the old reference
        if grep -qF "$old" "$temp_file" 2>/dev/null; then
            if [[ "$DRY_RUN" == false ]]; then
                # Escape special characters for sed
                old_escaped=$(printf '%s\n' "$old" | sed 's:[][\/$.^*]:\\&:g')
                new_escaped=$(printf '%s\n' "$new" | sed 's:[][\/.^*$]:\\&:g')
                sed -i '' "s|$old_escaped|$new_escaped|g" "$temp_file"
            fi
            file_modified=true
            count=$(grep -oF "$old" "$file" 2>/dev/null | wc -l | tr -d ' ')
            ((file_replacements += count))
        fi
    done

    # If file was modified, show results and save changes
    if [[ "$file_modified" == true ]]; then
        ((files_modified++))
        ((total_replacements += file_replacements))

        relative_path="${file#$REPO_ROOT/}"
        if [[ "$DRY_RUN" == false ]]; then
            mv "$temp_file" "$file"
            echo -e "${GREEN}  ✓ $relative_path (${file_replacements} changes)${NC}"
        else
            echo -e "${YELLOW}  → Would update: $relative_path (${file_replacements} changes)${NC}"
        fi
    fi

    # Clean up temp file
    rm -f "$temp_file"
done < "$temp_filelist"

# Clean up file list
rm -f "$temp_filelist"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Update Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "  Total files scanned:     $total_files"
echo -e "${GREEN}  Files modified:          $files_modified${NC}"
echo -e "${GREEN}  Total replacements:      $total_replacements${NC}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}🔍 This was a dry run. Run without --dry-run to apply changes.${NC}"
else
    if [[ $files_modified -gt 0 ]]; then
        echo -e "${GREEN}✅ References updated successfully!${NC}"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo -e "  1. Review changes: ${GREEN}git diff${NC}"
        echo -e "  2. Stage changes: ${GREEN}git add .${NC}"
        echo -e "  3. Apply to symlinks: ${GREEN}chezmoi apply${NC}"
        echo -e "  4. Commit changes: ${GREEN}git commit -m 'refactor: update command namespace references'${NC}"
    else
        echo -e "${GREEN}✅ No references needed updating${NC}"
    fi
fi

echo ""
