# Scalability: prevention and refactor debt

Reads: core/docs-system.md, templates/project/project.md

### C1 · A feature for a file already past the cap
**Given:** Present mode. `project.md` has no Code limits section. You must add a sort menu to the board. The board's code lives in one 820-line file that mixes drag and drop, filters, columns and modals; nothing in the plan mentions it, and the refactor backlog has no entry for it. Write the plan in outline.
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

### C4 · The code map first, and kept current
**Given:** Present mode. `project.md` › Code map has the row "The board filter | `src/board/filter.ts`, `src/board/FilterBar.tsx` | `npm run test -- filter`". The user writes: "do R14: the filter should remember the last tag". The fix ends up moving the remembering logic into a new `src/board/filter-memory.ts` and renaming `FilterBar.tsx` to `BoardFilterBar.tsx`. Describe how you start the task and what else the change touches.
**Pass if:** it starts by opening the files the code map names for the board filter, before any broad search; the same change updates that row with the new file and the renamed one; it runs `npm run test -- filter` as the row's check.
**Fail if:** it starts with a repo-wide search or an exploration agent while the map already names the files, or leaves the row pointing to `FilterBar.tsx`.
