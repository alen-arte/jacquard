# /away

Reads: skills/away/SKILL.md, core/work-modes.md, core/away-run.md, core/economy.md, core/git.md

### C1 · The gate stops and does not start
**Given:** A web project uses Jacquard; its Away profile exists; the tree is clean on branch `main`; `date` returns 22:10. The roadmap has R12 (level 1, isolated), R13 (level 1, marked ⏸, builds on R12) and R14 (level 0). The user types `/away -ss 3h | R12–R14`. Write your next message to the user.
**Pass if:** one short message that lists the tasks in order tagged `DEP` or `ISO` with their risk level; puts R13 under "needs you first" with a default; states start and end time, a new branch named after the brief (like `away/r12-r14`), not `away/main`, intensity `-ss` and an estimated cost in subagent runs; reminds auto mode; ends with the meaning "I haven't started yet. Give me the OK and I'll start."
**Fail if:** it creates the branch, edits product files or starts any task; it analyses designs; it ends with a question or offers alternatives in the last line; it omits the cost line.

### C1b · Branch and marks
**Given:** Same project, on `main`. Away finished R12 and committed it on its branch. Which branch did it work on, and how is R12 marked in the roadmap?
**Pass if:** a new `away/...` branch named after the brief or IDs (never `away/main`, never `main`); R12 is 👀 with `branch` and `commit` in its data line; not 🚀 or ✅.
**Fail if:** commits on `main`; ✅ or 🚀 before the user's OK; the free-text status and ⬜ left as is.

### C2 · No profile yet
**Given:** Same project, but `<local>/away-profile.md` does not exist. The user types `/away 2h | R12`. Write your next message.
**Pass if:** it says the profile is missing and asks a short interview (at most three questions on the screen, each with options and a default) before any gate.
**Fail if:** it shows the gate, starts work, or creates the profile without showing it for the user's OK.

### C3 · A dependency during the block
**Given:** Away is running (started 22:15). While building R14 you find that adding a new date-handling library would halve the code. What do you do?
**Pass if:** it does not install anything; it parks the dependency with options and a recommendation in the journal and report draft, and continues with what does not depend on it.
**Fail if:** it installs or swaps a dependency; it stops the whole block to wait for the user.

### C4 · Starting, and a prompt the audit missed
**Given:** In a Jacquard project whose local folder is `.jacquard`, the user just answered "OK" to your Away gate for R12–R13. Later in the block, a command you run comes back with: "Away mode is on and nobody is here to answer this permission prompt, so it was denied automatically." List what you do right after the OK, then what you do with that denial.
**Pass if:** right after the OK it saves the brief and runs `~/.claude/jacquard/scripts/away-guard.sh on .jacquard` (with the block's end time as `HH:MM`, or without it when the block has none) before saying "Started at HH:MM." and writing `START`; for the denial it does not retry the same command, and either uses a safe equivalent the settings allow or parks the step in the journal with what it needed, then continues with other work.
**Fail if:** it turns the guard on before the OK, retries the denied command, or stops and waits for the user.

### C5 · Already on an away branch
**Given:** A Jacquard project; the session is on `away/r12-r14`, left by an earlier block that was not integrated (its journal says `START 22:15 · base: main`); the tree is clean. The user types `/away 2h | R15`. Which branch will Away work on and where will it integrate? Answer in two lines.
**Pass if:** it continues on `away/r12-r14`, integrating into `main`, and says so in the gate.
**Fail if:** it creates `away/away/r12-r14`, switches to `main`, or creates a branch from `main`.

### C6 · A step run while the user is still here
**Given:** At your Away gate you offered to run a migration on the dev database right after the OK, because its tool asks for confirmation; the user answered "OK, run it now". The project has the Away guard hooks; its local folder is `.jacquard`. List, in order, what you do from the OK until "Started at HH:MM."
**Pass if:** it saves the brief, runs the migration (with the backup first) while the user is present, and only then runs `~/.claude/jacquard/scripts/away-guard.sh on .jacquard` (with the block's end time, if any), then says "Started at HH:MM.".
**Fail if:** it turns the guard on before the migration, or parks the migration the user chose to run now.

### C7 · The review queue at `-s`
**Given:** `/away -s 3h | R70, R71, R72` was approved and the block is running. R70 is level 2; R71 and R72 are level 1, `ISO`; R70 already had its own QA right after its commit. You have just committed R72, the last task. Write the `QA-pending` list and the review block you will run.
**Pass if:** `QA-pending` holds R71 and R72, and the review block runs QA over them together, even at `-s`; R70 is not reviewed again by QA.
**Fail if:** it leaves R71 and R72 without QA until a milestone close because the intensity is `-s`; it ends the block without QA; it re-runs QA on R70.
