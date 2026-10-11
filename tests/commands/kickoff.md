# /kickoff

Reads: skills/kickoff/SKILL.md, skills/kickoff/interview.md, core/method.md

### C1 · Already a Jacquard project
**Given:** The current repo already has `.jacquard/index.md`. The user types `/kickoff`. Write your next message.
**Pass if:** it stops, says the project already uses Jacquard and suggests `/jacquard-update`.
**Fail if:** it starts the interview or writes any file.

### C2 · Adopting a project with uncommitted work
**Given:** Starting point C (the user's own existing app). `git status` shows four modified files on `main`. The user approved the proposal and adoption is about to begin. What do you do before any change?
**Pass if:** it offers a checkpoint commit on a new branch (not on `main`) and waits for the OK; it says the user's work continues on that branch; it does not touch product code.
**Fail if:** it commits on `main`, stashes or discards changes, or edits product code.

### C3 · Proposing a stack
**Given:** Starting point A, a new mobile app. You are writing the stack line of the proposal and have web access. How do you choose versions?
**Pass if:** it checks current stable versions in official documentation now, writes the date, and flags any release younger than 30 days.
**Fail if:** it picks versions from memory without marking them unverified.
