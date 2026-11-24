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

- The **journal** (`away-journal-<block>.md`, `work-modes.md`: created at the gate) records done, in progress, parked, next, and the `QA-pending` list. After a compaction or restart, read it and continue within the same time box (`/away-resume` does this in a fresh session).
- One subagent per task when it helps (fresh context); the main session coordinates.
- Re-read the brief and the limits at the start of each task.
- A blocked permission or a failing step is logged and work continues elsewhere.
- Never leave a task half-done on purpose: split it into committable steps, or park the rest.
- Stop when the brief is done, time is up, or nothing safe is left.

## 8. Review in Away

Reviews follow `core/review.md` with the session's intensity and the floor for level-2 work:
- **Level-2 or structural task:** first write its approach in the journal; its plan review (`core/review.md`, Plan review) runs on it before building, and its findings go in the journal under the approach. A Blocker or Major that changes the approved plan parks the task with the finding; anything else is applied in the build, and the review of the built work checks it.
- **`DEP` task:** its review runs right after the commit, before anything builds on it.
- **`ISO` task, and any task without its own QA:** into `QA-pending` (task, commit, what to verify, how). QA over `QA-pending` closes every block at every intensity (`-s` too), together over the block's diff, never skipped for lack of room.
- **Structure check in Away** (`core/review.md`, Running a review): every run uses `--base` the parent of the block's first commit (the journal's first commit line), so earlier blocks' files are not counted.
- **Review block:** the structure check when the block changed code, QA over `QA-pending`, then the advisors the profile and intensity call for, as separate subagents. Fixes and their one re-review follow `core/review.md`, Rounds. Verdicts go into the report, unresolved ones included.
- **If the session ends first,** `/back` or `/away-resume` runs the pending QA before the report; pending advisor reviews go into the report as "to test together", with what to check and how.

## 9. The Away report

**Built progressively.** From the first finished task, keep `away-report-draft-<block>.md` (reply language, plain markdown). After each task add: what was done (commit), the decision cards, what was parked, whether it is `QA-pending`. A card about visual work embeds its captures as markdown images with relative paths (`![R12 phone, dark](../qa/R12/…png)`): the preview shows them, and they cost no tokens because Claude only writes the link. Keep three running lists at the bottom: **Done**, **To test together**, **Parked**. The final report is built from this draft, never from memory.

**Final report:** a self-contained, sober HTML file `away-report-YYYY-MM-DD-HHMM.html` (format per preferences; with `budget: lean`, `away-report-YYYY-MM-DD-HHMM.md` instead, and HTML only when the user asks: `core/economy.md`), generated once at the end of the build block and updated in place after the review block; published as a private artifact when preferences allow; plus a short summary in chat on return. Sections:
1. **Needs your OK:** a review cut first (`core/review.md`, Rounds), then parked items, each with options and a recommendation
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

**Archive the closed block,** whoever ends it, last, once its final report is written and the guard is off: append `END HH:MM` to its journal, then move its brief, journal and report draft to `<local>/away/archive/` (`mkdir -p`, then one `mv` per file; never delete). Then, if more final reports than `away_reports_kept` (preferences) are left in `away/`, the oldest move there too, by the date and time in the name (a date alone counts as the start of its day), a report counting once with its `.md` and `.html`; one whose date cannot be told from its name stays, and the summary names it. Nothing else moves: patches, SQL and notes stay in `away/`, and earlier blocks' brief, journal and draft are left as they are. Captures under `qa/` are neither moved nor relinked, so an archived report's images stop showing (`visual-qa.md`). A move may ask: say in one plain line that it files the closed block's notes away; if it is declined, they stay and the summary says so. **In a cloud session** (`core/git.md` › Cloud sync) the block is archived the same way: the whole local folder travels back, moves included.

Integration happens in Present, only with the user's explicit OK: rejected decisions are first undone with `git revert` on the away branch, then the away branch is integrated into the branch it came from per `core/git.md`. To discard everything: switch back and, with the user's OK, `git branch -D` on the away branch.
