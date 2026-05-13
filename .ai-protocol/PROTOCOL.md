# AI CLI Communication Protocol

Version: 1.1  
Last updated: 2026-05-13

This is the canonical specification for CLI-to-CLI agent collaboration through `ai-protocol-tasks/` files.

## Core Principle

Agents communicate by reading and writing a shared task file. A status field in the file acts as a mutex: only the agent that owns the current status may edit the file. The orchestrator reads status and generates the next prompt for the human to paste.

## Status Machine

```
planned
  └─► codex-implementing or claude-implementing
        └─► ready-for-review
              └─► gemini-reviewing
                    ├─► approved ──► done
                    └─► needs-fixes
                          └─► codex-implementing or claude-implementing (loop)

Any status ──► blocked  (either agent or human sets this when stuck)
  └─► resolved manually ──► back to appropriate status
```

### Status Ownership

| Status | Who sets it | Who acts on it |
|--------|-------------|----------------|
| `planned` | Human or Gemini | Implementer (Codex or Claude) |
| `codex-implementing` | Codex (on start) | Codex |
| `claude-implementing` | Claude (on start) | Claude |
| `ready-for-review` | Implementer (on finish) | Gemini |
| `gemini-reviewing` | Gemini (on start) | Gemini |
| `needs-fixes` | Gemini (found issues) | Original Implementer |
| `approved` | Gemini (no issues) | Human |
| `done` | Human | Human (run archive script) |
| `blocked` | Any agent or human | Human (must resolve manually) |

### Archiving Completed Tasks

Once a task reaches the `done` status, it should be archived to prevent the `ai-protocol-tasks/` directory from becoming cluttered and bloating the AI's context window.

Run the cleanup script:
```bash
./.ai-protocol/scripts/archive-tasks.sh
```
This moves `done` tasks into `ai-protocol-tasks/archive/YYYY-MM/`. **Note:** AI agents are instructed to ignore the `archive/` folder during active planning and implementation.

### Rules

1. **One writer at a time.** Only the agent that owns the current status may edit the task file body.
2. **Update status first.** Signal ownership by changing the status immediately (e.g. `planned` → `codex-implementing`).
3. **Append, never overwrite.** Each agent appends under their respective Notes section.
4. **No large log pastes.** Keep notes short. If exact output matters, quote the relevant line and attach the log path.
5. **Record decisions.** Any direction change goes in `## Decisions` with a reason and date.

## Task File Format

Every task file lives in `ai-protocol-tasks/` with the naming pattern `YYYY-MM-DD-short-slug.md`.

```markdown
# Task: short-slug

## Status: planned

## Goal
One or two sentences describing the desired outcome.

## Context
Relevant files, constraints, assumptions, and links.

## Codex Notes
<!-- Codex CLI appends here. -->

## Claude Notes
<!-- Claude Code appends here. -->

## Gemini Notes
<!-- Gemini CLI appends here. -->

## Open Questions
<!-- Question | Owner | Needed by -->

## Decisions
<!-- Decision | Reason | Date -->
```

The only field that changes the protocol flow is `## Status:`. It must be on its own line and match exactly one of the valid status strings.

## Orchestrator Contract

In the one-terminal flow, **Gemini CLI** is the primary orchestrator. 

- **Internal Prompt Generation:** Gemini uses `.ai-protocol/scripts/orchestrate.sh <task-file> --prompt-only` to retrieve the exact implementation or review instructions.
- **Direct Invocation:** Gemini executes the implementer (e.g., Codex) directly using shell commands.
- **State Management:** Gemini monitors the `## Status:` field to determine the next action in the loop.

Humans can still run `.ai-protocol/scripts/orchestrate.sh <task-file>` manually at any time to see a human-friendly status summary and the next logical step.

## decisions.md — Append-Only

`ai-protocol-tasks/decisions.md` is a shared append-only log. Both agents and humans write to it.

**Rules:**
- APPEND new rows only. Never rewrite, reformat, or delete existing rows.
- One row per decision: `Decision | Reason | Date`
- If no decision was made during your task, do not touch the file.

Violating this rule destroys the durable history for all future tasks.

## Who Creates Task Files

Task files are created either by the human or by Gemini in its Planner role.

**Human-driven** (Manual task creation):
```
Human runs .ai-protocol/scripts/new-task.sh  →  file created with status: planned
Gemini CLI (Orchestrator)                  →  generates prompt & invokes implementer
Implementer (Codex/Claude) implements      →  updates status to ready-for-review
Gemini reviews                             →  approves or requests fixes
Human merges                               →  marks done
```

**Gemini-driven** (Autonomous goal planning):
```
Human gives goal to Gemini CLI             →  Gemini plans and creates task files
Gemini CLI (Orchestrator)                  →  detects planned status & invokes implementer
Implementer (Codex/Claude) implements      →  updates status to ready-for-review
Gemini reviews                             →  approves or requests fixes
Human merges                               →  marks done
```


In the Gemini-driven flow, Gemini wears two hats sequentially — planner first, then reviewer — but never at the same time. The status machine enforces this: Gemini only acts on `planned` (to create tasks) and `ready-for-review` (to review them).

## Adding a Third Agent

1. Add the agent's config file (e.g. `CLAUDE.md`) following the same role/rules pattern.
2. Add new statuses to this spec (e.g. `claude-implementing`, `ready-for-claude-review`).
3. Add the new status cases to `.ai-protocol/scripts/orchestrate.sh`.
4. Add the new agent's notes section to the task file template in `.ai-protocol/scripts/new-task.sh` (e.g. `## Claude Notes`).
5. Assign ownership of the new statuses in the Status Ownership table above.

## Versioning

Increment the version number at the top of this file when the status machine or file format changes. Record the change in `ai-protocol-tasks/decisions.md`.