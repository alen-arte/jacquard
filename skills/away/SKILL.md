---
name: away
description: "Start Away mode: a delegated work block (hours or overnight) while the user is away."
argument-hint: "[-s|-ss|-sss] <duration or end time> | <brief, roadmap IDs, or 'everything you can'>   e.g. -ss 3h | R12–R15"
disable-model-invocation: true
---

Start **Away mode** for this session. Arguments from the user: $ARGUMENTS

1. **Find the project layer.** Read the project index (`<local>/index.md`, imported by `CLAUDE.local.md`). If this project does not use Jacquard, stop and suggest `/kickoff`.
2. **Read the rules:** `~/.claude/jacquard/core/work-modes.md` and the project's `<local>/away-profile.md`. If the profile does not exist, say so and run a short interview first (three questions at most per screen, tappable options with a default): checks that need a person, what Away may decide freely here, extra structural items, extra hard limits, shared files Away may write, advisors for the review block. Create the profile from `~/.claude/jacquard/templates/project/away-profile.md`, show it, and continue only after the user's OK. A profile may only add limits.
3. **Pre-flight gate** exactly as in `work-modes.md` section 1: one short message in the reply language, ending with the meaning "I haven't started yet. Give me the OK and I'll start." Then STOP and wait. Do not start work, do not analyse every task.
4. **On the OK:** apply the answers, save the brief to `<local>/away/brief-YYYY-MM-DD.md`, write one line "Started at HH:MM.", `START HH:MM` in the journal, the task plan at the top of the journal, the design-manual pass if there is visual or interaction work, then create the branch and work.
5. **Work** by `work-modes.md` sections 2–9 at the chosen intensity (`core/review.md`): after every task, checks → commit → journal line → report-draft entry. Park what must be parked and keep going. Check `date` between tasks; stop at the end time, when the brief is done, or when nothing safe is left.
6. **Finish:** report, views, review block (in that order), then return to Present with the summary: what needs the user first.

This mode applies to this session only. If the session is cut, `/away-resume` continues it in a fresh session.
