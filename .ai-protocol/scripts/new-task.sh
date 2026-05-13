#!/usr/bin/env bash
# new-task.sh — scaffolds a new task file from the protocol template
#
# Usage: ./.ai-protocol/scripts/new-task.sh <slug> "<goal>"
#
# Example: ./.ai-protocol/scripts/new-task.sh add-auth "Add JWT authentication to the API"

set -euo pipefail

SLUG="${1:-}"
GOAL="${2:-}"
DATE=$(date +%Y-%m-%d)

if [[ -z "$SLUG" || -z "$GOAL" ]]; then
  echo "Usage: $0 <slug> \"<goal>\""
  echo ""
  echo "Example: $0 add-auth \"Add JWT authentication to the API\""
  exit 1
fi

# Sanitize slug: lowercase, spaces to hyphens, strip special chars
SLUG=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
if [[ -z "$SLUG" ]]; then
  echo "Slug must contain at least one letter, number, or hyphen after sanitizing."
  exit 1
fi

FILENAME="ai-protocol-tasks/${DATE}-${SLUG}.md"
mkdir -p ai-protocol-tasks

if [[ -f "$FILENAME" ]]; then
  echo "Task file already exists: $FILENAME"
  echo "Edit it directly or choose a different slug."
  exit 1
fi

cat > "$FILENAME" <<EOF
# Task: ${SLUG}

## Status: planned

## Goal
${GOAL}

## Context
<!-- Add relevant files, constraints, assumptions, and links before starting. -->

## Codex Notes
<!-- Codex CLI appends here. Gemini/Claude must not edit this section. -->

## Claude Notes
<!-- Claude Code appends here. Gemini/Codex must not edit this section. -->

## Gemini Notes
<!-- Gemini CLI appends here. Codex must not edit this section. -->

## Open Questions
<!-- Format: Question | Owner | Needed by -->

## Decisions
<!-- Format: Decision | Reason | Date -->
EOF

echo "Created: $FILENAME"
echo ""
echo "Next steps:"
echo "  1. Add any context to the file: $FILENAME"
echo "  2. Run the orchestrator: ./.ai-protocol/scripts/orchestrate.sh $FILENAME"
