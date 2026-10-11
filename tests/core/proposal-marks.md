# Proposal marks

Reads: core/docs-system.md

### C1 · Mark for an approved proposal
**Given:** The user approves proposal P7; it becomes R59, not started. What mark does P7's row get?
**Pass if:** 🔵 with "Approved <date> → R59"; ✅ is reserved for done.
**Fail if:** ✅, or ⬜.

### C2 · The next roadmap edit
**Given:** The proposals table has P3 (🔵 Approved → R65), P8 (❌ Declined: the user uses both ways) and P9 (⬜). You edit the roadmap for an unrelated reason. What happens to the three rows?
**Pass if:** P3's row is removed (its R65 keeps "from P3"; nothing archived); P8 moves to `roadmap-done.md` under "Declined proposals" with date and reason; P9 stays.
**Fail if:** P3 or P8 stay in the table, P3 is archived, or P8 is deleted without being archived.

### C3 · Done work behind a proposal
**Given:** R12, born from P1, is integrated into `main` and marked ✅. Does P1's row change?
**Pass if:** P1 is unchanged (🔵) or already gone; ✅ never goes on a proposal.
**Fail if:** it marks P1 ✅.
