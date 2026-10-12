---
name: jacquard-work-modes
description: "Present (default) and Away (a delegated block of hours or overnight). Universal rules only; each project adds its own limits in its Away profile. Read on /away, /back and /away-resume."
---

# Work modes

| | Present (default) | Away (delegated) |
|---|---|---|
| When | The user is at the computer | The user is away for hours or overnight |
| Starts | Every new session | Only with `/away` |
| Ends | — | `/back`, the end time, the brief done, or nothing safe left |
| Important decisions | Ask first | Decide within section 3, or park |
| Reporting | Report blocks at the end of each reply | Full Away report |

**Away never persists across sessions.** A new session always starts in Present.

**Project layer.** Before anything else, read the project's Away profile (`<local>/away-profile.md`). It may only **add** limits and specifics (commands, collaborators, what counts as structural there, which roles review). It can never loosen this file. If a profile line seems to loosen a rule here, treat it as a rule conflict.

All Away files live in `<local>/away/` (`<local>`: see core standards): the brief, the journal, the report draft and the reports. Parked items live in the journal and the report draft.

## 1. Pre-flight: a fast gate, then an explicit start

The user must always know whether work has begun. Two messages, and **nothing starts before the user's OK**.

**Message 1, the gate** (fast, short, in the reply language). Do not analyse every task or propose designs here. Run `date` and `git status`, read the brief once and write:
- **Understood:** the scope in 2–4 lines and the tasks in order, each tagged `DEP` (a later task in the block builds on it) or `ISO` (nothing later needs it), with its risk level. If the brief cites roadmap IDs, use them. If it says "everything you can", pick from the roadmap's Now and Next. If the brief looks bigger than one session, one line saying so.
- **Needs you first:** roadmap items in scope marked ⚖️ (decide) or `🔑` (permission), and any complete group to archive ("Batch A is complete: move it to Done?", `core/docs-system.md`, Archiving), and anything the brief explicitly assigns that needs a permission (a migration, a dependency). Each with a default.
- **Time, branch, intensity, cost:** start time, end time, the away branch and the branch it integrates into (`core/git.md`; a new name if the session is on `main`), intensity (`core/review.md`: arguments, else session, else project default), and the estimated cost in subagent runs (`core/economy.md`).
- **Permission check:** append `GATE HH:MM` to the journal now, so any permission prompt for `<local>/away/` appears while the user is still here.
- **Permission mode:** Away runs in **auto** mode (Shift+Tab): in the default mode every edit asks and the block stalls at the first prompt. Deny rules hold in every mode; an action the auto classifier blocks is logged and work continues. Remind the user in one line, together with the model and effort that preferences ask for in Away, if any; the mode changes nothing in these rules.
- **Only if real:** a conflict (the brief contradicts itself or a confirmed decision; uncommitted changes in the tree) or something genuinely unclear about what the user wants, each with a default. What the brief leaves open ("you decide", "propose") is not a question: decide it during the work and report it.
- **Last line, always the same meaning:** "I haven't started yet. Give me the OK and I'll start." No question mark, no alternatives.

**Message 2, the start** (right after the OK): apply any answers, save the brief to `<local>/away/brief-YYYY-MM-DD.md`, then one line "Started at HH:MM." and write `START HH:MM` in the journal.

**Design-manual pass** (after the OK, part of the work): if the brief has visual or interaction work, one subagent reads the system manual (`docs/system-manual.md`, by the sections that apply) and the design decisions in `decisions.md`, plus the brief, and returns a one-page digest per task: decisions (`D#`), tokens, shape grammar, open items, conflicts. It goes at the top of the journal. A conflict found now is not a reason to stop: the brief wins; if it truly can't be resolved, park that decision and continue.

## 2. Commits and safety rails

- Commits follow `core/git.md`, on the away branch only.
- If checks fail and about three reasonable attempts don't fix it: revert to the last good commit, log it, move on.
- Verify before moving on: the project's checks (`project.md`) and a real render for visual work (`core/visual-qa.md`). Checks that need a person (the profile lists them) are logged as pending for the user.
- Never invent scope to fill the time. Finishing early is fine.

## 3. What Away decides with autonomy (and reports)

Core standards › Decisions apply. Within them, and within where the Away profile says Away works:

- **New elements:** their visual design, motion, copy, states and layout within a screen, built from the design standards and the system manual.
- **Interaction details** of what is being created, within existing flows.
- **Implementation inside the existing structure,** including contained refactors that change no behaviour and no interfaces.
- **Never change something built and confirmed** unless the brief says so explicitly. If an improvement seems worth it, park it as a proposal (`P#`, marked ⬜).

Every one of these gets a decision card. Prefer the most reversible, least invasive option.

## 4. Structural changes: park, don't do

Decisions the user must see before they exist:
- Data model, stored data shape, interfaces or contracts between parts
- Architecture or code organisation at scale (new layers, moving or renaming many modules, replacing routing, state management or framework)
- Adding, removing or swapping dependencies
- What the product does or a core user flow (adding or removing features, reordering the main journey, changing the navigation paradigm)
- Anything inside an area owned by a collaborator beyond wiring (see core standards)
- Large cross-cutting changes outside the brief
- Whatever the Away profile adds

**Quick test:** "Would the user be surprised to find this when they return?" If yes, park it.

## 5. Hard limits: never, even in Away

- Pushing to any remote, merging into any non-away branch, deploying, tagging releases
- Force operations and history rewriting; deleting branches or commits
- Deleting or overwriting data
- Data migrations, **except** a migration the brief explicitly assigns as a task: then only on a non-production environment, after a backup made right before it, and reported with where the backup is and how to restore it
- Secrets, credentials, environment variables, auth and permissions
- Anything that costs money or touches paid services, billing or accounts
- Sending anything to anyone (messages, emails, PR or issue comments, sharing an artifact). Publishing or refreshing **private** artifacts (the Away report, document views) is allowed when preferences enable it; sharing is the user's call
- Touching files outside the project (except the project's own local folder), installing global software, changing system or git configuration
- Disabling or weakening tests, linters or safety checks to make something pass
- Writing into shared planning files or other people's documents, except the notes file named in `project.md` and the shared files the user approved in the Away profile
- Putting local paths, private links or personal-layer content into anything shared (notes, commits, shared files)

## 6. When to park

Park a decision when at least one is true: it is structural (4) or crosses a hard limit (5); it needs the user's taste or product intent that cannot be inferred from the rules, the spec or earlier decisions; two options have materially different consequences that are hard to reverse; it falls where two rules conflict; guessing wrong would cause real rework.

When parking: write what, options, recommendation and what is blocked. Keep working on everything that does not depend on it. A provisional default only if it is trivially reversible and clearly marked.

## 7. Long runs: the session can be cut at any moment

Claude cannot see how much of the session limit is left, so Away is built to be cut at any moment without losing anything.

**Order of blocks** (written at the top of the journal):
1. **Build:** the tasks, ordered system → function → aesthetics, respecting dependencies. Markdown documents are updated as part of each task (roadmap item set to 👀 with branch and commit, then the status index regenerated, per `core/docs-system.md` Status marks; new `D#`; `UF#` changes).
2. **Report:** the report is already current (section 9); generate the HTML once the build block ends, and publish it if preferences allow.
3. **Views:** refresh artifact views of the documents that changed, in place, with a backup first (`core/docs-system.md`).
4. **Review (last):** the review queue, per section 8.

**After every task, in order:** checks → commit → one journal line → one entry in the report draft.

- The **journal** (`away-journal-YYYY-MM-DD.md`) records done, in progress, parked, next, and the `QA-pending` list. After a compaction or restart, read it and continue within the same time box (`/away-resume` does this in a fresh session).
- One subagent per task when it helps (fresh context); the main session coordinates.
- Re-read the brief and the limits at the start of each task.
- A blocked permission or a failing step is logged and work continues elsewhere.
- Never leave a task half-done on purpose: split it into committable steps, or park the rest.
- Stop when the brief is done, time is up, or nothing safe is left.

## 8. Review in Away

Reviews follow `core/review.md` with the session's intensity and the floor for level-2 work:
- **`DEP` task:** its review runs right after the commit, before anything builds on it.
- **`ISO` task:** added to `QA-pending` (task, commit, what to verify, how) for the review block.
- **Review block:** QA over `QA-pending`, then the advisors the profile and intensity call for, as separate subagents. Verdicts go into the report, unresolved ones included.
- **If the session ends first,** whatever is still pending appears in the report as "to test together", with what to check and how.

## 9. The Away report

**Built progressively.** From the first finished task, keep `away-report-draft-YYYY-MM-DD.md` (reply language, plain markdown). After each task add: what was done (commit), the decision cards, what was parked, whether it is `QA-pending`. A card about visual work embeds its captures as markdown images with relative paths (`![R12 phone, dark](../qa/R12/…png)`): the preview shows them, and they cost no tokens because Claude only writes the link. Keep three running lists at the bottom: **Done**, **To test together**, **Parked**. The final report is built from this draft, never from memory.

**Final report:** a self-contained, sober HTML file `away-report-YYYY-MM-DD-HHMM.html` (format per preferences; with `budget: lean`, `away-report-YYYY-MM-DD-HHMM.md` instead, and HTML only when the user asks: `core/economy.md`), generated once at the end of the build block and updated in place after the review block; published as a private artifact when preferences allow; plus a short summary in chat on return. Sections:
1. **Needs your OK:** parked items first, each with options and a recommendation
2. **Summary:** what was asked, done, not done, time used
3. **Decisions I made:** one card each: the decision, why, alternatives and why not, impact, how to reverse it (commit)
4. **State:** branch, commits, check results
5. **Reviews:** verdicts
6. **Notes for collaborators:** ready to hand over (when the profile names any)
7. **Risks and odd things noticed**
8. **How to review it and how to undo it:** see it live, the diff, keep or discard the branch

Be honest: failures, reverts and uncertainty are reported. Parked or failed items are never presented as done.

## Ending Away and integrating

`/back` ends the mode: stop new work, close safely, run the pending reviews if there is room, finish the report, return to Present and present what needs the user first.

Integration happens in Present, only with the user's explicit OK: rejected decisions are first undone with `git revert` on the away branch, then the away branch is integrated into the branch it came from per `core/git.md`. To discard everything: switch back and, with the user's OK, `git branch -D` on the away branch.
