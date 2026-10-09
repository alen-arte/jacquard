# Jacquard guide

## The idea in one minute

Jacquard gives every project the same hidden structure: standards that set the bar, roles that act only when needed, reviews proportional to risk, documents with stable IDs, and two ways of working. The kit stays generic; your preferences and each project's files stay private.

## Commands

| Command | What it does |
|---|---|
| `/kickoff` | Starts or adopts a project: starting point, short interview, proposal, files |
| `/away [-s\|-ss\|-sss] <time> \| <brief>` | Delegates a block of hours. Asks for your OK before starting |
| `/back` | Ends Away and gives you the report, what needs you first |
| `/away-resume` | Continues an Away block that was cut off |
| `/rigor -s\|-ss\|-sss` | Sets review intensity for the session |
| `/kit-update` | Brings a project up to the installed kit version, with your OK |

## A normal day

1. Open Claude Code in the project: it starts in **Present** mode.
2. Ask for a roadmap item by ID ("let's do R12") or describe what you want.
3. Claude plans, shows the risk level of each task, builds, verifies, and ends with the report blocks: done, decisions made, how to verify, what needs your OK, what comes next.
4. When leaving: `/away 3h | R12–R15`. Answer the gate, give the OK. On return: `/back`.

## Review intensity

| | What changes |
|---|---|
| `-s` light | Tests always; independent reviews mostly at milestones |
| `-ss` normal (default) | Reviews per batch; sensitive work reviewed per task |
| `-sss` hardened | Reviews per task, more tests, advisors per batch |

Sensitive work (data, money, auth, privacy, irreversible) always gets its reviews, whatever the intensity.

## IDs

`R#` roadmap item · `P#` Claude's proposal · `D#` decision · `UF#` user flow · `RF#` planned refactor · `§n` manual section.

## Where things are

| Place | What |
|---|---|
| `~/.claude/jacquard/` | The kit (core, roles, templates, commands) |
| `~/.claude/jacquard-personal/` | Your preferences and each project's files (private repo) |
| `<project>/.jacquard/` | Link to the project's files: index, project facts, roles, Away profile, documents, Away reports |
| `<project>/CLAUDE.local.md` | Imports the core, your preferences and the project index. Never tracked |

## Phases (default)

Kickoff → framing (flows, roadmap) → walking skeleton → usable MVP → system manual → iterations → release. See `core/method.md`.
