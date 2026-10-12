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

One mark per item, so the roadmap tells the truth at a glance. "Dev" means any non-production place: a branch, a dev database, a preview.

| Mark | Status | Applies to | Meaning |
|---|---|---|---|
| ⬜ | **Waiting** | `R` `P` | Nothing started: an `R` waiting to be built, a `P` waiting for a yes or a no |
| ⚖️ | **Decide** | `R` | Claude laid out options and the user must pick one before it can be built. Data line: `options: …` |
| 👀 | **Review** | `R` | Built in dev; the user has not said OK yet. Data line: `branch: <name> · commit: <sha>` |
| 🚀 | **Staged** | `R` | Built in dev, working and approved by the user; only the release to production is left |
| ✅ | **Done** | `R` | Finished and live in production. Data line: `done: YYYY-MM-DD` |
| 🔵 | **Approved** | `P` | The user said yes; it became an `R#` (also for rewritten, merged or absorbed proposals) |
| ❌ | **Rejected** | `R` `P` | Decided NOT to do. Needs a reason (see below) |

Flow of an `R`: ⬜ → (⚖️) → 👀 → 🚀 → ✅. A `P`: ⬜ → 🔵 (its `R#` takes over) or ❌.

- **Who moves it.** Claude sets ⬜, ⚖️ and 👀 (👀 in the same task that finishes the item; the roadmap edit goes in the task's commit). Only the user's explicit OK moves 👀 → 🚀. Only the release to production moves 🚀 → ✅; where `main` is production (see `project.md`), integrating into `main` with the user's OK goes straight from 👀 to ✅ (`core/git.md`, Integration). Away always ends at 👀, never higher.
- **Skipping states is fine** (an analysis-only item goes ⬜ → ✅ when the report is delivered), going backwards is not silent: if the user rejects what is in 👀, it returns to ⬜ with the reason in the data line, or becomes ❌.
- **⚖️ replaces the old `⏸` flag.** `🔑 permission` stays as a flag in the data line: it says what a step needs, not where the item stands.
- **Rejected needs a reason.** Set ❌, `rejected: YYYY-MM-DD` and `why: <reason>` in the data line, and say whether `D#` changes. At the next roadmap edit the item (an `R` or a `P`) leaves the roadmap and moves to `roadmap-done.md` under "Rejected" with ❌, the date, the reason and what it would take to reopen it, so it is not proposed again. Never delete a rejected item without that entry.
- Parked or failed items stay ⬜ with the reason in the data line.
- Why emoji and not `[ ]`/`[x]`: Markdown task boxes cannot show more than two states.
- Claude's proposals keep the mark **first** in the table row, followed by a few words ("⬜ Proposed", "🔵 Approved 2026-10-05 → R12", "❌ Rejected 2026-10-11: reason"), and each has a bold short title: `**P3 · Title:** detail`. **✅ never appears on a proposal:** an approved proposal's progress lives on its `R#`.
- **Approved and rejected rows leave the proposals table** at the next roadmap edit: an approved one disappears (its `R#` data line keeps `from P#`, so nothing is archived); a rejected one moves to `roadmap-done.md` as above.

### Status index (top of the roadmap)

Under the "How to read it" note, the roadmap carries one line per status listing the IDs, so the whole picture reads in seconds:

```
## ▦ Status index
<!-- status-index:start -->
✅ Done: R44, R46 · 🚀 Staged: R60 · 👀 Review: R61 · ⚖️ Decide: R54 · 🔵 Approved: — · ⬜ Waiting: R64, R65, P16 · ❌ Rejected: P8
<!-- status-index:end -->
```

It is derived, never edited by hand: after any change of mark, Claude edits **only the item** and then runs `~/.claude/jacquard/scripts/roadmap-index.sh --write <roadmap.md>`, which rewrites the block between the markers from the marks of the items. `--check` exits 1 if the block is out of date. The pre-commit hook does not run it, so run `--check` before a roadmap edit is committed.

## Closing an item

When a roadmap item is marked ✅, its data line also records `reviews` (independent reviews run), `findings` (Blocker/Major/Minor) and `rework` (reverts and fix commits after the first review). `/retro` reads these lines instead of the history.

## Planning against the roadmap

Applies whenever the user brings feedback, ideas or a change of direction to plan (in plan mode or not). An explicit request to edit the roadmap does not need a plan. Plan mode cannot write the project's documents, so the roadmap is changed in one step after approval, never live.

1. **Contrast first.** Read `roadmap.md` (Now, Next, Later and the proposals table, by ID) and search `decisions.md` by `D#` for what the input touches. Organize the plan by roadmap ID, so the user's annotations land on each item.
2. **Tag every point** of the input: *already in* (`R#`/`P#`), *changes* (`R#`), *contradicts* (`D#`, with both texts and a recommendation, per the conflicts rule in core standards; asked explicitly, and approving the plan does not settle a contradiction the user did not answer) or *new*.
3. **End the plan with "Roadmap changes"**, in the user's reply language:
   - Items (`R#`): new (an `R#`, origin user, when the user's idea is approved in the plan; a `P#` only for Claude's own ideas still awaiting a yes), changed (what and why), re-marked (⬜/⚖️/👀/🚀/✅), reordered, split or dropped.
   - Proposals (`P#`): approved (🔵) or rejected (❌, with the reason); never ✅. The table is cleaned at the next roadmap edit.
   - Decisions: new or revised `D#` (superseded ones stay, marked).
   - Everything else the plan does comes after, as its own steps.
4. **After approval**, the first step applies that section to `roadmap.md` and `decisions.md` exactly as approved, before any other work. Nothing in it is re-derived.
5. **No roadmap of its own** (external planning, read-only): contrast against that planning as context; "Roadmap changes" covers only what the project allows (see its `project.md`).
6. **Ordinary requests** (a task with no change of direction) skip this: the plan only names the `R#` it serves.

## Archiving

A **complete group** is a roadmap section (batch, phase) whose items are all ✅ or ❌.

- **When to ask:** every time a block of work is about to run (the Away gate, or the first task of a batch in Present), even in the same session where the group closed, if any group is complete, ask in one line: "Batch A is complete: move it to Done?". Only the user's OK moves it. A ✅ inside a group with open work is never moved.
- **How it moves:** the group's ✅ items go to `roadmap-done.md` under a heading with the group's name, and the roadmap keeps **one single line** with the last batch moved, replaced each time (never accumulated): `- 📦 **Last moved to Done (2026-10-12):** R55–R57 → roadmap-done.md`. The status index ignores it: it counts only what is still in the roadmap. Nothing is deleted; the full history is in `roadmap-done.md`.
- **Rejected items and proposals** (🔵 and ❌) move at the next roadmap edit without asking, under "Rejected" (see Status marks). Superseded decisions stay in `decisions.md`, marked "superseded by D#". Nothing is deleted; it is moved out of the hot path.

## Language

Documents use `docs_language` (preferences), headings included. IDs, file names, code and the status marks (⬜⚖️👀🚀✅🔵❌🔑) stay as they are.
