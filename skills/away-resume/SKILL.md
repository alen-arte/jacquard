---
name: away-resume
description: "Continue an Away block that was cut off (usage limit, crash) from its journal, in a fresh session."
argument-hint: "[optional: new end time or changes to the brief]"
disable-model-invocation: true
---

Resume an interrupted **Away** block. This is a fresh session: it starts in Present until the state is read, then returns to Away rules. Extra instructions: $ARGUMENTS

1. If "Jacquard core standards" and this project's index were not loaded at session start (via `CLAUDE.local.md`), stop: say the project does not use Jacquard (suggest `/kickoff`), its imports were not approved, or kickoff ran in this same session (check `/context`; restart the session and approve). Read `~/.claude/jacquard/core/work-modes.md`, `~/.claude/jacquard/core/away-run.md` and the project's `<local>/away-profile.md`.
2. Find the latest files in `<local>/away/`: journal, report draft, brief. Do not read large HTML reports unless needed.
3. Check the state: `git branch --show-current` (expect `away/...`; switch to it only if the tree is clean), `git status --short`, `git log --oneline -10`. Compare the last journal line with the last commit.
4. Say in 3–5 lines where it was cut: last finished task, anything half-done (keep, finish or revert, safest first), which block was running, what remains.
5. **Permission audit of what remains** (`work-modes.md` section 1, only for the remaining tasks and the items parked for lack of a permission): the user is here now, so this is the moment to ask. If anything would ask, one short question with a default (allow it, or run it now while the user is here, or keep it parked) and wait for the answer; if nothing would, say so in one line and go on.
6. Turn the Away guard on for this session (`~/.claude/jacquard/scripts/away-guard.sh on <local>`; if it fails, log it and continue without it). Continue without the rest of the pre-flight: same branch, brief, intensity, rules and limits. Time box from the arguments, else until the remaining blocks are done. Do not redo finished tasks. Do not fetch, pull, rebase or merge.
7. Same per-task order and block order as `away-run.md` section 7. Journal line: `RESUMED HH:MM from <last task>`.
8. Finish like `/away`: report (update the existing artifact in place if already published), guard off, return to Present, summary with what needs the user first.
