# Status marks

Reads: core/docs-system.md

### C1 · Mark for an approved proposal
**Given:** The user approves proposal P7; it becomes R59, not started. What mark does P7's row get?
**Pass if:** 🔵 with "Approved <date> → R59"; ✅ is reserved for done.
**Fail if:** ✅, or ⬜.

### C2 · The next roadmap edit
**Given:** The proposals table has P3 (🔵 Approved → R65), P8 (❌ Rejected: the user uses both ways) and P9 (⬜). You edit the roadmap for an unrelated reason. What happens to the three rows?
**Pass if:** P3's row is removed (its R65 keeps "from P3"; nothing archived); P8 moves to `roadmap-done.md` under "Rejected" with date and reason; P9 stays.
**Fail if:** P3 or P8 stay in the table, P3 is archived, or P8 is deleted without being archived.

### C3 · Done work behind a proposal
**Given:** R12, born from P1, is integrated into `main` and marked ✅. Does P1's row change?
**Pass if:** P1 is unchanged (🔵) or already gone; ✅ never goes on a proposal.
**Fail if:** it marks P1 ✅.

### C4 · Status after the user's OK
**Given:** Away finished R14 on `away/r14` and marked it. The user reads the report, tests it in dev and says "R14 is good". The release to production has not happened. What mark does R14 have before and after the user's words, and what else do you edit?
**Pass if:** 👀 before, 🚀 after (not ✅, because nothing is in production); the status index is regenerated with `roadmap-index.sh --write` and not typed by hand.
**Fail if:** ✅ after the OK, 🟡, or the index edited manually.

### C5 · Rejecting a built item
**Given:** R20 is 👀. The user looks at it and says "no, drop this, it makes the board noisier". What do you do?
**Pass if:** ❌ with `rejected: <date>` and `why:` in the data line (the user's reason), then the index is regenerated; at the next roadmap edit R20 moves to `roadmap-done.md` under "Rejected" with date, reason and what it would take to reopen; asks or notes whether a `D#` changes.
**Fail if:** R20 is deleted, goes back to ⬜ without a reason, or the reason is not kept anywhere.

### C6 · Waiting for a pick
**Given:** For R30 you found two ways to do it and the user has to choose. What mark and data does R30 get?
**Pass if:** ⚖️ with `options:` in the data line; not ⬜, and no `⏸` flag.
**Fail if:** ⬜ with a `⏸` flag, or building before the answer.
