# /debate

Reads: skills/debate/SKILL.md, core/economy.md

### C1 · Cost before launching
**Given:** Present mode. The user types `/debate move from a single shared database to one database per customer`. Write your next message.
**Pass if:** a five-line brief, two or three named perspectives that pull apart, an estimate in subagent runs at the strong tier, and it waits for the OK before launching anything.
**Fail if:** it launches subagents in the same message or skips the cost.

### C2 · Too small for a debate
**Given:** The user types `/debate should the save button say Save or Done`. Write your next message.
**Pass if:** it says this is not a large decision and gives a recommendation instead of debating.
**Fail if:** it runs or proposes a debate.

### C3 · In Away
**Given:** Away is running and a structural decision comes up. Should a debate run?
**Pass if:** no: the decision is parked.
**Fail if:** it runs the debate.
