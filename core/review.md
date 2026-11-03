---
name: jacquard-review
description: "How much verification and review each task gets: risk levels, intensity (-s / -ss / -sss), the floor for sensitive work, batches, and the catalogue of checks and reviewers."
---

# Review

Tests do the heavy lifting every time: they are objective, repeatable and cheap. Judgement reviews (QA, advisors) are added where they pay off. Reviewers are a model with fresh context and a different question, not a second human, so they complement tests and never replace them.

Risk levels (0, 1, 2) and the floor for level 2 are in core standards.

## Intensity (the user chooses)

Default `-ss`. The most specific setting wins: per message > per Away block (`/away -s 2h | …`) > per session (`/rigor -sss`) > the project default (`index.md`) > `default_intensity` in preferences (`-ss`).

| Check | Tier · effort | `-s` light | `-ss` normal | `-sss` hardened |
|---|---|---|---|---|
| Automatic checks (types, lint, unit tests, build) | — | every task | every task | every task |
| Test-first (TDD) | — | level-2 logic | level 1–2 logic | all logic, plus edge and negative cases |
| End-to-end tests | — | before integrating | affected flows per batch; full suite before integrating | affected flows per task; full suite per batch |
| Independent QA | standard · normal (strong for level 2 with `budget: generous`; light only for pure consistency sweeps) | level 2 per task; the rest at milestone close | level 2 per task; level 1 per batch | every task |
| Engineering advisor | strong · high | before structural changes (on the plan: Plan review); on the affected area when duplication is found that the task did not resolve (by QA, or by the builder outside the task's scope; a structure-check duplicate warning counts once confirmed: Running a review) | + at each milestone close | + at each batch close |
| Security and privacy | strong · high | level-2 tasks touching auth, permissions, personal or financial data, secrets, payments or external integrations | same | + at each batch close |
| Domain advisor | standard · normal | when its trigger fires | same | same |
| Design critic on rendered results (`design-exploration.md` step 7) | standard · normal | at milestone close | same | + at each batch close that built an explored design |

**Always, at every level:** the builder checks visual work in a real render (`visual-qa.md`), and searches for existing equivalents before building (core standards › Scalability). That is verification, not review. **In Away,** QA closes every block at every intensity, over the tasks that had none (`away-run.md` section 8).

**Missing role:** if the project has no file for a reviewer this table or the floor calls for, run it from the kit's role file (`~/.claude/jacquard/roles/review/`). The floor never drops. A domain advisor that was never created is not improvised: say "no domain review".

## Batches

A batch is a group of related tasks closed together (one or several roadmap items). Batch reviews look at the batch diff once instead of each task separately. In Away, `DEP` tasks (something builds on them) get their QA before the next task builds on them; `ISO` tasks wait for the batch review.

## Plan review

A design mistake (what enters, what leaves, what triggers what) is cheapest to catch before it is built. One reviewer reads the plan, not the code:

- **Level 2, always:** the reviewer the floor names for the task (security and privacy when its triggers fire, else a domain advisor whose trigger fires, else the engineering advisor), at its row's tier; two only when two triggers fire.
- **Level 1, only with a structural change:** the engineering advisor, in its "before structural changes" slot.
- **Level 0, never:** one revert undoes it.
- The prompt passes the plan (in Away, the task's approach, written in the journal first), the `D#` it cites and the files it names. The reviewer returns design findings only.
- **One pass, no re-review:** its findings are applied to the plan, and the review of the built work receives them and checks they were applied. A plan the user later changes is reviewed again only when the change adds a level-2 or structural part.
- **In Present,** it runs before the plan is shown, so the user approves a reviewed plan; it is part of the floor, so its cost is said in one line before it runs, without waiting. **In Away,** at the start of each level-2 or structural task (`away-run.md` section 8).

## Catalogue

- **QA reviewer:** fidelity to the spec, manual and decisions; function; states; accessibility; regressions. Reports, never fixes.
- **Engineering advisor:** approach, architecture, scalability, performance, technical debt. Read-only.
- **Security and privacy reviewer:** authorization, secrets, personal data, input handling, dependencies.
- **Domain advisors:** defined per project with explicit triggers.
- **Design critic:** filters design concepts before the user sees them (`design-exploration.md`), at every exploration; on rendered results per the table above.
- **Debate:** for a decision that is irreversible, structural or about the product's direction, Claude may propose `/debate` in the plan, with its cost. It never starts one itself, and never in Away.
- **Full audit:** when adopting a project (offered by kickoff, with its own OK), before the first release, and every few milestones. Engineers audit their areas; QA reviews the audit.

## Running a review

- One subagent per review, at its row's tier and effort, both passed explicitly: the model and effort come from `tiers` in preferences, and "normal" is the tier's own effort (without `tiers`, the session's). Level-2 work is never reviewed below its row's tier, whatever the budget. QA runs as the `jacquard-qa-reviewer` subagent when it is installed (listed among the available subagent types; `INSTALL.md` step 2): read-only tools and a turn cap, so it cannot run the checks and the prompt carries their results and the captures. Every other review, and QA where that subagent is not installed, runs as a general-purpose subagent (never Explore or Plan: they do not load the core standards).
- **Structure check, for code:** before any review of code, the builder runs `~/.claude/jacquard/scripts/structure-check.sh --base <the branch the work integrates into> --project <local>/project.md` (it only reads; Away's base: `away-run.md` section 8). A `✗` is resolved first, only by a move core standards › Scalability allows without asking (undoing a cycle the task made is one); anything wider is a proposed `RF#` (in Away: parked). The output goes into QA's and the engineering advisor's prompts; no reviewer re-measures it. Warnings add no review: the advisor, in its existing slot, reads whole only the files on the `Flagged:` line. A file on the `Flagged past the cap:` line is read whole once, and that read proposes its `RF#` if it has none; while its `RF#` is open or awaiting the user's OK (the builder passes its ID), the advisor reads only the changed parts and the functions they touch, and searches the rest. A duplicate warning counts as duplication found (table) only once confirmed as the same behaviour. No script, or running it would ask (found by the gate's audit; in Away the step is parked): prompts and report say "no structure check" and why.
- The prompt names the role file and the handoff note, and passes the diff, the files in point 6 of the handoff note and only the document sections cited by ID. A diff alone cannot show that a behaviour already exists elsewhere: QA and the engineering advisor also search the repo for equivalents of what the diff adds; an advisor triggered by QA gets QA's finding and its files. It never pastes or re-reads the always-loaded files: the subagent already has them.
- The reviewer returns only its verdict and findings.
- The verdict and every open finding go into the report.

## Rounds

- **First round:** Blockers and Majors are fixed. One the builder judges wrong is not fixed: the re-review gets the reason and decides (agreed: closed; not: still open). A Minor is fixed in the batch only when the fix is contained and adds nothing new; otherwise it goes on the item's data line (`open: m4–m6`) or becomes its own item (`R#`; `RF#` for structure). In Away, a fix that would be structural (`work-modes.md` section 4) is parked instead.
- **One re-review per review that had a Blocker or Major,** by a fresh subagent in that review's role: never the first reviewer continued, which reloads its whole earlier conversation every round. The prompt passes the role file, each finding (with the builder's reason when disputed), the diff of its fix, the functions it touches and their callers, the `D#` the findings cite, point 4 of the handoff note, and the checks' results (for level-2 logic, the test showing each fix failing, then passing; for code, the structure check of the fix). The reviewer checks that each finding is closed and that nothing calling the changed code broke, and searches the repo for equivalents of what the fix adds. Tier: the original row's for level-2 work (the floor) and for a fix that changes the design; standard otherwise.
- **The cut:** if the re-review finds a new Blocker or Major, or one still open, there is no second fix round. The finding becomes a roadmap item with `blocks: <branch>` (`docs-system.md`, Status marks), first in the roadmap's Now and on the `Now:` line of the project's `index.md` (its ID with `blocks: <branch>`); the report opens with it. The branch is not integrated unless the user explicitly says to integrate it despite the cut. The next Present session starts with it, and other work starts before it only if the user asks for it explicitly; `/away-resume` reports it, never fixes it.
- **Minors the re-review finds:** a contained one (wording, one line, nothing new) is fixed right away with no further review, marked "no independent review" on the item's data line and in the report, and covered by the next batch or milestone review; any other is recorded as in the first round. What a review round costs is the next review, not the edit.
- **Before asking to integrate** (and when an Away block closes): every Blocker and Major fix has had its re-review (one that has not runs now, or is listed as open), and no cut is open. In Present, if the batch reached the size in `economy.md` (Too big for one session) or the context was compacted, recommend continuing in a new session: every reply resends the whole conversation.
