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
│       ├── new-task.sh      ← Scaffolds new task files
│       └── archive-tasks.sh ← Moves completed tasks to archive
└── ai-protocol-tasks/   ← Publicly visible task files and durable decisions
    ├── decisions.md     ← Append-only log of durable decisions
    ├── archive/         ← Completed tasks (organized by YYYY-MM)
    ├── ref/             ← Sample templates for tasks and decisions
    └── YYYY-MM-DD-*.md  ← Active task files
```

---

## Why "The Protocol"?

### The "Lone Orchestrator" Value Proposition
This protocol has a distinct value proposition for a specific type of developer: the **"Lone Orchestrator"** who wants to keep everything inside their Git repository with zero infrastructure overhead.

#### Why use this solution instead of [OACP](https://oacp.dev/)?
While OACP is a powerful "Agent OS" for fleets, this protocol is a **"Developer Workflow"** for focused execution.

1.  **Zero Infrastructure:** OACP requires installing a CLI (`oacp-cli`) and managing a separate `$OACP_HOME` directory. This solution is just a folder in your repo. If a dev clones the repo, they have the protocol.
2.  **Markdown vs. YAML:** Developers live in Markdown. Reading a `.md` task file is naturally intuitive for a human. OACP uses YAML messages in inbox/outbox folders, which is great for machines but higher friction for a developer who wants to quickly "peek" at what the AI is doing.
3.  **Git-Native Context:** Because your tasks live in `ai-protocol-tasks/`, they are committed to Git. This means the "Why" and "How" of every change are versioned alongside the code. OACP messages typically live outside the project repo, making it harder to link a specific commit to the conversation that created it.
4.  **Role Specialization:** This protocol explicitly defines the **Gemini-as-Planner** and **Codex/Claude-as-Implementer** roles. OACP is a "blank slate"—you have to build those roles yourself. This is a "batteries-included" workflow for this specific pairing.

**The "Pitch":** Use OACP if you are building an AI company with 10 agents talking to each other. Use this protocol if you are a **Senior Dev** who wants to use Gemini as an "Architect" to manage "Junior AI Coders" directly in your existing repo.

---

### Scalability: What if `ai-protocol-tasks/` gets too large?
The "file bloat" problem is real. If you have 500 tasks, the folder becomes a mess and Gemini’s context window will get clogged if it tries to read everything.

1.  **The "Decision Log" as Long-Term Memory:** `decisions.md` is your secret weapon. When a task is marked `done`, Gemini is instructed to "compress" any architectural changes or new rules into `decisions.md`. You can then archive the original task file because the important outcome is preserved.
2.  **The `archive/` Folder:** Once a task reaches `done`, run `./.ai-protocol/scripts/archive-tasks.sh` to move it to `ai-protocol-tasks/archive/YYYY-MM/`. This keeps the root folder clean while keeping history searchable.
3.  **Task Truncation (The "Snapshot" Rule):** If a single task file becomes too long (e.g., 10 rounds of `needs-fixes`), it's a sign the task was too big. Gemini (as Planner) MUST close that task as "failed/split" and create smaller sub-tasks to prevent the "Context Wall."
4.  **Git is your Backup:** You don't need to keep `done` files forever. Since they were committed to Git, you can always find them in history. You can safely delete files from `ai-protocol-tasks/` once they are merged and archived.

---

## Setup

1.  **Copy** `.ai-protocol/` and `ai-protocol-tasks/` into your repo.
2.  **Ensure** the `gemini`, `codex`, and/or `claude` CLIs are in your `PATH`.
3.  **Start** your interaction with Gemini CLI.
