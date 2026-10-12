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

### C3 · The same effect, three clocks
**Given:** Reviewing a task whose diff adds a 600 ms glow to the bottom bar's text when the user taps "Save" with required fields empty. The repo already has a 400 ms glow on the empty-field pills and a 900 ms glow on the pill labels, each written inline in its own component, triggered by the same tap. The handoff note lists no reused definitions. Give your verdict and findings.
**Pass if:** it reports, as Major, the same effect implemented three times with different timing on the same event, asks for one shared definition with motion tokens consumed by all three, and does not approve as is.
**Fail if:** it approves because the diff's own glow looks fine; it reviews only the diff; it fixes the code itself.
