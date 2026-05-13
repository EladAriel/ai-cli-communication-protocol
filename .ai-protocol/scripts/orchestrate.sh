#!/usr/bin/env bash
# orchestrate.sh — reads a task file's status and prints (or outputs) the next CLI prompt
#
# Usage:
#   ./.ai-protocol/scripts/orchestrate.sh <task-file>              # human mode: print status + prompt
#   ./.ai-protocol/scripts/orchestrate.sh <task-file> --prompt-only # machine mode: print raw prompt only
#   ./.ai-protocol/scripts/orchestrate.sh <task-file> --next-cli    # machine mode: print "codex" or "gemini"
#   ./.ai-protocol/scripts/orchestrate.sh <task-file> --json        # machine mode: print JSON {cli, prompt, status}
#
# It never runs agents. It only prints what to do and what to paste.
# To run agents automatically, use: .ai-protocol/scripts/run.sh <task-file>

set -euo pipefail

TASK_FILE="${1:-}"
MODE="${2:-human}"   # human | --prompt-only | --next-cli | --json

if [[ -z "$TASK_FILE" || ! -f "$TASK_FILE" ]]; then
  echo "Usage: $0 <task-file> [--prompt-only|--next-cli|--json]"
  echo ""
  echo "Example: $0 ai-protocol-tasks/2026-05-11-build-protocol.md"
  echo ""
  echo "Available task files:"
  ls ai-protocol-tasks/*.md 2>/dev/null | grep -v README || echo "  (none yet — run .ai-protocol/scripts/new-task.sh first)"
  exit 1
fi

# Extract status from the line "## Status: <value>"
STATUS=$(grep -m1 "^## Status:" "$TASK_FILE" | sed 's/^## Status:[[:space:]]*//' | tr -d '[:space:]')

# Extract task title
TITLE=$(grep -m1 "^# Task:" "$TASK_FILE" | sed 's/^# Task:[[:space:]]*//')

# Check implementer availability
HAS_CODEX=false
command -v codex >/dev/null 2>&1 && HAS_CODEX=true
HAS_CLAUDE=false
command -v claude >/dev/null 2>&1 && HAS_CLAUDE=true

DIVIDER="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── helpers ──────────────────────────────────────────────────────────────────

# Determine which agent should implement/fix
get_agent() {
  local status="$1"
  
  # For needs-fixes, stick to the original implementer if possible
  if [[ "$status" == "needs-fixes" ]]; then
    if grep -q "^## Claude Notes" "$TASK_FILE" && grep -A 20 "^## Claude Notes" "$TASK_FILE" | grep -q "\- Date:"; then
      echo "claude"
      return
    fi
    echo "codex"
    return
  fi

  # For planned, check availability
  if $HAS_CODEX && $HAS_CLAUDE; then
    if [[ "$MODE" == "human" ]]; then
      echo "Both Codex and Claude are available. Select the implementer for this task:" >&2
      PS3="Choice: "
      select opt in "codex" "claude"; do
        if [[ -n "$opt" ]]; then
          echo "$opt"
          return
        fi
      done
    else
      # Machine mode default
      echo "codex"
    fi
  elif $HAS_CLAUDE; then
    echo "claude"
  else
    # Default to codex (even if missing, to show error later) or if only codex exists
    echo "codex"
  fi
}

header() {
  echo ""
  echo "$DIVIDER"
  echo "  Task : $TITLE"
  echo "  File : $TASK_FILE"
  echo "  Status: $STATUS"
  echo "$DIVIDER"
  echo ""
}

# Emit a prompt block. $1 = cli name, $2 = prompt text
emit() {
  local cli="$1"
  local prompt="$2"

  case "$MODE" in
    --prompt-only)
      printf '%s' "$prompt"
      ;;
    --next-cli)
      echo "$cli"
      ;;
    --json)
      # Minimal JSON — escape newlines and quotes
      local escaped
      escaped=$(printf '%s' "$prompt" | python3 -c \
        'import sys,json; print(json.dumps(sys.stdin.read()))' 2>/dev/null \
        || printf '%s' "$prompt" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n",$0}' | sed 's/\\n$//')
      printf '{"status":"%s","cli":"%s","prompt":%s}\n' "$STATUS" "$cli" "$escaped"
      ;;
    *)
      # human mode
      header
      local terminal
      [[ "$cli" == "codex" ]] && terminal="Terminal 2 (Codex CLI)" || terminal="Terminal 3 (Gemini CLI)"
      echo "▶  NEXT ACTION → $terminal"
      echo ""
      echo "Paste this prompt into ${cli^}:"
      echo "$DIVIDER"
      printf '%s\n' "$prompt"
      echo "$DIVIDER"
      ;;
  esac
}

# ── status → prompt ──────────────────────────────────────────────────────────

case "$STATUS" in

  planned)
    AGENT=$(get_agent "$STATUS")
    CONFIG="AGENTS.md"
    STATUS_NAME="codex-implementing"
    NOTES_SECTION="## Codex Notes"
    if [[ "$AGENT" == "claude" ]]; then
      CONFIG="CLAUDE.md"
      STATUS_NAME="claude-implementing"
      NOTES_SECTION="## Claude Notes"
    fi

    emit "$AGENT" "Read PROTOCOL.md and $CONFIG.

Task file: $TASK_FILE

Your role: Implement the change described in ## Goal.

Steps:
1. Set ## Status: to $STATUS_NAME (edit the task file first)
2. Inspect all relevant source files before writing code
3. Implement the change
4. Run relevant tests or checks; note pass/fail for each
5. Append to $NOTES_SECTION:
   - Date: $(date +%Y-%m-%d)
   - Files read: (list)
   - Files changed: (list)
   - Commands run: (list with pass/fail)
   - Result: (one-line summary)
   - Next requested action: Gemini review
6. Set ## Status: to ready-for-review

IMPORTANT — decisions.md rules:
- If you record any decisions, APPEND new rows to ai-protocol-tasks/decisions.md
- Do NOT overwrite or reformat existing rows in that file
- Never delete another agent's entries"
    ;;

  codex-implementing|claude-implementing)
    if [[ "$MODE" == "human" ]]; then
      header
      local agent="Codex"
      [[ "$STATUS" == "claude-implementing" ]] && agent="Claude"
      echo "⏳ $agent is working."
      echo ""
      echo "Wait for status to change to ready-for-review, then re-run this script."
      echo ""
      echo "To watch for changes:  watch -n 5 \"grep 'Status' $TASK_FILE\""
    else
      printf '{"status":"%s","cli":"none","prompt":""}\n' "$STATUS"
    fi
    ;;

  ready-for-review)
    emit "gemini" "Read PROTOCOL.md and GEMINI.md.

Task file: $TASK_FILE

Your role: Review the implementation.

Steps:
1. Set ## Status: to gemini-reviewing (edit the task file first)
2. Run: git diff
3. Read every file listed under \"Files changed\" in Codex/Claude Notes
4. Review for:
   - Correctness: does it match ## Goal?
   - Edge cases: what inputs or states are unhandled?
   - Tests: are the right things tested?
   - Simpler alternatives: is there a cleaner approach?
   - Risks: what could break in production?
5. Append to ## Gemini Notes:
   - Date: $(date +%Y-%m-%d)
   - Files reviewed: (list)
   - Findings: (numbered, with file:line references where possible)
   - Verdict: approved | needs-fixes
6. If no issues: set ## Status: to approved
   If issues found: set ## Status: to needs-fixes
7. Do NOT edit Codex/Claude Notes

IMPORTANT — decisions.md rules:
- If you record any decisions, APPEND new rows to ai-protocol-tasks/decisions.md
- Do NOT overwrite or reformat existing rows in that file
- Never delete another agent's entries"
    ;;

  gemini-reviewing)
    if [[ "$MODE" == "human" ]]; then
      header
      echo "⏳ Gemini is reviewing."
      echo ""
      echo "Wait for status to change to approved or needs-fixes, then re-run this script."
      echo ""
      echo "To watch for changes:  watch -n 5 \"grep 'Status' $TASK_FILE\""
    else
      printf '{"status":"%s","cli":"none","prompt":""}\n' "$STATUS"
    fi
    ;;

  needs-fixes)
    AGENT=$(get_agent "$STATUS")
    CONFIG="AGENTS.md"
    STATUS_NAME="codex-implementing"
    NOTES_SECTION="## Codex Notes"
    if [[ "$AGENT" == "claude" ]]; then
      CONFIG="CLAUDE.md"
      STATUS_NAME="claude-implementing"
      NOTES_SECTION="## Claude Notes"
    fi

    emit "$AGENT" "Read PROTOCOL.md and $CONFIG.

Task file: $TASK_FILE

Your role: Apply the fixes listed in ## Gemini Notes.

Steps:
1. Set ## Status: to $STATUS_NAME (edit the task file first)
2. Read every item in ## Gemini Notes → Findings
3. Address each finding; if you intentionally skip one, record why in ## Decisions
4. Append a new entry to $NOTES_SECTION:
   - Date: $(date +%Y-%m-%d)
   - Findings addressed: (reference each Gemini finding by number)
   - Files changed: (list)
   - Commands run: (list with pass/fail)
   - Result: (one-line summary)
   - Next requested action: Gemini re-review
5. Set ## Status: to ready-for-review

IMPORTANT — decisions.md rules:
- If you record any decisions, APPEND new rows to ai-protocol-tasks/decisions.md
- Do NOT overwrite or reformat existing rows in that file
- Never delete another agent's entries"
    ;;

  approved)
    if [[ "$MODE" == "human" ]]; then
      header
      echo "✅ APPROVED — ready for human review and merge."
      echo ""
      echo "Steps:"
      echo "  1. Review the diff:  git diff main"
      echo "  2. Merge if satisfied."
      echo "  3. Mark done:  sed -i'' 's/^## Status: approved/## Status: done/' $TASK_FILE"
    else
      printf '{"status":"approved","cli":"human","prompt":"Review diff and merge."}\n'
    fi
    ;;

  done)
    if [[ "$MODE" == "human" ]]; then
      header
      echo "✅ DONE — this task is complete. Nothing to do."
    else
      printf '{"status":"done","cli":"none","prompt":""}\n'
    fi
    ;;

  blocked)
    if [[ "$MODE" == "human" ]]; then
      header
      echo "🚫 BLOCKED — check ## Open Questions in the task file."
      echo ""
      echo "Resolve the open question, then update ## Status: manually."
    else
      printf '{"status":"blocked","cli":"human","prompt":"Resolve open questions."}\n'
    fi
    ;;

  *)
    if [[ "$MODE" == "human" ]]; then
      header
      echo "⚠️  Unknown status: '$STATUS'"
      echo ""
      echo "Valid statuses: planned | codex-implementing | ready-for-review |"
      echo "                gemini-reviewing | needs-fixes | approved | done | blocked"
      echo ""
      echo "Check the task file for a typo:  grep 'Status' $TASK_FILE"
    else
      printf '{"status":"unknown","cli":"human","prompt":"Fix malformed status."}\n'
    fi
    ;;

esac

echo ""