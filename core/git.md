---
name: jacquard-git
description: "Branches, commits, integration, push and syncing with collaborators. Read when touching git."
---

# Git

The user may not be an engineer: choose branches and messages yourself and explain each git step in one plain line.

## Branches

- **`main` always works.** Nobody commits on it directly, neither the user nor Claude: work reaches `main` only by integrating a branch.
- One short-lived branch per roadmap item or batch, named after the ID: `r12-tag-filter`. Short means days, not weeks; long branches collect conflicts.
- Away works on `away/<current-branch>` (add `-2` if it exists). Never on `main`.

## Commits

- One commit per completed task or logical change, message starting with the ID: `R12: add tag filter to board header`.
- Never rewrite history: no amend of earlier commits, no rebase of shared work, no `reset --hard`. Undo with `git revert`.
- A known-good commit before any risky step.

## Integration

A branch is integrated when its checks are green, its reviews per `review.md` are done, and the user says OK. Prefer `git merge --ff-only`; if it refuses because the target moved, stop and explain the options. Delete the branch afterwards with `git branch -d` (safe delete).

## Push

- Only in Present, only when the user asks in writing for that specific push. One OK does not cover the next.
- Before pushing, say in one line which branch goes to which remote branch and how many commits.
- Never force-push. Never push in Away.
- Pushing an integrated `main` is allowed unless the project forbids it in `project.md`.

## Syncing with collaborators (Present only)

At the start of a Present session in which code will change, fetch and say in one line how far the current branch is from the shared main branch and which files both sides touched. Update only with the user's OK and show what conflicted and how it was resolved. Away never fetches, pulls, rebases or merges.

## Technical backstop

The project's `.claude/settings.local.json` (excluded from git) puts pushes, merges, rebases, pulls, resets, restores, stashes, remote changes, branch deletion and `gh` behind a confirmation, and denies the common forms of force-push, skipping hooks, history rewriting, git configuration changes, running git in another folder (`git -C`) and adding the local files (`<local>`, `CLAUDE.local.md`, local settings) to git. Where the repo has no hooks of its own, kickoff adds a local pre-commit guard that refuses commits on the main branch and commits that include the local files. Instructions are the rule; permissions are the safety net: a variant of a command can escape a pattern.
