---
name: jacquard-work-modes
description: "Present (default) and Away (a delegated block of hours or overnight): the gate and the rules that hold during the block (sections 1–6). Universal rules only; each project adds its own limits in its Away profile. Read on /away and /away-resume."
---

# Work modes

Sections 1–6 are here. Running the block, reviews in Away, the report and ending (sections 7–9) are in `away-run.md`.

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
- **Needs you first:** roadmap items in scope marked ⚖️ (decide) or `🔑` (permission), and any complete group to archive ("Batch A is complete: move it to Done?", `core/docs-system.md`, Archiving), anything the brief explicitly assigns that needs a permission (a migration, a dependency), and whatever the permission audit finds. Each with a default.
- **Time, branch, intensity, cost:** start time, end time, the away branch and the branch it integrates into (`core/git.md`; a new name if the session is on `main`), intensity (`core/review.md`: arguments, else session, else project default), and the estimated cost in subagent runs (`core/economy.md`).
- **Permission audit** (silent; only what would ask is written): for each task, the tools and commands it needs beyond editing files (git, scripts, MCP tools), matched against `permissions` in `.claude/settings.local.json`, `.claude/settings.json` and `~/.claude/settings.json` (deny, then ask, then allow) and against the profile's "Tools that confirm on their own": allowed in settings is not the same as prompt-free. What would ask goes under **Needs you first**: for a settings rule, the user adds an allow now or the step is parked; for a tool that confirms on its own, no rule can silence it, so the step is parked or run right after the OK while the user is still here; for a deny, it is parked or done with a safe equivalent (section 2). If nothing would ask: one line, "Permissions: nothing would ask." Then append `GATE HH:MM` to the journal, so a prompt for `<local>/away/` appears while the user is still here.
- **Memory check:** the user's feedback memories about Away, permissions or migrations, if any. Stricter than this file: follow it and say so in one line. Looser: a rule conflict (core standards); park the affected task until the user answers. Quote a memory only in chat or the journal; elsewhere write "a saved preference conflicts with …".
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
- **Before a command or tool the audit did not cover,** match it against `ask`, `deny` and the profile's "Tools that confirm on their own". If it matches, use the safe equivalent or park the step; never wait on a prompt. Safe equivalents, with commands the template already allows:
  - Set aside uncommitted work: a WIP commit on the away branch (not `stash`, `reset`, `restore` or `checkout --`).
  - See a check fail without a fix: write the test first and run it before the fix (test-first). If the fix is already committed separately from its test: `git revert --no-edit HEAD`, run the check, `git revert --no-edit HEAD` again; if they share a commit, log "not shown failing".
  - Tools: only the commands `project.md` lists (such as `npm run <script>`); never `npx` or a binary it does not list.

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
- Data migrations, **except** a migration the brief explicitly assigns as a task **and** either the gate's audit found its tool runs without a prompt or the user chose at the gate to have it run right after the OK, while present: then only on a non-production environment, after a backup made right before it, and reported with where the backup is and how to restore it. Otherwise it is parked with the SQL, the backup step and the restore step ready, for the user to run on return
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

