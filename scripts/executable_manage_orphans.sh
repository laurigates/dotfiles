#!/bin/bash

# Smart orphan management for chezmoi
# This script identifies orphaned files without automatically deleting them

SOURCE_DIR="$HOME/.local/share/chezmoi/dot_claude"
TARGET_DIR="$HOME/.claude"
CHEZMOIREMOVE="$HOME/.local/share/chezmoi/.chezmoiremove"

echo "=== Chezmoi Orphan File Detector ==="
echo "Comparing source and target directories..."
echo

# Function to get relative path
get_relative_path() {
    echo "${1#$2/}"
}

# Find orphaned files (in target but not in source)
orphans=()
while IFS= read -r -d '' target_file; do
    rel_path=$(get_relative_path "$target_file" "$TARGET_DIR")

    # Convert target path to source path format
    # Replace .claude with dot_claude in path components
    source_equiv="$SOURCE_DIR/${rel_path}"

    # Check if source file exists
    if [ ! -e "$source_equiv" ]; then
        # Check if it's been tracked by chezmoi (not a user-created file)
        if chezmoi managed --include=files 2>/dev/null | grep -q "$HOME/.claude/$rel_path"; then
            orphans+=("$rel_path")
        fi
    fi
done < <(find "$TARGET_DIR" -type f -print0 2>/dev/null)

if [ ${#orphans[@]} -eq 0 ]; then
    echo "✓ No orphaned files detected"
    exit 0
fi

echo "Found ${#orphans[@]} potential orphan(s):"
echo
for orphan in "${orphans[@]}"; do
    echo "  • .claude/$orphan"
done

echo
echo "Options:"
echo "1) Add to .chezmoiremove (safe removal on next 'chezmoi apply --remove')"
echo "2) View file contents to verify"
echo "3) Check modification times (detect interactive changes)"
echo "4) Export list for manual review"
echo "5) Cancel"
echo
read -p "Select option [1-5]: " choice

case $choice in
    1)
        echo
        echo "Adding to .chezmoiremove..."
        echo "" >> "$CHEZMOIREMOVE"
        echo "# Orphaned files detected on $(date)" >> "$CHEZMOIREMOVE"
        for orphan in "${orphans[@]}"; do
            echo ".claude/$orphan" >> "$CHEZMOIREMOVE"
        done
        echo "✓ Added ${#orphans[@]} entries to .chezmoiremove"
        echo
        echo "To apply removals, run:"
        echo "  chezmoi apply --remove --dry-run  # Preview"
        echo "  chezmoi apply --remove             # Execute"
        ;;
    2)
        for orphan in "${orphans[@]}"; do
            echo
            echo "=== .claude/$orphan ==="
            head -20 "$TARGET_DIR/$orphan"
            echo "..."
            echo
            read -p "Press Enter to continue..."
        done
        ;;
    3)
        echo
        echo "Checking modification times..."
        for orphan in "${orphans[@]}"; do
            target_file="$TARGET_DIR/$orphan"
            mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$target_file" 2>/dev/null || stat -c "%y" "$target_file" 2>/dev/null)
            echo "  • .claude/$orphan - Modified: $mod_time"
        done
        ;;
    4)
        output_file="/tmp/chezmoi_orphans_$(date +%Y%m%d_%H%M%S).txt"
        for orphan in "${orphans[@]}"; do
            echo ".claude/$orphan" >> "$output_file"
        done
        echo "✓ Orphan list exported to: $output_file"
        ;;
    5)
        echo "Cancelled"
        ;;
esac
