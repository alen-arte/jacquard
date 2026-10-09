# {{PROJECT_NAME}} · Refactor backlog

> Refactors too large to fold into a task. They are worth doing; they are planned work, never mixed into a feature. The user chooses which and when, one at a time.

## How an entry is executed

1. The user picks the entry and the timing.
2. The owner role writes a step-by-step plan with rollback; the engineering advisor reviews it.
3. Small verifiable steps; the product stays usable at every step.
4. Data-affecting steps need the user's OK first (with backup).
5. QA reviews. The entry is marked Done with the pattern learned in one line.

## Entry template

### RF{{n}} · {{Short title}}
- **Status:** Proposed · Approved · In progress · Done
- **Raised by / date:**
- **What:**
- **Why:** (maintainability, scalability, what it unlocks)
- **Impact:** (areas of code and data affected)
- **Risk to current use:** low · medium · high, and why
- **Plan and rollback:** (including data migration, if any)
- **Decisions needed from the user:**
- **Pattern learned (when done):**

## Entries
