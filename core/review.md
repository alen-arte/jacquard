---
name: jacquard-review
description: "How much verification and review each task gets: risk levels, intensity (-s / -ss / -sss), the floor for sensitive work, batches, and the catalogue of checks and reviewers."
---

# Review

Tests do the heavy lifting every time: they are objective, repeatable and cheap. Judgement reviews (QA, advisors) are added where they pay off. Reviewers are a model with fresh context and a different question, not a second human, so they complement tests and never replace them.

Risk levels (0, 1, 2) and the floor for level 2 are in core standards.

## Intensity (the user chooses)

Default `-ss`. The most specific setting wins: per message > per Away block (`/away -s 2h | …`) > per session (`/rigor -sss`) > the project default (`index.md`) > `default_intensity` in preferences (`-ss`).

| Check | `-s` light | `-ss` normal | `-sss` hardened |
|---|---|---|---|
| Automatic checks (types, lint, unit tests, build) | every task | every task | every task |
| Test-first (TDD) | level-2 logic | level 1–2 logic | all logic, plus edge and negative cases |
| End-to-end tests | before integrating | affected flows per batch; full suite before integrating | affected flows per task; full suite per batch |
| Independent QA | level 2 per task; the rest at milestone close | level 2 per task; level 1 per batch | every task |
| Engineering advisor | before structural changes only | + at each milestone close | + at each batch close |
| Security and privacy | level-2 tasks touching auth, permissions, personal or financial data, secrets, payments or external integrations | same | + at each batch close |
| Domain advisor | when its trigger fires | same | same |

**Always, at every level:** the builder checks visual work in a real render (`visual-qa.md`). That is verification, not review.

**Missing role:** if the project has no file for a reviewer this table or the floor calls for, run it from the kit's role file (`~/.claude/jacquard/roles/review/`). The floor never drops. A domain advisor that was never created is not improvised: say "no domain review".

## Batches

A batch is a group of related tasks closed together (one or several roadmap items). Batch reviews look at the batch diff once instead of each task separately. In Away, `DEP` tasks (something builds on them) get their QA before the next task builds on them; `ISO` tasks wait for the batch review.

## Catalogue

- **QA reviewer:** fidelity to the spec, manual and decisions; function; states; accessibility; regressions. Reports, never fixes.
- **Engineering advisor:** approach, architecture, scalability, performance, technical debt. Read-only.
- **Security and privacy reviewer:** authorization, secrets, personal data, input handling, dependencies.
- **Domain advisors:** defined per project with explicit triggers.
- **Design critic:** filters design concepts before the user sees them (`design-exploration.md`); on rendered results only at milestones or when the intensity calls for it.
- **Full audit:** when adopting a project (offered by kickoff, with its own OK), before the first release, and every few milestones. Engineers audit their areas; QA reviews the audit.

## Running a review

- One subagent per review, prompted as core standards say, at the tier in `economy.md`, with the diff and only the document sections cited by ID.
- The verdict and every open finding go into the report.
- Blockers and Majors are fixed and re-reviewed (changed areas plus regressions) before asking the user to integrate.
