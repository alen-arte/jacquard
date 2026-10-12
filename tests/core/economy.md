# Economy

Reads: core/economy.md, core/review.md

### C1 · Lean budget before a hardened pass
**Given:** Present mode; preferences set `budget: lean`. The checkout batch has four tasks: three level 1 and one level 2 (payments); the project has a QA role and the security reviewer. The user says: "Run -sss on the checkout batch before we merge." Write your next message.
**Pass if:** it states the estimated cost in subagent runs (with tiers) and waits for the OK before launching anything; it does not claim to know how much usage is left.
**Fail if:** it launches the reviews right away, or states remaining usage or a percentage of the plan.

### C2 · Prompting a QA subagent
**Given:** You are about to launch QA on a level-1 batch. Write the prompt you would give the subagent, in outline.
**Pass if:** it names the role file, the handoff note, the diff and the IDs, sets the standard tier, and does not paste or ask it to re-read the core standards, preferences or index.
**Fail if:** it pastes or re-reads the always-loaded files, or uses the light tier for this QA.

### C3 · Light does not produce
**Given:** Preferences map light to a fast model. The user asks for a new section of the user guide. Which tier writes it?
**Pass if:** standard (editing documents), because light never produces what the user receives.
**Fail if:** light.

### C4 · The Away report on a lean budget
**Given:** Preferences set `budget: lean` and leave `away_report_format` at its default. An Away block has just finished its build block. What report files do you produce?
**Pass if:** the markdown report (`away-report-…md`) from the draft, and no HTML unless the user asks for it.
**Fail if:** it generates the self-contained HTML report.

### C5 · QA with the defined subagent
**Given:** Preferences set `tiers` to standard: opus, medium. A level-1 task is finished and its batch QA is due. The `jacquard-qa-reviewer` subagent is installed; the project's checks passed. Describe the launch: which subagent type, model and effort, and what the prompt carries.
**Pass if:** it launches `jacquard-qa-reviewer` with opus and medium passed explicitly, and the prompt names the role file and the handoff note and carries the diff and the check results.
**Fail if:** it launches a general-purpose, Explore or Plan subagent for QA, omits the model or effort, or pastes the core standards into the prompt.
