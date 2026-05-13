# One-Terminal Collaboration Workflow

This project uses a streamlined, single-terminal workflow where **Gemini CLI** acts as the central orchestrator.

## Roles at a Glance

| Agent | Does | How |
|-------|------|-----|
| **Gemini CLI** | Plans goals, reviews work, orchestrates Implementers | Primary interactive session |
| **Codex / Claude** | Implements, tests, and fixes | Invoked via shell by Gemini |
| **Human** | Gives goals, approves tool calls, merges changes | Oversees the session |

---

## The Standard Loop

### 1. Goal Setting
You give Gemini a high-level goal in natural language.
> "Add a validator script for task files."

### 2. Planning (Gemini)
Gemini breaks the goal into task files in `ai-protocol-tasks/`.
- Each task is set to `## Status: planned`.
- Gemini records architectural decisions in `ai-protocol-tasks/decisions.md`.

### 3. Implementation (Codex or Claude)
Gemini automatically invokes an implementer to fulfill the current task.
- Gemini grabs the prompt using `./.ai-protocol/scripts/orchestrate.sh <file> --prompt-only`.
- Gemini runs `codex "$PROMPT"` or `claude "$PROMPT"`.
- **Your Role:** You will see a platform dialog asking to allow the agent to modify files.

### 4. Review (Gemini)
Once the implementer finishes and sets status to `ready-for-review`, Gemini automatically reviews the changes.
- Gemini checks for correctness, edge cases, and tests.
- If fixes are needed, Gemini sends the task back to the implementer.

### 5. Approval & Merge
When Gemini is satisfied, it sets the status to `approved`.
- You review the final `git diff`.
- You merge the changes and mark the task as `done`.

---

## Why One Terminal?

- **No Copy-Paste:** You don't have to manually move prompts between windows.
- **Durable History:** The entire planning and review history is captured in one place.
- **Simplified Setup:** No `tmux`, no `watcher` scripts, and no complex terminal management.
