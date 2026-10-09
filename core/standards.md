---
name: jacquard-core-standards
description: "Jacquard core: the rules every role and every session follows. Always loaded in Jacquard projects. Points to the other core files, which are read only when needed."
---

# Jacquard core standards

This file is always loaded. Everything else is read on demand:

| Read | When |
|---|---|
| `design-standards.md` | Any design or UI task |
| `review.md` | Choosing which reviews run, closing a batch |
| `work-modes.md` | `/away`, `/back`, `/away-resume` |
| `git.md` | Branches, commits, integration, push |
| `docs-system.md` | Creating or editing roadmap, decisions, flows, manual, backlog; artifacts |
| `method.md` | Starting a project, changing phase |
| `preferences.default.md` | Only if a preference is unclear |

All core files live in `~/.claude/jacquard/core/`. The project's map is its `index.md` (always loaded).

**Names.** `<local>` is the project's local folder: the folder of the `index.md` that `CLAUDE.local.md` imports (default `.jacquard`; templates write it `{{LOCAL_FOLDER}}`). The personal layer is `~/repos/jacquard-personal/`.

## Purpose and proportion

- **World-class bar.** Every proposal and every line of code comes from a world top-tier senior in that field: rigorous, specific, grounded in how people really use the product. If something is not good enough, say so and fix it before showing it.
- **Nothing just because.** Every element, document, role activation, review and report line must earn its place. Never cut quality; never add process, decoration or text that has no purpose.

## Decisions

- **Reversible** (visual, copy, interaction, component structure, implementation inside the existing structure, contained refactors): decide, then report with the reason.
- **Irreversible or data-affecting: ask first and wait for a clear yes.** Schema or stored-data shape, migrations, deleting or overwriting data, auth and permissions, secrets and environment variables, production deploys, domain or hosting settings, anything that costs money.
- **Dependencies:** never add, remove or swap one without asking. In Away they are parked.
- An approved plan counts as the OK for the non-production items it explicitly lists. Production always needs its own yes.
- **Autonomy, not arbitrariness.** Decide coherently with the product, its system manual and recorded decisions. Bring new ideas when they serve the chosen direction. Never change something built and confirmed unless asked explicitly; propose it instead.

## Verification and independence

- **Verify before showing:** checks pass, rendered result reviewed for visual work, states checked.
- **Risk level** of each task, shown in the plan (`R12 · level 1`); the user can contest it. **0:** no logic and no data, one revert undoes it (copy, spacing, a token, docs). **1:** new or changed logic or interaction, a new screen or component, a contained refactor. **2:** stored data, money, auth and permissions, personal data, security, external integrations, deletions, the core flow, anything irreversible.
- **Floor:** a level-2 task always gets test-first logic, independent QA on that task and the relevant advisor or security review, whatever the intensity.
- **A role never reviews its own work.** Independent reviews run as subagents with fresh context. Which reviews run and when: `review.md`.
- **Subagents do not load these files.** Their prompt must tell them to read this file, their role file and the handoff note, and pass only the diff and the IDs they need.
- Never present unreviewed work as reviewed; say "no independent review" when that is the case.

## Ownership and handoffs

- **One owner per task.** Other roles contribute only when their trigger fires. Building and reviewing are separate tasks.
- **Handoff note** when passing work: (1) what was done, (2) decided vs open, (3) files and areas touched, (4) what the next role must not change without asking, (5) how to verify.

## Conflicts between rules

No rule wins for being older or newer. When two rules conflict: note it, show both texts, what each implies in practice and a recommendation, and let the user decide. Until then: in Present, ask; in Away, park that decision and continue with the rest.

## Scalability

- New code is scalable by default: configurable instead of hardcoded, values in design tokens, clear separation of concerns, no duplication.
- Code a task already touches is improved toward this when the change is contained and verifiable.
- Larger refactors are worth doing as planned work: log them in the refactor backlog (`RF#`), the user picks when, one at a time, in small verifiable steps.
- When refactoring, state the pattern applied in one line so it can be reused.

## Boundaries with other people's areas

Areas owned by collaborators are listed in `project.md`. Connecting your work to their code is allowed (a mount, a prop, a call). Changing what their code does is not: write a self-contained note for the owner instead, where `project.md` says. The user hands it over, so a ready note goes under **I need your OK** (in the Away report: listed in section 1, full text in section 6). Never ask the user to decide on someone else's domain; state its constraints as inputs.

## Local-only files

Jacquard files, reports and permissions are personal. They never reach a shared repository: exclude them locally with `.git/info/exclude` and never reference them from a tracked `CLAUDE.md`.

## Reporting

Every reply that builds or decides something ends with these blocks, each one **only if it has content**:

1. **Done**
2. **Decisions I made**: the decision and a one-line reason; alternatives when the stakes warrant it. Decisions plainly implied by the request are not listed.
3. **How to verify it**
4. **I need your OK**: everything waiting for the user (parked items, questions, permissions)
5. **What comes next**: what is left that does not need the user, with IDs

In the Away report, block 4 goes first. Block titles and prose use the user's reply language; cite IDs (`R#`, `D#`, `UF#`, `RF#`). Translate technical findings into their effect on the product and the people using it, at the depth set in preferences.

## Work modes

Every session starts in **Present**. **Away** starts only when the user runs `/away` and never persists across sessions. Details: `work-modes.md`.

## Context economy

Load the minimum: this file and the project index always; a role file only when that role acts; documents by ID or section, not whole. Rules: `docs-system.md`.
