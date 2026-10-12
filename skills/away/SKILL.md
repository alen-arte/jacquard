---
name: away
description: "Start Away mode: a delegated work block (hours or overnight) while the user is away."
argument-hint: "[-s|-ss|-sss] <duration or end time> | <brief, roadmap IDs, or 'everything you can'>   e.g. -ss 3h | R12–R15"
disable-model-invocation: true
---

Start **Away mode** for this session. Arguments from the user: $ARGUMENTS

1. **Check Jacquard is loaded.** If "Jacquard core standards" and this project's index were not loaded at session start (via `CLAUDE.local.md`), stop: say the project does not use Jacquard (suggest `/kickoff`), its imports were not approved, or kickoff ran in this same session (check `/context`; restart the session and approve).
2. **Read the rules:** `~/.claude/jacquard/core/work-modes.md`, `~/.claude/jacquard/core/away-run.md` and the project's `<local>/away-profile.md`. If the profile does not exist, say so and run a short interview first (three questions at most per screen, tappable options with a default): checks that need a person, where Away works (default: the whole product), extra structural items, extra hard limits, shared files Away may write, advisors for the review block. Create the profile from `~/.claude/jacquard/templates/project/away-profile.md`, show it, and continue only after the user's OK. A profile may only add limits.
3. **Pre-flight gate** exactly as in `work-modes.md` section 1: one short message in the reply language, ending with the meaning "I haven't started yet. Give me the OK and I'll start." Then STOP and wait. Do not start work, do not analyse every task.
4. **On the OK:** message 2 of `work-modes.md` section 1 (brief saved, Away guard on, "Started at HH:MM.", `START` in the journal), the task plan at the top of the journal, the design-manual pass if there is visual or interaction work, then create the branch and work.
5. **Work** by `work-modes.md` sections 2–6 and `away-run.md` sections 7–9 at the chosen intensity (`core/review.md`): after every task, checks → commit → journal line → report-draft entry. Park what must be parked and keep going. Check `date` between tasks; stop at the end time, when the brief is done, or when nothing safe is left.
6. **Finish:** report, views, review block (in that order), then turn the guard off (`~/.claude/jacquard/scripts/away-guard.sh off <local>`) and return to Present with the summary: what needs the user first.

This mode applies to this session only. If the session is cut, `/away-resume` continues it in a fresh session.
