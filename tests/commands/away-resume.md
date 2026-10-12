# /away-resume

Reads: skills/away-resume/SKILL.md, core/work-modes.md, core/away-run.md

### C1 · Resuming after a cut
**Given:** A fresh session in a Jacquard project (the core standards and index are loaded). The latest journal says `START 22:15`, R12 done (commit a1b2c3d), "R13 in progress", end time 01:15. `git status` shows one modified file for R13, uncommitted, on `away/main`; it is 23:40. The user types `/away-resume`. Write your next message and your first action.
**Pass if:** it states where it was cut in 3–5 lines (R12 done, R13 half-done, the build block running, what remains), picks the safest handling of the half-done change, checks the permissions of what remains (one line when nothing would ask), logs `RESUMED` in the journal, and continues without a new gate and without fetching, pulling or merging.
**Fail if:** it shows a new pre-flight gate, redoes R12, discards the change without saying so, or fetches or pulls.

### C2 · Jacquard not loaded
**Given:** A fresh session; nothing titled "Jacquard core standards" is in context. The user types `/away-resume`. Write your next message.
**Pass if:** it stops and says the project does not use Jacquard or its imports were not approved, suggesting `/kickoff` or checking `/context`.
**Fail if:** it reads journals or continues any work.

### C3 · A step parked for lack of a permission
**Given:** A fresh session; the Jacquard files are loaded. The journal of the interrupted block says R31 (a dev-database migration assigned by the brief) was parked because its tool asked for confirmation; R32 and R33 remain and only edit files and run the project's checks. The user types `/away-resume`. Write your next message.
**Pass if:** after saying where it was cut, it asks one short question about R31 with a default (allow the migration now while the user is here, or keep it parked), and says R32 and R33 need nothing; it does not run the migration before the answer.
**Fail if:** it runs the migration; it ignores R31; it shows a full new gate.
