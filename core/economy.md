---
name: jacquard-economy
description: "Model tiers, effort and the budget profile: which tier each kind of work uses, the floor that never drops, and how to estimate cost before delegating. Read when launching a subagent, at the Away gate, or when the cost of a step is unclear."
---

# Economy

Spend on judgement, save on repetition. The quality floor never depends on budget: the level-2 floor (core standards), independent QA and verifying before showing stay the same in every profile. What is saved is mechanical, repeated or purposeless work.

## Tiers

Three tiers: **light**, **standard**, **strong**. Preferences map each one to a model and an effort (`tiers`). A project may set its own `budget` with a line in its index (precedence: `preferences.default.md`). Without a mapping, every tier runs on the session's model and only the effort column applies.

What the kit controls: the model and effort of each **subagent** it launches (set per launch), and the effort of a **skill's own turn** (frontmatter). The main session's model and effort are the user's choice; when a step needs a different tier than the session, say so in one line instead of assuming it.

| Work | Tier | Effort |
|---|---|---|
| Mechanical checks: broken references, consistency, format, log summaries, `/retro` counts, skill-test sweeps | light | low |
| Build level 0–1, edit documents | standard | normal |
| Design decisions; build level 2 | standard | high |
| Independent QA | standard (light only for pure consistency sweeps) | normal |
| Design concepts (`design-exploration.md`) | standard | high |
| Design critic | standard | normal |
| Engineering advisor, security and privacy, full audit, structural plan, debate | strong | high |

**Effort:** `low` and `high` are passed as written; "normal" means the tier's effort from preferences, or the session's effort when `tiers` is unset (never passed literally). Light never produces anything the user receives: it counts, compares and flags.

**Floor:** a review of level-2 work never runs below the tier this table gives it, whatever the budget.

## Budget profile

`budget` sets how the table is applied. Intensity (`review.md`) decides **how often** reviews run; budget decides **how much each step costs**. They never override each other. `lean` and `balanced` pick the same tiers; lean differs in two things only: it asks before expensive steps, and a design exploration searches references only after an option set was rejected.

| | lean | balanced (default) | generous |
|---|---|---|---|
| Strong tier | only in the rows that name it | same | also for QA of level-2 work |
| Before `-sss`, or a design exploration's references or second round | say the estimated cost and wait for the OK | say it in the plan | not needed |
| Design references (`design-exploration.md` step 4) | only after a rejection | at high impact or after a rejection | same |
| Screenshots (`visual-qa.md`) | only what changed, plus the sweeps `visual-qa.md` requires | same | also a full sweep at batch close |

`/debate` always says its cost and waits, in every profile. In Away, a cost estimated at the gate is covered by its OK; an expensive step that was not estimated there is parked.

## Estimating cost

Before an Away block, `-sss`, a debate or an exploration, count the subagents it will launch (reviews, passes, critics) from the task list and the intensity table, and write it as one line: "≈ 6 subagent runs (4 standard, 2 strong)". Claude cannot see how much of the user's usage limit is left: never guess it, never present an estimate as a measurement. `/usage` shows real attribution afterwards.

## Launching subagents

- Every subagent except the built-in Explore and Plan already loads `CLAUDE.local.md` and its imports (core standards, preferences, project index). The prompt names the role file, the handoff note, the diff and the IDs; it never pastes or re-reads the always-loaded files.
- Explore and Plan load none of them: use them for searches, never for reviews.
- Pass the tier's model and effort explicitly on each launch.
- One subagent per independent question; batch work that reads the same files (skill tests) into one subagent.
- A follow-up round with the same subagent (a debate's second round, a re-review) continues it instead of launching a new one, when the environment allows it.
- Return only the verdict and the findings; verbose output stays in the subagent.
