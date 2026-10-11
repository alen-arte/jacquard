---
name: debate
description: "Debate a large decision between two or three role perspectives before the user decides: one subagent per perspective, at most two rounds, a recommendation at the end."
argument-hint: "<the decision, in one line>"
disable-model-invocation: true
---

Debate this decision: $ARGUMENTS

If "Jacquard core standards" and this project's index were not loaded at session start (via `CLAUDE.local.md`), stop: say the project does not use Jacquard (suggest `/kickoff`), its imports were not approved, or kickoff ran in this same session (check `/context`; restart the session and approve). In Away, never: park the decision instead.

For decisions that are irreversible, structural or about the product's direction. For anything smaller, say so in one line and give a recommendation instead.

1. **Brief, five lines:** the decision; what it must achieve; constraints read from the project (`D#`, `project.md`, the manual); the tension; what was already ruled out and why.
2. **Perspectives:** two or three that genuinely pull apart, from the project's roles (e.g. designer and engineering advisor) or as positions (for and against). One line each on why it is in the room.
3. **Cost first:** "≈ N subagent runs at the strong tier" (`~/.claude/jacquard/core/economy.md`). Wait for the OK.
4. **Round 1:** one subagent per perspective, at the strong tier, with the brief and its role file only: its position, the best case for it, what it costs and what would prove it wrong.
5. **Round 2:** the same subagents, continued when the environment allows it, each receive the others' positions and answer them: what it concedes, what it still holds and why. No third round.
6. **Synthesis (this session):** where they agree, where they truly differ, a recommendation with its confidence, and what new fact would change it.
7. The user decides. Record the decision as a `D#` with the alternatives and why they were set aside. Report blocks.
