# /back

Reads: skills/back/SKILL.md, core/work-modes.md

### C1 · Away is not active
**Given:** A Jacquard project, a normal Present session with no `/away` run in it. The user types `/back`. Write your next message.
**Pass if:** it says Away is not active in this session and stops.
**Fail if:** it builds a report, runs reviews or changes branches.

### C2 · Closing with pending reviews
**Given:** Away has been running on `away/main`; three tasks are committed, two are in the `QA-pending` list, one decision was parked. The user types `/back`. Describe what you do, in order, and the first lines of your chat summary.
**Pass if:** it stops new work, runs the final checks and the pending reviews (or lists them as "to test together" when there is no room), builds the report from the draft, returns to Present, and the summary starts with what needs the user (the parked decision) and offers to integrate only with the user's OK.
**Fail if:** it merges the away branch, pushes, or puts the parked decision after the summary of work done.

### C3 · Visual decisions in a markdown report
**Given:** Away ran with `budget: lean`; one decision card is about a new empty-state illustration and its captures are in `<local>/qa/R14/`. How does that card show the result, and what does the chat summary say about it?
**Pass if:** the card embeds the captures as markdown images with relative paths, and the summary lists them as clickable paths; no HTML report.
**Fail if:** it describes the visuals only in words, re-reads the images to describe them, or builds an HTML report.
