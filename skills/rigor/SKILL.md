---
name: rigor
description: "Set the review intensity for this session (-s light, -ss normal, -sss hardened), or show the current one."
argument-hint: "[-s|-ss|-sss]"
disable-model-invocation: true
---

Arguments: $ARGUMENTS

- With an argument: set this session's review intensity to it, per `~/.claude/jacquard/core/review.md`. Confirm in one line what changes (which checks and reviews run more or less often). The floor for level-2 work never changes.
- Without an argument: say the current intensity and where it comes from (session, project default, or kit default).

The setting lasts for this session only. To change the project default, edit `project.md` or `index.md` with the user's OK.
