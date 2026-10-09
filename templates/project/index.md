---
name: {{PROJECT_SLUG}}-index
description: "Map of this project for Claude: where things are, who acts when, what is current. Always loaded; keep it under one screen."
---

# {{PROJECT_NAME}}

{{ONE_LINE_PRODUCT}}

- **Starting point:** {{A|B|C|D}} · **Phase:** {{PHASE}} · **Default intensity:** {{INTENSITY}} · **Kit version:** {{KIT_VERSION}}
- **The user here:** {{USER_ROLE_ONE_LINE}}
- **Now:** see `roadmap.md` › Now ({{NOW_IDS}})

## Where things are (read only when needed)

| File | Read when |
|---|---|
| `project.md` | Stack, commands, environments, collaborators and boundaries, irreversibles |
| `roles/<role>.md` | That role acts |
| `away-profile.md` | `/away`, `/back`, `/away-resume` |
| `docs/roadmap.md` | Choosing what next, Away briefs (read by ID) |
| `docs/decisions.md` | Before changing anything confirmed (search by `D#`) |
| `docs/user-flows.md` | Building or reviewing a flow (`UF#`) |
| `docs/system-manual.md` | Any design or UI task (by `§`) |
| `docs/refactor-backlog.md` | Structural work (`RF#`) |

Remove rows for documents that do not exist yet.

## Roles and triggers

| Role | Acts when |
|---|---|
{{ROLE_ROWS}}

## Project rules

Only rules that exist nowhere else and apply to this project alone. Each one may add limits, never loosen the core.

{{PROJECT_RULES_OR_NONE}}
