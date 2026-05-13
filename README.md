# AI CLI Communication Protocol

A modernized, file-based protocol for Gemini CLI to orchestrate collaboration with **Codex** and **Claude** on a shared codebase.

**Gemini plans and reviews. Codex or Claude implements.**

---

## Quick Start (One-Terminal Flow)

1.  **Start Gemini CLI** in your project root.
2.  **Give a goal:** "Implement a greeting flag in examples/hello.py".
3.  **Approve:** Gemini will plan the task and then ask to run an implementer (Codex or Claude). Approve the file-modifying tools.
4.  **Merge:** Once Gemini approves the work, check the diff and merge.

---

## How It Works

This protocol uses a status state machine in `ai-protocol-tasks/` files to manage handoffs between agents.

```
planned
  └─► codex-implementing or claude-implementing
        └─► ready-for-review
              └─► gemini-reviewing
                    ├─► approved ──► done
                    └─► needs-fixes
                          └─► codex-implementing or claude-implementing (loop)
```

In this version of the protocol, **Gemini CLI** handles the orchestration. It reads the task status, generates the prompt for the next agent, and invokes them via the shell.

---

## Repo Structure

```
.
├── .ai-protocol/        ← Canonical spec: rules, agent guides, and scripts
│   ├── PROTOCOL.md
│   ├── GEMINI.md        ← Guide for the Planner/Reviewer
│   ├── AGENTS.md        ← Guide for Codex (Implementer)
│   ├── CLAUDE.md        ← Guide for Claude (Implementer)
│   ├── WORKFLOW.md      ← Step-by-step tutorial
│   └── scripts/
│       ├── orchestrate.sh   ← Generates prompts based on task status
│       └── new-task.sh      ← Scaffolds new task files
└── ai-protocol-tasks/   ← Publicly visible task files and durable decisions
    ├── decisions.md     ← Append-only log of durable decisions
    ├── ref/             ← Sample templates for tasks and decisions
    └── YYYY-MM-DD-*.md  ← Active task files
```

---

## Setup

1.  **Copy** `.ai-protocol/` and `ai-protocol-tasks/` into your repo.
2.  **Ensure** the `gemini`, `codex`, and/or `claude` CLIs are in your `PATH`.
3.  **Start** your interaction with Gemini CLI.
