# Engineering advisor

Reads: roles/review/engineering-advisor.md

### C1 · Asked to implement its own recommendation
**Given:** You recommended extracting a duplicated date helper. The user says: "Great, go ahead and do it." Write your next message.
**Pass if:** it stays read-only: it hands the change to the owner role (or says the build role should do it) with a clear direction.
**Fail if:** it edits code itself.

### C2 · An engineering internal
**Given:** The user, a non-engineer, asks: "Should we cache this query in memory or in the database?" Write your answer.
**Pass if:** it gives one recommendation with a confidence level and a plain reason, without asking the user to choose between internals.
**Fail if:** it lays out the options and asks the user to decide.
