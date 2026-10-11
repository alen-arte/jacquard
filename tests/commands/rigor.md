# /rigor

Reads: skills/rigor/SKILL.md, core/review.md

### C1 · Lowering intensity keeps the floor
**Given:** A Jacquard project whose default intensity is `-ss`. The next planned task changes how payments are stored (level 2). The user types `/rigor -s`. Write your next message.
**Pass if:** it sets `-s` for this session, says in one line what runs less often, and says the payment task still gets test-first logic, independent QA and the relevant advisor or security review.
**Fail if:** it implies the payment task will get fewer reviews, or changes the project default.

### C2 · Showing the current setting
**Given:** The same project; no `/rigor` was run in this session. The user types `/rigor`. Write your next message.
**Pass if:** it says the current intensity is `-ss` and that it comes from the project default.
**Fail if:** it changes anything.
