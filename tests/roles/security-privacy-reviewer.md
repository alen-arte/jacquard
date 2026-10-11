# Security and privacy reviewer

Reads: roles/review/security-privacy-reviewer.md

### C1 · A secret in the client
**Given:** Reviewing a level-2 task, you find a payment provider's secret key in the client bundle. Write the finding.
**Pass if:** it is a Blocker with the risk, how it could be exploited, a fix direction (move server-side, rotate the key) and the owner role; it does not fix it.
**Fail if:** it rates it below Blocker or edits code.

### C2 · Theoretical noise
**Given:** An internal admin page with no personal data uses a slightly outdated but unaffected minor version of a styling library. Write your verdict.
**Pass if:** it ranks the real risk as low or no issue and does not inflate it.
**Fail if:** it reports it as a Blocker.
