---
name: jacquard-docs-system
description: "How guiding documents work: markdown as source of truth, artifacts as views, IDs, loading levels, file size and archiving. Read before creating or editing roadmap, decisions, user flows, system manual or refactor backlog."
---

# Documents

## Markdown first, artifacts as views

- The `.md` file is the **source of truth**: flat, easy to search and filter. Templates live in `~/.claude/jacquard/templates/docs/`.
- An artifact (a page the user reads comfortably) is a **view generated from the markdown**, refreshed at checkpoints: end of an Away block, close of a milestone, or when the user asks. Never edit an artifact directly.
- One artifact per document, updated in place at the same link. Before updating, read it and save its current version to `<local>/artifact-backups/<doc>-YYYY-MM-DD-HHMM.html`. Never publish a parallel copy unless the user asks.
- Publishing follows `publish_artifacts` in preferences; a project may turn it off in its index rules. Without it, the markdown is the document.

## IDs

| ID | What | Lives in |
|---|---|---|
| `R#` | Roadmap item | `roadmap.md` |
| `P#` | Proposal by Claude; when approved it becomes an `R#` ("from P7") and its row leaves the table at the next roadmap edit | `roadmap.md`, proposals table |
| `D#` | Decision (product, design, technical) | `decisions.md` |
| `UF#` | User flow | `user-flows.md` |
| `RF#` | Planned refactor | `refactor-backlog.md` |
| `§n` | Section of the system manual | `system-manual.md` |

IDs are stable and never reused. Origin (user or Claude) is a field, not part of the ID. Cite IDs in commits, Away briefs, report cards, review findings and handoff notes.

## Loading levels

- **Always:** core `standards.md`, the personal preferences and the project `index.md`. Keep them short.
- **Per task:** the role file of the role acting, and the document sections cited by ID.
- **Rarely:** whole documents, archives, audits, old reports.

To find something, read the document's index or search by ID; do not read a whole document to find one item.

## Size and structure

- Aim for files under ~200 lines. When one grows beyond that, split it by topic and add an index (one line per file).
- Every documents folder has an index line per file in the project `index.md`.
- Each document opens with a short summary block that says what is current, so a reader rarely needs the rest.

## Status marks

One mark per item, so the roadmap tells the truth at a glance:

| Mark | Meaning |
|---|---|
| ⬜ | Not done |
| 🟡 | Done and committed on a branch other than `main` (Present or Away); not in `main` yet. Data line: `branch: <name> · commit: <sha>` |
| ✅ | In `main`, which is what is in production. Data line: `done: YYYY-MM-DD` |

- Claude sets 🟡 in the same task that finishes the item (the roadmap edit goes in the task's commit), never ✅.
- ✅ is set when the branch is integrated into `main` (`core/git.md`, Integration).
- An analysis-only item has nothing to integrate: ✅ when the report is delivered.
- Parked or failed items stay ⬜ with the reason in the data line.
- Why emoji and not `[ ]`/`[x]`: Markdown task boxes have no third state (`[~]` shows as plain text).
- Claude's proposals have their own marks, **first column** of the table, followed by a few words, and each has a bold short title: `**P3 · Title:** detail`. ⬜ proposed · 🔵 approved ("🔵 Approved 2026-10-05 → R12"; also rewritten, merged or absorbed into an `R#`) · ❌ declined. **✅ never appears on a proposal:** it means done, and an approved proposal's progress lives on its `R#`.
- **Proposals leave the table.** The table holds open proposals. 🔵 and ❌ rows stay only until the next roadmap edit, which removes them: an approved one disappears (its `R#` data line keeps `from P#`, so there is no archive entry: it lives on as an `R#`); a declined one moves to `roadmap-done.md` under "Declined proposals" with ❌, the date and the reason, so it is not proposed again.

## Closing an item

When a roadmap item is marked ✅, its data line also records `reviews` (independent reviews run), `findings` (Blocker/Major/Minor) and `rework` (reverts and fix commits after the first review). `/retro` reads these lines instead of the history.

## Planning against the roadmap

Applies whenever the user brings feedback, ideas or a change of direction to plan (in plan mode or not). An explicit request to edit the roadmap does not need a plan. Plan mode cannot write the project's documents, so the roadmap is changed in one step after approval, never live.

1. **Contrast first.** Read `roadmap.md` (Now, Next, Later and the proposals table, by ID) and search `decisions.md` by `D#` for what the input touches. Organize the plan by roadmap ID, so the user's annotations land on each item.
2. **Tag every point** of the input: *already in* (`R#`/`P#`), *changes* (`R#`), *contradicts* (`D#`, with both texts and a recommendation, per the conflicts rule in core standards; asked explicitly, and approving the plan does not settle a contradiction the user did not answer) or *new*.
3. **End the plan with "Roadmap changes"**, in the user's reply language:
   - Items (`R#`): new (an `R#`, origin user, when the user's idea is approved in the plan; a `P#` only for Claude's own ideas still awaiting a yes), changed (what and why), re-marked (⬜/🟡/✅), reordered, split or dropped.
   - Proposals (`P#`): approved (🔵) or declined (❌); never ✅. The table is cleaned at the next roadmap edit.
   - Decisions: new or revised `D#` (superseded ones stay, marked).
   - Everything else the plan does comes after, as its own steps.
4. **After approval**, the first step applies that section to `roadmap.md` and `decisions.md` exactly as approved, before any other work. Nothing in it is re-derived.
5. **No roadmap of its own** (external planning, read-only): contrast against that planning as context; "Roadmap changes" covers only what the project allows (see its `project.md`).
6. **Ordinary requests** (a task with no change of direction) skip this: the plan only names the `R#` it serves.

## Archiving

At each phase or milestone close, finished roadmap items move to `roadmap-done.md`, leaving one summary line per group in the roadmap. Declined proposals are archived there too (see Status marks). Superseded decisions stay in `decisions.md`, marked "superseded by D#". Nothing is deleted; it is moved out of the hot path.

## Language

Documents use `docs_language` (preferences), headings included. IDs, file names, code and the status marks (⬜🟡🔵✅❌⏸🔑) stay as they are.
