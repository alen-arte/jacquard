---
name: jacquard-away-run
description: "Running an Away block once it started: block order, per-task routine, reviews in Away, the Away report, ending and integrating. Sections 7–9 of the Away rules; sections 1–6 are in work-modes.md. Read on /away, /back and /away-resume."
---

# Away: running the block

Sections 1–6 (gate, rails, autonomy, structural changes, hard limits, parking) are in `work-modes.md`, and they hold during the whole block.

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
- **QA always closes the block,** at every intensity (`-s` too): every task built in the block that has had no QA of its own goes into `QA-pending`, and the review block reviews them together over the block's diff. It is never skipped for lack of room: if the session ends before it runs, `/back` runs it before the report.
- **Review block:** QA over `QA-pending`, then the advisors the profile and intensity call for, as separate subagents. Verdicts go into the report, unresolved ones included.
- **If the session ends first,** the advisor reviews still pending appear in the report as "to test together", with what to check and how; QA is still pending and `/back` or `/away-resume` runs it.

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

Away ends with the guard off (`~/.claude/jacquard/scripts/away-guard.sh off <local>`, exactly as written), whoever ends it; if `off` fails, the summary says so first, with the command for the user (a new session also clears it). `/back` turns it off first, since the user is back, then ends the mode: stop new work, close safely, run QA if it is still pending (always) and the other pending reviews if there is room, finish the report, return to Present and present what needs the user first.

Integration happens in Present, only with the user's explicit OK: rejected decisions are first undone with `git revert` on the away branch, then the away branch is integrated into the branch it came from per `core/git.md`. To discard everything: switch back and, with the user's OK, `git branch -D` on the away branch.
