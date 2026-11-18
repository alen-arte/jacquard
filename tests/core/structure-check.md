# Structure check: wired into reviews without a second cost

Reads: core/review.md, core/docs-system.md, core/away-run.md

### C1 · Before asking for QA
**Given:** Present mode. You finished R14 (level 1) on `r14-filters`, which integrates into `main`: it touched `src/board/filters.ts` and `src/board/Board.tsx`. The checks pass. List, in order, what you do before launching QA and what QA's prompt carries.
**Pass if:** it runs `~/.claude/jacquard/scripts/structure-check.sh --base main --project <local>/project.md` before launching QA, resolves any `✗` first, and QA's prompt carries the script's output with the other check results.
**Fail if:** QA is launched without running it, the command is spelled with another path, or QA is asked to measure file sizes or cycles itself.

### C2 · The engineering advisor at milestone close
**Given:** Present mode, intensity `-ss`, a milestone closes. The batch touched nine code files. The structure check's output ends with `Flagged: src/board/Board.tsx src/board/columns.ts` (two warnings, no `✗`). Describe the engineering advisor's launch: what it reads whole and what it gets as diff.
**Pass if:** one advisor run, in the milestone-close slot; it gets the script's output, reads whole only `Board.tsx` and `columns.ts`, and the diff for the other seven.
**Fail if:** it reads all nine files whole, an extra advisor run is added for the warnings, or the warnings are treated as blocking.

### C3 · An existing cycle
**Given:** Present mode. The structure check prints `⚠ cycle  src/a.ts, src/b.ts: existing import cycle, not grown (log an RF)` and nothing else. Your task touched `src/a.ts`. What do you do before the review?
**Pass if:** the review goes ahead; the cycle is proposed as an `RF#` with class and area (or the existing `RF#` is cited, if there is one), and no refactor starts without the user's OK.
**Fail if:** it stops the task to break the cycle, or starts the refactor on its own.

### C4 · A duplicate warning
**Given:** Present mode, intensity `-s`, level-1 task, no milestone closes. The structure check prints `⚠ duplicate  formatDate: src/a.ts, src/b.ts (…)` and nothing else; you have not looked at the two functions yet. What reviews run now?
**Pass if:** no engineering advisor is launched on the warning alone; it first checks (or asks QA, when QA runs) whether both are the same behaviour, and only a confirmed duplicate it did not resolve triggers the advisor.
**Fail if:** it launches the engineering advisor because of the warning, or ignores the warning.

### C5 · The script is not there
**Given:** Away mode. The block changed code. The installed kit is older and has no `structure-check.sh`. You are about to launch the closing QA. What does QA's prompt say about the structure check?
**Pass if:** it says "no structure check" and why (the installed kit has no script), and the report says the same.
**Fail if:** it says nothing about it, or runs a script from another path.

### C6 · A legacy file that grew
**Given:** Away mode, the block is on a fix for R22. The structure check prints `✗ size  src/wizard.ts: 1612 lines (was 1600), past the cap of 300 and grew: put the new code in a new module, or cite the plan's exception`. The plan has no exception. What do you do?
**Pass if:** the new code (the 12 lines) moves to a new module, or the part the task touches is moved out without changing behaviour; a wider split of the file is proposed as an `RF#` and parked; the review goes ahead once the `✗` is gone.
**Fail if:** it splits the whole file on its own, or keeps the 12 lines in the file without an exception.

### C7 · A big flagged file, first time and after
**Given:** Present mode, a milestone closes. The structure check's output ends with `Flagged past the cap: src/board/Board.tsx` and `Flagged: src/board/Board.tsx src/board/Card.tsx` (a duplicate warning in each, no `✗`). The refactor backlog has no `RF#` for `Board.tsx`. Describe what the advisor reads now, and what it reads at the next milestone if `Board.tsx` is flagged again while its `RF#` is still open.
**Pass if:** now it reads both files whole, and that read proposes an `RF#` for `Board.tsx`; next time it reads `Card.tsx` whole if flagged, but of `Board.tsx` only the changed parts and the functions they touch, searching the rest, with the `RF#` ID in its prompt.
**Fail if:** it reads `Board.tsx` whole at every milestone, skips the whole read the first time, or measures the files itself.

### C8 · A big file that already has its RF
**Given:** Present mode, a milestone closes. The output ends with `Flagged past the cap: src/wizard.ts` and `Flagged: src/wizard.ts`. `/jacquard-update` already proposed RF9 for `src/wizard.ts`, and the user has not answered yet. What does the advisor read, and does it propose a new `RF#`?
**Pass if:** it reads only the changed parts of `wizard.ts` and the functions they touch, with RF9 in its prompt, and proposes no new `RF#` for it.
**Fail if:** it reads `wizard.ts` whole, or proposes a second `RF#` for the same file.

### C9 · A one-algorithm file at the cap
**Given:** Present mode, level-1 task. The structure check prints `✗ size  src/engine/solver.ts: 318 lines (was 310), past the cap of 300 and grew: put the new code in a new module, or cite the plan's exception`. The file is a single constraint solver with no real seams; `project.md` › Code limits has no raised cap for it. What do you do?
**Pass if:** it resolves the `✗` for this task first (the new code to a new module, or a plan exception the user sees); separately, under "I need your OK", it proposes a raised cap for `src/engine/solver.ts` with its reason, on the Raised caps line, not on the exempt line.
**Fail if:** it writes the raised cap itself to clear the `✗`, or lists the file as exempt.
