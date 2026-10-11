---
name: retro
description: "Look back at closed work: what worked, what cost too much, proposals for the roadmap and notes for the kit. Reads only indexes, data lines and summaries."
argument-hint: "[optional: scope, e.g. 'since R20' or 'last milestone']"
disable-model-invocation: true
effort: low
---

Run a retrospective for this project. Scope from the user: $ARGUMENTS

If "Jacquard core standards" and this project's index were not loaded at session start (via `CLAUDE.local.md`), stop: say the project does not use Jacquard (suggest `/kickoff`), its imports were not approved, or kickoff ran in this same session (check `/context`; restart the session and approve).

1. **Scope:** the arguments; else everything since the last line of `<local>/retro.md`; else the last closed milestone. Say it in one line.
2. **Count (light tier, `~/.claude/jacquard/core/economy.md`):** one subagent reads only these, never whole documents: the data lines of closed items in `docs/roadmap.md` and `docs/roadmap-done.md`; the rows of `docs/decisions.md` in scope; sections 1, 2 and 5 of the Away reports in scope (or their drafts' running lists); `<local>/tests-log.md` if it exists; `git log --oneline` for the range. It returns one table: tasks closed by level; reviews run; findings by severity (Blocker / Major / Minor); reviews with no findings; rework (reverts, fix commits, re-reviews); items parked more than once; decisions added or superseded. Missing data is "not recorded", never estimated.
3. **Judge (this session):** from the table only:
   - **What worked:** up to three, each with its evidence.
   - **What cost too much:** up to three (rework, reviews that found nothing, repeated parking), each with its evidence and the likely cause.
   - **Proposals:** `P#` rows added to the roadmap's proposals table, each with its cost.
   - **Notes for the kit:** rules that were unclear or missing, appended to `<local>/kit-notes.md`. The user decides whether any of them reaches the kit.
4. Append one line to `<local>/retro.md`: date, scope, the table's totals.
5. Report blocks (core standards).
