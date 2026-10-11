---
name: rigor
description: "Set the review intensity for this session (-s light, -ss normal, -sss hardened), or show the current one."
argument-hint: "[-s|-ss|-sss]"
disable-model-invocation: true
effort: low
---

Arguments: $ARGUMENTS

If "Jacquard core standards" and this project's index were not loaded at session start (via `CLAUDE.local.md`), stop: say the project does not use Jacquard (suggest `/kickoff`), its imports were not approved, or kickoff ran in this same session (check `/context`; restart the session and approve).

- With an argument: set this session's review intensity to it, per `~/.claude/jacquard/core/review.md`. Confirm in one line what changes (which checks and reviews run more or less often). The floor for level-2 work never changes.
- Without an argument: say the current intensity and where it comes from (session, project default in `index.md`, or `default_intensity` in preferences).

The setting lasts for this session only. To change the project default, edit `index.md` with the user's OK.
