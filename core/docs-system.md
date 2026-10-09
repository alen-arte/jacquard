---
name: jacquard-docs-system
description: "How guiding documents work: markdown as source of truth, artifacts as views, IDs, loading levels, file size and archiving. Read before creating or editing roadmap, decisions, user flows, system manual or refactor backlog."
---

# Documents

## Markdown first, artifacts as views

- The `.md` file is the **source of truth**: flat, easy to search and filter. Templates live in `~/.claude/jacquard/templates/docs/`.
- An artifact (a page the user reads comfortably) is a **view generated from the markdown**, refreshed at checkpoints: end of an Away block, close of a milestone, or when the user asks. Never edit an artifact directly.
- One artifact per document, updated in place at the same link. Before updating, read it and save its current version to `<local>/artifact-backups/<doc>-YYYY-MM-DD-HHMM.html`. Never publish a parallel copy unless the user asks.
- Publishing is optional per project (preferences); without it, the markdown is the document.

## IDs

| ID | What | Lives in |
|---|---|---|
| `R#` | Roadmap item | `roadmap.md` |
| `P#` | Proposal by Claude, not yet approved; becomes an `R#` when approved ("from P7") | `roadmap.md`, proposals table |
| `D#` | Decision (product, design, technical) | `decisions.md` |
| `UF#` | User flow | `user-flows.md` |
| `RF#` | Planned refactor | `refactor-backlog.md` |
| `§n` | Section of the system manual | `system-manual.md` |

IDs are stable and never reused. Origin (user or Claude) is a field, not part of the ID. Cite IDs in commits, Away briefs, report cards, review findings and handoff notes.

## Loading levels

- **Always:** core `standards.md` and the project `index.md`. Keep both short.
- **Per task:** the role file of the role acting, and the document sections cited by ID.
- **Rarely:** whole documents, archives, audits, old reports.

To find something, read the document's index or search by ID; do not read a whole document to find one item.

## Size and structure

- Aim for files under ~200 lines. When one grows beyond that, split it by topic and add an index (one line per file).
- Every documents folder has an index line per file in the project `index.md`.
- Each document opens with a short summary block that says what is current, so a reader rarely needs the rest.

## Archiving

At each phase or milestone close, finished roadmap items move to `roadmap-done.md`, leaving one summary line per group in the roadmap. Superseded decisions stay in `decisions.md`, marked "superseded by D#". Nothing is deleted; it is moved out of the hot path.

## Language

Documents use the project's documents language (preferences). IDs, file names and code stay in English.
