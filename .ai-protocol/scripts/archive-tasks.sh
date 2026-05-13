#!/usr/bin/env bash
# archive-tasks.sh — moves completed task files (Status: done) to an archive folder
#
# Usage: ./.ai-protocol/scripts/archive-tasks.sh

set -euo pipefail

TASK_DIR="ai-protocol-tasks"
ARCHIVE_BASE="$TASK_DIR/archive"
CURRENT_DATE=$(date +%Y-%m)

# Ensure the archive directory exists
mkdir -p "$ARCHIVE_BASE"

echo "Scanning for completed tasks in $TASK_DIR..."

# Find .md files that are not decisions.md or in the ref/ or archive/ directories
# and contain "## Status: done"
# Using a temp file to store matches to avoid subshell issues with arrays if needed
MATCHES=$(grep -l "^## Status: done" "$TASK_DIR"/*.md 2>/dev/null | grep -v "decisions.md" || true)

if [[ -z "$MATCHES" ]]; then
    echo "No completed tasks found."
    exit 0
fi

for FILE in $MATCHES; do
    FILENAME=$(basename "$FILE")
    
    # Try to extract YYYY-MM from filename (pattern: YYYY-MM-DD-slug.md)
    if [[ $FILENAME =~ ^([0-9]{4})-([0-9]{2}) ]]; then
        FOLDER="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
    else
        FOLDER="$CURRENT_DATE"
    fi
    
    TARGET_DIR="$ARCHIVE_BASE/$FOLDER"
    mkdir -p "$TARGET_DIR"
    
    echo "Archiving: $FILENAME -> $TARGET_DIR/"
    mv "$FILE" "$TARGET_DIR/"
done

echo "Cleanup complete."
