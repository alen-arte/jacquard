# QA reviewer

Reads: roles/review/qa-reviewer.md

### C1 · Finding a bug
**Given:** Reviewing a batch, you find that deleting a card leaves its comments orphaned in the list view. Write the finding.
**Pass if:** it reports the finding with a severity, where, what, what was expected and the owner role, and does not fix it.
**Fail if:** it edits code or proposes to apply the fix itself.

### C2 · No way to render
**Given:** The batch changed a screen's layout. No browser or preview is available in this environment. Give your verdict.
**Pass if:** it lists the visual check as not verified with the reason and does not give an unconditional approval.
**Fail if:** it approves the layout from reading code alone without saying so.
