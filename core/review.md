---
name: jacquard-review
description: "How much verification and review each task gets: risk levels, intensity (-s / -ss / -sss), the floor for sensitive work, batches, and the catalogue of checks and reviewers."
---

# Review

Tests do the heavy lifting every time: they are objective, repeatable and cheap. Judgement reviews (QA, advisors) are added where they pay off. Reviewers are the same model with fresh context and a different question, not a second human, so they complement tests and never replace them.

## Risk level (Claude classifies each task)

Shown in the plan next to the task, e.g. `R12 · level 1`. The user can contest it.

| Level | Criteria |
|---|---|
| **0** | No logic and no data; undone with one revert. Copy, spacing, a token value, documentation. |
| **1** | New or changed logic or interaction; a new screen or component; a contained refactor. |
| **2** | Stored data (model, migrations), money or calculations, auth and permissions, personal data, security, external integrations, deletions, the core flow, anything irreversible. |

## Intensity (the user chooses)

Default `-ss`. Set per session (`/rigor -sss`), per Away block (`/away -s 2h | …`) or per message. The project can set its own default.

| Check | `-s` light | `-ss` normal | `-sss` hardened |
|---|---|---|---|
| Automatic checks (types, lint, unit tests, build) | every task | every task | every task |
| Test-first (TDD) | level-2 logic | level 1–2 logic | all logic, plus edge and negative cases |
| End-to-end tests | before integrating | affected flows per batch; full suite before integrating | affected flows per task; full suite per batch |
| Independent QA | level 2 per task; the rest at milestone close | level 2 per task; level 1 per batch | every task |
| Engineering advisor | before structural changes only | + at each milestone close | + at each batch close |
| Security and privacy | level-2 tasks touching auth or personal data | same | + at each batch close |
| Domain advisor | when its trigger fires | same | same |

**Floor:** a level-2 task always gets test-first logic, independent QA on that task and the relevant advisor or security review, whatever the intensity.

**Always, at every level:** the builder checks visual work in a real render. That is verification, not review.

## Batches

A batch is a group of related tasks closed together (one or several roadmap items). Batch reviews look at the batch diff once instead of each task separately. In Away, `DEP` tasks (something builds on them) get their QA before the next task builds on them; `ISO` tasks wait for the batch review.

## Catalogue

- **QA reviewer:** fidelity to the spec, manual and decisions; function; states; accessibility; regressions. Reports, never fixes.
- **Engineering advisor:** approach, architecture, scalability, performance, technical debt. Read-only.
- **Security and privacy reviewer:** authorization, secrets, personal data, input handling, dependencies.
- **Domain advisors:** defined per project with explicit triggers.
- **Full audit:** when adopting a project, before the first release, and every few milestones. Engineers audit their areas; QA reviews the audit.

## Running a review

- One subagent per review, with: this core's `standards.md`, the reviewer's role file, the handoff note, the diff, and only the document sections cited by ID.
- The verdict and every open finding go into the report. Unreviewed work is labelled "no independent review".
- Blockers and Majors are fixed and re-reviewed (changed areas plus regressions) before asking the user to integrate.
