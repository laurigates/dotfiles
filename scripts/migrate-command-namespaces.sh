#!/usr/bin/env bash
# migrate-command-namespaces.sh
# Migrates Claude Code commands to new namespace structure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Command directory
COMMANDS_DIR="${HOME}/.local/share/chezmoi/.claude/commands"

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
            echo "  --dry-run    Show what would be renamed without making changes"
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

# Migration mapping: "old-path|new-namespace|new-name"
declare -a MIGRATIONS=(
    # git: namespace (consolidating github: commands)
    "git/smartcommit.md|git|commit.md"
    "git/repo-maintenance.md|git|maintain.md"
    "github/process-issues.md|git|issues.md"
    "github/process-single-issue.md|git|issue.md"
    "github/fix-pr.md|git|fix-pr.md"

    # code: namespace
    "codereview.md|code|review.md"
    "chore/refactor.md|code|refactor.md"

    # config: namespace
    "audit-agents.md|config|audit.md"
    "assimilate.md|config|assimilate.md"

    # project: namespace
    "setup/new-project.md|project|new.md"
    "chore/modernize.md|project|modernize.md"
    "experimental/modernize.md|project|modernize-exp.md"
    "project/init.md|project|init.md"

    # test: namespace
    "test/run.md|test|run.md"
    "tdd.md|test|setup.md"
    "test-analysis.md|test|analyze.md"

    # docs: namespace
    "docs/update.md|docs|generate.md"
    "docs/docs.md|docs|build.md"
    "docs/decommission.md|docs|decommission.md"
    "build-knowledge-graph.md|docs|knowledge-graph.md"

    # workflow: namespace
    "experimental/devloop.md|workflow|dev.md"
    "experimental/devloop-zen.md|workflow|dev-zen.md"

    # sync: namespace
    "daily-catchup.md|sync|daily.md"
    "disseminate.md|sync|github-podio.md"

    # deploy: namespace
    "setup/release.md|deploy|release.md"
    "handoff.md|deploy|handoff.md"
    "compact/handoff.md|deploy|handoff-compact.md"

    # deps: namespace (already correct)
    "deps/install.md|deps|install.md"

    # lint: namespace (already correct)
    "lint/check.md|lint|check.md"

    # tools: namespace
    "vectorcode/init.md|tools|vectorcode.md"
)

# Namespace directories to create
declare -a NAMESPACES=(
    "git"
    "code"
    "config"
    "project"
    "test"
    "docs"
    "workflow"
    "sync"
    "deploy"
    "deps"
    "lint"
    "tools"
)

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Claude Code Command Namespace Migration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

# Check if commands directory exists
if [[ ! -d "$COMMANDS_DIR" ]]; then
    echo -e "${RED}❌ Error: Commands directory not found: $COMMANDS_DIR${NC}"
    exit 1
fi

# Create namespace directories
echo -e "${BLUE}📁 Creating namespace directories...${NC}"
for namespace in "${NAMESPACES[@]}"; do
    namespace_dir="$COMMANDS_DIR/$namespace"
    if [[ ! -d "$namespace_dir" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$namespace_dir"
            echo -e "${GREEN}  ✓ Created: $namespace/${NC}"
        else
            echo -e "${YELLOW}  → Would create: $namespace/${NC}"
        fi
    else
        echo -e "  ℹ  Already exists: $namespace/"
    fi
done
echo ""

# Track migration statistics
declare -i total_files=0
declare -i migrated_files=0
declare -i skipped_files=0
declare -i not_found=0

echo -e "${BLUE}🔄 Migrating command files...${NC}"

# Process each migration
for migration in "${MIGRATIONS[@]}"; do
    IFS='|' read -r old_path new_namespace new_name <<< "$migration"

    ((total_files++))

    # Build full paths
    old_full_path="$COMMANDS_DIR/$old_path"
    new_full_path="$COMMANDS_DIR/$new_namespace/$new_name"

    # Check if old file exists
    if [[ ! -f "$old_full_path" ]]; then
        echo -e "${YELLOW}  ⚠  Not found: $old_path${NC}"
        ((not_found++))
        continue
    fi

    # Check if already at target location
    if [[ "$old_full_path" == "$new_full_path" ]]; then
        echo -e "  ℹ  Already correct: $new_namespace:$new_name"
        ((skipped_files++))
        continue
    fi

    # Check if target already exists (conflict)
    if [[ -f "$new_full_path" ]]; then
        echo -e "${YELLOW}  ⚠  Conflict: $new_namespace:$new_name already exists${NC}"
        ((skipped_files++))
        continue
    fi

    # Perform migration
    if [[ "$DRY_RUN" == false ]]; then
        mv "$old_full_path" "$new_full_path"
        echo -e "${GREEN}  ✓ $old_path → $new_namespace:$new_name${NC}"
        ((migrated_files++))

        # Also migrate associated files (e.g., PRD files)
        old_dir=$(dirname "$old_full_path")
        old_basename=$(basename "$old_path" .md)
        for associated in "$old_dir/$old_basename".*; do
            if [[ -f "$associated" ]] && [[ "$associated" != "$old_full_path" ]]; then
                ext="${associated##*.}"
                new_basename=$(basename "$new_name" .md)
                new_associated="$COMMANDS_DIR/$new_namespace/$new_basename.$ext"
                mv "$associated" "$new_associated"
                echo -e "${GREEN}    ↳ $(basename "$associated") → $new_namespace:$new_basename.$ext${NC}"
            fi
        done
    else
        echo -e "${YELLOW}  → Would migrate: $old_path → $new_namespace:$new_name${NC}"
        ((migrated_files++))
    fi
done

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Migration Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "  Total files:     $total_files"
echo -e "${GREEN}  Migrated:        $migrated_files${NC}"
echo -e "  Skipped:         $skipped_files"
echo -e "${YELLOW}  Not found:       $not_found${NC}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}🔍 This was a dry run. Run without --dry-run to apply changes.${NC}"
else
    echo -e "${GREEN}✅ Migration complete!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "  1. Run: ${GREEN}chezmoi diff${NC} to review changes"
    echo -e "  2. Run: ${GREEN}chezmoi apply${NC} to sync to ~/.claude/commands/"
    echo -e "  3. Update documentation references with the companion script"
fi

echo ""
