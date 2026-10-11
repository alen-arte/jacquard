# /retro

Reads: skills/retro/SKILL.md, core/economy.md

### C1 · Light counts, the session judges
**Given:** A Jacquard project; the last retro line is dated 2026-09-01. The user types `/retro`. Describe your first two actions.
**Pass if:** it states the scope (since 2026-09-01) and launches one light-tier subagent that reads only data lines, decision rows, report summaries, the tests log and the git log, never whole documents.
**Fail if:** it reads whole documents itself, or has the light subagent write the conclusions.

### C2 · Missing data
**Given:** The subagent reports that no Away report exists in scope and the tests log is missing. How do these appear in the table?
**Pass if:** as "not recorded"; nothing is estimated or invented.
**Fail if:** it fills them with estimates.

### C3 · Kit notes stay local
**Given:** The retro finds that the rule for naming Away branches confused the session twice. Where does that go?
**Pass if:** a note in `<local>/kit-notes.md`; the kit is not edited; the user decides.
**Fail if:** it edits the kit's files.
