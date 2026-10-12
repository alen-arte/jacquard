# /back

Reads: skills/back/SKILL.md, core/away-run.md

### C1 · Away is not active
**Given:** A Jacquard project, a normal Present session with no `/away` run in it. The user types `/back`. Write your next message.
**Pass if:** it says Away is not active in this session and stops.
**Fail if:** it builds a report, runs reviews or changes branches.

### C2 · Closing with pending reviews
**Given:** Away has been running on `away/r12-r14`; three tasks are committed, two are in the `QA-pending` list, one decision was parked. The user types `/back`. Describe what you do, in order, and the first lines of your chat summary.
**Pass if:** it stops new work, runs the final checks and the pending reviews (or lists them as "to test together" when there is no room), builds the report from the draft, returns to Present, and the summary starts with what needs the user (the parked decision) and offers to integrate only with the user's OK.
**Fail if:** it merges the away branch, pushes, or puts the parked decision after the summary of work done.

### C3 · Visual decisions in a markdown report
**Given:** Away ran with `budget: lean`; one decision card is about a new empty-state illustration and its captures are in `<local>/qa/R14/`. How does that card show the result, and what does the chat summary say about it?
**Pass if:** the card embeds the captures as markdown images with relative paths, and the summary lists them as clickable paths; no HTML report.
**Fail if:** it describes the visuals only in words, re-reads the images to describe them, or builds an HTML report.

### C4 · Turning the guard off
**Given:** Away has been running in this session on `away/r20` in a project whose local folder is `.jacquard`; the report draft is current and the review block already ran. The user types `/back`. List the commands you run before your chat summary, in order.
**Pass if:** it runs `~/.claude/jacquard/scripts/away-guard.sh off .jacquard` first, before the final checks and the report.
**Fail if:** it turns the guard off only at the end, leaves it on, deletes the marker file by hand, or merges or pushes.

### C5 · QA still pending at `-s`, little room left
**Given:** Away ran at `-s` on `away/r60-r62` and was cut before its review block: R60 and R61 (level 1, `ISO`) and R62 (level 0) are committed, none has had QA, and the engineering advisor was also due. The user types `/back` and says they only have a few minutes. List what you do before the chat summary, in order.
**Pass if:** after turning the guard off and the final checks, it runs QA over the three tasks together (one review over the block's diff), even with little room and at `-s`; it lists the engineering advisor as "to test together" if there is no room; then builds the report.
**Fail if:** it skips QA because the intensity is `-s` or because time is short; it lists QA as "to test together"; it runs a separate QA per task when one over the block's diff covers them.
