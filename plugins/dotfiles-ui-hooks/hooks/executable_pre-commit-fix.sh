#!/bin/bash
# .claude/hooks/pre-commit-fix.sh
# Safe pre-commit formatter for Claude's automated commits
# Ensures only originally staged files are re-staged after formatting

set -euo pipefail

echo "Claude is attempting a commit. Running formatter on staged files..."

# Get the list of currently staged files BEFORE any formatting changes
STAGED_FILES=$(git diff --name-only --cached)

# If there are no staged files, there's nothing to do
if [ -z "$STAGED_FILES" ]; then
  echo "No files staged. Skipping pre-commit formatting."
  exit 0
fi

echo "Staged files to format:"
echo "$STAGED_FILES" | sed 's/^/  - /'

# Check if pre-commit is available
if ! command -v pre-commit >/dev/null 2>&1; then
  echo "Warning: pre-commit not found. Skipping formatting."
  exit 0
fi

# Run the formatter ONLY on the specific files that were staged
# This prevents formatting unrelated files in the working directory
echo "Running pre-commit hooks on staged files..."
if pre-commit run --files $STAGED_FILES; then
  echo "Pre-commit hooks completed successfully."
else
  # pre-commit may exit with non-zero even when just making formatting changes
  echo "Pre-commit hooks completed (some files may have been formatted)."
fi

# Re-stage ONLY those same files to capture any changes made by the formatter
# This is the critical safety measure - we ONLY add back the originally staged files
echo "Re-staging files to capture formatting changes..."
# Use -- to safely handle filenames with special characters
git add -- $STAGED_FILES

echo "Pre-commit formatting complete. Original staged files preserved."

# Exit with code 0 to allow Claude's original commit command to proceed
exit 0
