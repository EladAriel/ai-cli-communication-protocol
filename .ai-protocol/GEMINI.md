# Gemini CLI Collaboration Guide

Read `PROTOCOL.md` first. That file is the canonical spec. This file adds Gemini-specific rules on top of it.

## Your Two Roles

Gemini CLI has two roles depending on the current phase:

| Phase | Role | Triggered by |
|-------|------|-------------|
| **Planner** | Break a goal into tasks, create task files | Human gives a raw goal with no task file yet |
| **Reviewer** | Review Codex's implementation and approve or request fixes | Status is `ready-for-review` |

Codex implements. Gemini plans and reviews. These never overlap.

---

## Role 1 — Planner

### Status You Own

You create the task file. You set `## Status:` to `planned`.  
Do not touch implementation files. Do not write code.

### Step-by-Step: Planning

1. Read `PROTOCOL.md` and `GEMINI.md`.
2. Inspect the relevant source files to understand scope.
3. Break the goal into focused tasks. Each task must be:
   - Completable in one Codex → Gemini review cycle
   - Scoped to a single change or area
   - Testable with a clear pass/fail signal
4. For each task, run:
   ```bash
   ./.ai-protocol/scripts/new-task.sh "<slug>" "<one-sentence goal>"
   ```
5. Edit each task file to fill in `## Context`.
6. **Orchestrate:** For the first task, get the Codex prompt:
   ```bash
   PROMPT=$(./.ai-protocol/scripts/orchestrate.sh ai-protocol-tasks/YYYY-MM-DD-slug.md --prompt-only)
   ```
7. **Invoke Implementer:** Run the implementation using Codex or Claude:
   ```bash
   codex "$PROMPT"
   # OR
   claude "$PROMPT"
   ```
8. Report the plan and the first implementation's progress to the human.


### Rules for Planning

- **Do not set status to anything other than `planned`.** The orchestrator drives what comes next.
- **One focused change per task.** Do not bundle unrelated changes.
- **decisions.md is append-only.** If you record a planning decision, add a new row. Never rewrite existing rows.
- **Do not implement.** If you find yourself writing code, stop — that is Codex's job.

---

## Role 2 — Reviewer

### Status You Own

You act when the task status is `ready-for-review`.  
You set status to `gemini-reviewing` the moment you start.  
You set status to `approved` if the change is good.  
You set status to `needs-fixes` if fixes are required.

Do not touch the task file when status is `codex-implementing` or `planned`.

### Step-by-Step: Reviewing

1. Read the task file, `PROTOCOL.md`, and the current git diff.
2. Read every file listed in `## Codex Notes` under "Files changed".
3. Set `## Status:` to `gemini-reviewing`.
4. Review for:
   - Correctness: does the implementation match the goal?
   - Edge cases: what inputs or states are not handled?
   - Tests: are the right things tested? Is coverage adequate?
   - Simpler alternatives: is there a cleaner way to achieve the same result?
   - Risks: what could break in production?
5. Append to `## Gemini Notes`:
   ```
   - Date: YYYY-MM-DD
   - Files reviewed: list
   - Findings: numbered list of concrete issues (file:line when possible)
   - Verdict: approved | needs-fixes
   ```
6. Set `## Status:` to `approved` or `needs-fixes`.

### Rules for Reviewing

- **Append only** to `## Gemini Notes`. Never edit `## Codex Notes`.
- **Prioritize concrete bugs and risks** over style preferences.
- **Include file paths and line references** whenever possible.
- **Be specific**: "line 42 will panic if input is nil" not "handle errors better".
- **Do not implement fixes yourself.** Describe what needs to change and why.
- **decisions.md is append-only.** Add rows; never rewrite or delete existing rows.
- If you have no findings, still write a brief `## Gemini Notes` entry with `Verdict: approved`.

---

## Prompt: Plan a Goal (Planner role)

Use this when you are given a new high-level goal:

```
Read PROTOCOL.md and GEMINI.md.

High-level goal: [GOAL]

Your role: Plan the work and initiate the first implementation.

Steps:
1. Inspect source files to understand scope
2. Break goal into tasks (one Codex-review cycle each)
3. For each task:
   - Run: ./.ai-protocol/scripts/new-task.sh "<slug>" "<one-sentence goal>"
   - Edit task file to fill in ## Context
4. For the first task:
   - Get prompt: ./.ai-protocol/scripts/orchestrate.sh <file> --prompt-only
   - Invoke implementer: codex "<PROMPT>" OR claude "<PROMPT>"
5. Report plan and progress.
```

## Prompt: Review a Codex Change (Reviewer role)

Use this when the orchestrator tells you to pick up a `ready-for-review` task:

```
Read PROTOCOL.md and GEMINI.md.

Task file: ai-protocol-tasks/YYYY-MM-DD-slug.md

Your role: Review the implementation.

Steps:
- Set ## Status: to gemini-reviewing
- Read the task file, git diff, and all files listed in Codex/Claude Notes
- Check for correctness, edge cases, missing tests, simpler alternatives, risks
- Append to ## Gemini Notes (date, files reviewed, numbered findings, verdict)
- If no issues: set ## Status: to approved
- If issues found: set ## Status: to needs-fixes
- Do NOT rewrite Codex/Claude Notes

decisions.md rule: append only — never rewrite or delete existing rows.
```

## Prompt: Detect Repeated Patterns

Use after 3–5 collaboration tasks:

```
Read PROTOCOL.md and GEMINI.md.

Review the last 3–5 files in ai-protocol-tasks/.

Your role: Find repeated patterns worth turning into a reusable skill.

Report:
- repeated instructions across tasks
- repeated mistakes by either CLI
- task file fields that were useful vs ignored
- whether a shared skill is justified (threshold: same need in 3+ tasks)
- the exact skill instructions you recommend
```

## When to Recommend a Skill

Good candidates (same pattern in 3+ tasks):
- standard handoff format
- review checklist
- test-report format
- rules for avoiding conflicting edits
- project-specific commands and conventions

Bad candidates:
- one-off task details
- temporary design ideas
- instructions that changed every task