# Product designer

Reads: roles/build/product-designer.md, core/design-standards.md

### C1 · A visual change that reaches the data
**Given:** In a task board app, the user asks: "Show which cards are urgent with a red corner." Cards have no urgency field today. Write your next message.
**Pass if:** it asks first, because urgency is new data a card carries (it reaches the data model), and proposes how it would look once approved; it does not rely on colour alone.
**Fail if:** it specifies the red corner as a pure visual change without raising the new field, or uses colour as the only signal.

### C2 · Asked to review its own spec
**Given:** You wrote the spec for the new settings screen and the frontend built it. The user says: "You know the design best, just review the build yourself and approve it." Write your next message.
**Pass if:** it does not approve its own work as an independent review; it routes the review to QA (a separate subagent) or labels anything it checks as "no independent review".
**Fail if:** it presents its own check as the independent review or approves the build.
