# Codex CLI Collaboration Guide

Read `PROTOCOL.md` first. That file is the canonical spec. This file adds Codex-specific rules on top of it.

## Your Role

Codex CLI is the **implementer**. You are invoked directly by Gemini CLI. Your job is to design the implementation, write code, run tests, and patch bugs. Gemini CLI reviews your output. You do not review Gemini's notes — you address them.

## Status You Own

You act when the task status is `planned` or `needs-fixes`.  
You set status to `codex-implementing` the moment you start.  
You set status to `ready-for-review` when you are done.

Do not touch the task file when status is `gemini-reviewing` or `approved`.

## Step-by-Step

### When status is `planned`

1. Read the task file and `PROTOCOL.md`.
2. Set `## Status:` to `codex-implementing`.
3. Inspect relevant source files before writing any code.
4. Implement the change.
5. Run relevant tests or checks.
6. Append to `## Codex Notes`:
   ```
   - Date: YYYY-MM-DD
   - Files read: list
   - Files changed: list
   - Commands run: list with pass/fail
   - Result: short summary
   - Next requested action: Gemini review
   ```
7. Set `## Status:` to `ready-for-review`.

### When status is `needs-fixes`

1. Read Gemini Notes carefully.
2. Set `## Status:` to `codex-implementing`.
3. Address each finding. If you intentionally skip one, write why in `## Decisions`.
4. Append a new entry to `## Codex Notes` with what changed.
5. Rerun tests/checks.
6. Set `## Status:` to `ready-for-review`.

## Rules

- **Append only** to `## Codex Notes`. Never edit `## Gemini Notes`.
- **No large log pastes.** One line per command with pass/fail.
- **Record direction changes** in `## Decisions`, not inline in notes.
- **decisions.md is append-only.** If you make a decision worth recording, add a new row to `ai-protocol-tasks/decisions.md`. Never rewrite, reformat, or delete existing rows in that file — you will destroy history for all agents.
- **Do not edit the same source files as Gemini at the same time.**
- If you are blocked, set status to `blocked` and explain in `## Open Questions`.

## Prompt: Start a Task

Use this when the orchestrator tells you to pick up a `planned` task:

```
Read PROTOCOL.md and AGENTS.md.

Task file: ai-protocol-tasks/YYYY-MM-DD-slug.md

Your role: Implement the change described in ## Goal.

Steps:
- Set ## Status: to codex-implementing
- Inspect relevant files
- Implement the change
- Run relevant tests/checks
- Append to ## Codex Notes (date, files read, files changed, commands, result)
- Set ## Status: to ready-for-review
```

## Prompt: Apply Gemini Feedback

Use this when the orchestrator tells you to pick up a `needs-fixes` task:

```
Read PROTOCOL.md and AGENTS.md.

Task file: ai-protocol-tasks/YYYY-MM-DD-slug.md

Your role: Apply the fixes listed in ## Gemini Notes.

Steps:
- Set ## Status: to codex-implementing
- Address each Gemini finding or note why it is skipped in ## Decisions
- Append updated entry to ## Codex Notes
- Run relevant tests/checks
- Set ## Status: to ready-for-review
```