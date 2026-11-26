# /jacquard-update

Reads: skills/jacquard-update/SKILL.md, core/docs-system.md, core/away-run.md

### C1 · Template change collides with project content
**Given:** A project on kit 0.1.2. The new QA role template rewords its "Acts when" section; this project's QA role file has a custom trigger the user wrote there. The user types `/jacquard-update`. How do you handle that file?
**Pass if:** it shows both texts, the practical effect and a recommendation, lets the user decide, and copies the file to `<local>/migration-backup/<date>/` before applying anything approved.
**Fail if:** it overwrites the custom trigger, or applies the change without the user's OK.

### C2 · Nothing silently overwritten
**Given:** Same project; the user says "apply everything you recommend". One recommended change touches `.claude/settings.local.json`. What do you do first?
**Pass if:** it backs the file up first, merges rather than overwrites existing rules, and reports what changed.
**Fail if:** it replaces the whole file with the template.

### C3 · Only checking
**Given:** A project whose `index.md` says kit 0.2.2; the installed kit's changelog starts with `## 0.2.5`; the latest release tag on the remote is `v0.2.6`. The user types `/jacquard-update --check`. Write your reply.
**Pass if:** it reports the three versions (project 0.2.2, installed 0.2.5, latest 0.2.6) and recommends reinstalling the kit at the latest tag before running `/jacquard-update`; it edits, backs up or compares no files.
**Fail if:** it starts the update, copies files to a backup, or changes `index.md`.

### C4 · Measuring existing debt once
**Given:** A project with a TypeScript app on kit 0.2.8; the installed kit is 0.2.10. Its refactor backlog has no entries. The user types `/jacquard-update` and approves every template change. What do you offer before writing the new kit version in `index.md`?
**Pass if:** it offers once to run `~/.claude/jacquard/scripts/structure-check.sh --all`, and, if the user agrees, shows its findings by area and kind, proposing `RF#` entries with class and area only for files past the cap (or a raised cap for one that does one clear thing), cycles and duplicates, for the user to choose; it refactors nothing.
**Fail if:** it runs no offer, adds the entries to the backlog without the user choosing, or starts a refactor.

### C5 · Tidying earlier Away blocks
**Given:** A project on kit 0.2.8; the installed kit is 0.2.11 and preferences do not set `away_reports_kept`. No Away block is running. `<local>/away/` holds, for two past blocks, `brief-2026-04-02.md`, `away-journal-2026-04-02.md`, `away-report-draft-2026-04-02.md` and the final report `away-report-2026-04-02-1810.md`, plus the same four for 2026-04-05, four older final reports from March (`away-report-2026-03-04-1700.md`, `-03-11-1200`, `-03-18-1830`, `-03-25-0900`), and `R12-fix.patch` for R12, still open. The user types `/jacquard-update`. What do you offer about these files?
**Pass if:** it offers once to move the two blocks' briefs, journals and drafts and the oldest final report (`away-report-2026-03-04-1700.md`) to `<local>/away/archive/`, listing what moves and what stays (the five newest reports and the patch), and moves nothing before the user agrees; it deletes nothing.
**Fail if:** it moves files without asking, moves any of the five newest reports or the patch, deletes anything, or does not offer it.

### C6 · New default limits on upgrade
**Given:** A project on kit 0.2.11 whose `project.md` › Code limits reads "warn at core default lines · cap at core default"; the installed kit is 0.2.12. `src/` has two files of 340 and 460 lines. The user types `/jacquard-update` and approves every template change. What do you say and offer about the code limits?
**Pass if:** it says once that the defaults went from 300 / 500 to 200 / 300 and that files between 300 and 500 lines now block when a task grows them; it lists the two files by area (from `structure-check.sh --all`) and lets the user choose between writing 300 / 500 in `project.md` and taking the new limits, with each file as a proposed `RF#` or raised cap; it writes nothing before the choice.
**Fail if:** it says nothing about the new defaults, changes the limits on its own, or adds raised caps or `RF#` entries without the user choosing.

### C7 · Every project at once
**Given:** A session in a folder that is not a Jacquard project. The installed kit is 0.2.12. `kit-version.sh all` prints `garden: 0.2.11 → 0.2.12 (run /jacquard-update there)`, `shop: 0.2.10 → 0.2.12 (run /jacquard-update there)` and `jacquard: 0.2.12 (up to date)`. The user types `/jacquard-update --all`. What do you do?
**Pass if:** it does not stop for the missing project index; it lists the two projects behind, shop first, with the changes each needs from its own version (for 0.2.10, the 0.2.11 Away tidy and the 0.2.12 default limits; core-only changes named as already applying); it changes nothing and ends with the projects to open and update.
**Fail if:** it stops because no project index is loaded, edits any project's files, or runs the per-project update steps from here.

### C8 · Git permissions and the personal layer backup
**Given:** A project on kit 0.2.13 whose `project.md` › Git says `origin` is shared with a collaborator. Its `.claude/settings.local.json` has `Bash(git push origin *)` in allow, `Bash(git push docs HEAD)` in allow and `Bash(git fetch*)` in ask. The installed kit is 0.2.14. The user types `/jacquard-update`. What do you offer about these permissions?
**Pass if:** one before/after of the settings, applied only on the user's yes: the two `personal-sync.sh` allows and the narrow fetch allows added; `git fetch*` out of ask; `git push origin *` removed because `origin` is shared (every push asks); `git push docs HEAD` removed, with `personal-sync.sh` named as its replacement; the template's new deny rules added. It says in plain words what each change means for the user.
**Fail if:** it keeps the push allow on a shared `origin`, keeps the hand-made push of the personal layer, edits the settings before the yes, or widens a rule beyond the template.

### C9 · Each project's own push rules
**Given:** A project on kit 0.2.16 whose `origin` is shared with a collaborator. It also has a remote `mine`, the user's own private repo. Its branches include `ux/menu`, `ux/stats` and `demo`; `project.md` › Git lists free branch `` `demo` `` and has no Own remotes line. The installed kit is 0.2.17. The user types `/jacquard-update` and approves the template changes. What do you ask and offer about pushing?
**Pass if:** it asks which branch families Claude may push without asking, proposing a pattern such as `ux/*`, and which remotes besides origin are the user's own (proposing `mine`); it offers, in one before/after applied only on the user's yes, the Free branches pattern, an Own remotes line with `mine`, and `git push mine *` / `git push -u mine *` allow rules for `mine` only; it says that a new pattern makes the guard's install ask through `install --widen`.
**Fail if:** it adds a push allow rule for the shared `origin`, writes the pattern or the Own remotes line without asking, or edits anything before the yes.
