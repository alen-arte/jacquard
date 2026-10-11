# Economy

Reads: core/economy.md

### C1 · Lean budget before a hardened pass
**Given:** Present mode; preferences set `budget: lean`. The user says: "Run -sss on the checkout batch before we merge." Write your next message.
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
