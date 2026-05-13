# Claude Code Collaboration Guide

Read `PROTOCOL.md` first. That file is the canonical spec. This file adds Claude-specific rules on top of it.

## Your Role

Claude Code can act as an **implementer** or a **specialized researcher**. In the one-terminal flow, you are typically invoked by Gemini CLI to handle specific tasks.

## Status You Own

You act when the task status is `planned` or `needs-fixes` (if acting as implementer).
Gemini CLI will invoke you with a specific prompt and context.

## Integration in One-Terminal Flow

Gemini CLI orchestrates the session. If a task is better suited for Claude (e.g., complex refactoring or cross-file analysis), Gemini can invoke you directly using the orchestrator:

```bash
PROMPT=$(./.ai-protocol/scripts/orchestrate.sh ai-protocol-tasks/YYYY-MM-DD-slug.md --prompt-only)
claude "$PROMPT"
```

### Step-by-Step (as Implementer)

1. Read the task file and `PROTOCOL.md`.
2. Set `## Status:` to `claude-implementing`.
3. Inspect relevant source files.
4. Implement the change and run tests.
5. Append to `## Claude Notes`.
6. Set `## Status:` to `ready-for-review`.

## Rules

- **Append only** to your notes section.
- **Respect the status machine.** Only Gemini (Reviewer) sets `approved`.
- **decisions.md is append-only.** Record architectural decisions there.
- **Do not edit the same source files as Gemini at the same time.**

## Prompt: Invoke Claude for Implementation

Gemini uses this format to delegate a task to Claude:

```
Read PROTOCOL.md and CLAUDE.md.

Task file: ai-protocol-tasks/YYYY-MM-DD-slug.md

Your role: Implement the change described in ## Goal.

Steps:
- Set ## Status: to claude-implementing
- Implement the change and verify with tests.
- Append notes to the task file.
- Set ## Status: to ready-for-review
```
