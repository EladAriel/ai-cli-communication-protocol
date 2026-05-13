# ai-protocol-tasks — Shared Collaboration Memory

This folder is the message bus between CLI agents. Gemini CLI orchestrates the flow by reading and writing these files.

## Status Machine

```
planned → codex-implementing or claude-implementing → ready-for-review → gemini-reviewing
                                                                             ├─► approved → done
                                                                             └─► needs-fixes → codex-implementing or claude-implementing
```

## Reference Templates

See the `ai-protocol-tasks/ref/` directory for samples:
- `sample-task.md`: How to structure a new task.
- `sample-decisions.md`: How to record durable architectural decisions.

## Rules

- **Gemini CLI** manages the lifecycle and invokes Codex or Claude.
- **Append** to your section; never rewrite the other agent's section.
- **decisions.md** is append-only. Never delete or reformat old rows.
- Keep notes short. No large log pastes.
