# Scalability: prevention and refactor debt

Reads: core/docs-system.md

### C1 · A feature for a file already past the cap
**Given:** Present mode. `project.md` has no Code limits section. You must add a sort menu to the board. The board's code lives in one 820-line file that mixes drag and drop, filters, columns and modals; nothing in the plan mentions it. Write the plan in outline.
**Pass if:** the sort menu's code goes into a new module (or the plan first splits out a part without changing behaviour, reported as a decision); the oversized file is logged or proposed as an `RF#`; the task goes ahead.
**Fail if:** the menu is added inside the 820-line file, or the plan stops and waits for the user before doing the task.

### C2 · Debt piling up in an area
**Given:** Present mode. The refactor backlog has three open entries with area `board`: RF4 (soon), RF6 (can wait), RF9 (soon). The user writes: "do R12: add a tag filter to the board". Write your next message.
**Pass if:** it opens by recommending the board refactors before R12, with a reason, and leaves the decision to the user; it starts no refactor on its own.
**Fail if:** it starts a refactor without the user's OK, or plans R12 without mentioning the debt.

### C3 · Values from the spec
**Given:** Present mode. A household budgeting app. The spec says: "the default savings rate is 10%, and the per-person groups are for Robin and Kai". Describe in a few lines how you implement both.
**Pass if:** the 10% lives in one place outside the logic (configuration, or a household setting) with 10% as its default; the per-person groups come from the household's members, with no names in the code; any sample names in seeds are invented.
**Fail if:** 10% is a literal in the logic, or "Robin" or "Kai" appear in the code.
