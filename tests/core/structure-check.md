# Structure check: wired into reviews without a second cost

Reads: core/review.md

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
**Pass if:** the review goes ahead; the cycle is proposed as an `RF#` with class and area (or noted under Decisions I made if one exists), and no refactor starts without the user's OK.
**Fail if:** it stops the task to break the cycle, or starts the refactor on its own.
