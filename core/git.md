---
name: jacquard-git
description: "Branches, commits, integration, push, syncing with collaborators and with cloud sessions. Read when touching git."
---

# Git

The user may not be an engineer: choose branches and messages yourself and explain each git step in one plain line.

## Branches

- **`main` always works.** Nobody commits on it directly, neither the user nor Claude: work reaches `main` only by integrating a branch.
- One short-lived branch per roadmap item or batch, named after the ID: `r12-tag-filter`. Short means days, not weeks; long branches collect conflicts.
- Away always works on its own branch, never on `main` (or on the project's default branch). The gate says which, by where the session is:
  - on `main`: a new branch named after the brief, `away/<first-ID-or-theme>` (e.g. `away/r44-r50-board-fixes`); add `-2` if the name exists;
  - already on an `away/…` branch (an earlier block not integrated yet): Away continues on it;
  - on any other work branch: `away/<that-branch>`;
  - the brief changes nothing tracked in the repo (only `<local>` documents, or analysis): no branch.

  The base branch (where it integrates) goes in the journal's `START` line; on an existing `away/…` branch, it is the one in that block's `START` line.

## Commits

- One commit per completed task or logical change, message starting with the ID: `R12: add tag filter to board header`.
- Never rewrite history: no amend of earlier commits, no rebase of shared work, no `reset --hard`. Undo with `git revert`.
- A known-good commit before any risky step.

## Integration

A branch is integrated when its checks are green, its reviews per `review.md` are done, and the user says OK. Prefer `git merge --ff-only`; if it refuses because the target moved, stop and explain the options (a merge commit, or bringing the branch up to date first). Finishing a merge is allowed by the guard; a plain commit on `main` is not. Delete the branch afterwards with `git branch -d` (safe delete).

Integrating into `main` is also what closes roadmap items: as the last commit on the branch, before the merge, mark its items ✅ with the done date (`core/docs-system.md`, Status marks) and regenerate the status index. If `main` is not production, mark them 🚀 instead and ✅ only after the release. If the merge does not go through, revert that commit.

## Push

- Only in Present, only when the user asks in writing for that specific push. One OK does not cover the next.
- Before pushing, say in one line which branch goes to which remote branch and how many commits.
- Never force-push. Never push in Away.
- Pushing an integrated `main` is allowed unless the project forbids it in `project.md`.
- **The one standing OK:** with `cloud_sync: on` (preferences), the pushes of Cloud sync below, and making the kit branch the repo's default branch, need no new OK each time. They go to the cloud remote only, never to `main` and never to a remote shared with other people.

## Syncing with collaborators (Present only)

At the start of a Present session in which code will change, fetch and say in one line how far the current branch is from the shared main branch and which files both sides touched. Update only with the user's OK and show what conflicted and how it was resolved. Away never fetches, pulls, rebases or merges.

## Cloud sync (only with `cloud_sync: on`)

So the user can also work from a Claude Code cloud session (phone, web) with the same kit. `~/.claude/jacquard/scripts/cloud.sh` keeps one kit branch per work branch, `cloud/<branch>` (without `away/`): the work branch's files plus the kit (framework, preferences, and the project documents the personal layer versions; what it git-ignores never travels). It runs on the computer, on the work branch; its header has the details.

- **The cloud remote** is the project's own repo, `origin`, unless `origin` is shared with other people: then a separate private remote, named in `project.md` › Git and set by the user in the repo's local git config (`git config jacquard.cloudRemote <name>`; Claude's permissions deny `git config`). `prepare` checks every time that its one push URL is a private GitHub repo with no other collaborators, and pushes nothing otherwise. A repo that deploys or runs workflows (they could start on the kit branch) needs the user's yes to what `prepare` found, which they give themselves with the `git config jacquard.cloudDeployOk "…"` it prints (it asks again when something new appears), or a separate private remote instead.
- **Down, at the start of a Present session:** with the fetch above, run `~/.claude/jacquard/scripts/cloud.sh status`, spelled exactly so (the allow rule matches only that). If a cloud branch has commits not landed, say so in one line and run `cloud.sh land` on the work branch it names before touching code; then commit the documents it copied back into the personal layer. A `<file>.cloud` is a document changed in both places: merge it into `<file>` and delete it before that commit. If `land` names files that run or give instructions (`package.json`, hooks, workflows, `CLAUDE.md`, `.claude/`), show the user what changed in them before running any check or following them. If `status` fails (offline, no branch checked out), say so in one line and continue.
- **Up, when work closes** (a Present session that committed work or changed project documents, or an Away block once it is closed, so in Present): say in one line which branches go where and how many commits, run `cloud.sh prepare` (it checks the remote first), then push the work branch to the cloud remote. Nothing new: say so. Away never runs `cloud.sh` (it refuses while the guard is on) and never pushes.
- **In a cloud session:** commit on that same `cloud/<branch>` and push it when the work is closed. An Away block closed there writes the same report as on the computer, every section included.
- **The kit branch** follows one work branch (`away/x` and `x` share `cloud/x`): another takes it over only once it holds that work. If the followed branch was deleted without being integrated, ask the user whether its work is wanted: on yes, bring the branch back with the `git branch` the refusal prints and integrate it first; on no, run the same command with `--take-over`. It never goes to a remote shared with others, is never merged into `main`, never opened as a PR, and never checked out on the computer (it tracks `CLAUDE.local.md`, which would replace the user's). It becomes the repo's default branch, so new cloud sessions start on it; Dependabot and Renovate need their base set to `main` (`prepare` warns). Before a repo is shared or made public, delete its `cloud/` branches there; `status` warns if it stopped being private.
- **If `land` stops on a conflict:** resolve it and `git am --continue`; to keep this computer's version instead, follow the commands the stop prints (an empty commit carrying the cloud commit's message, then `git am --skip`). Then `land` again: what already landed is skipped. `prepare` never merges, so it cannot conflict. Never edit the script's record by hand.

## Technical backstop

The project's `.claude/settings.local.json` (excluded from git) puts pushes, merges, rebases, pulls, resets, restores, stashes, remote changes, branch deletion and `gh` behind a confirmation, and denies the common forms of force-push, skipping hooks, history rewriting, git configuration changes, running git in another folder (`git -C`) and adding the local files (`<local>`, `CLAUDE.local.md`, local settings) to git. Where the repo has no hooks of its own, kickoff adds a local pre-commit guard that refuses commits on the main branch and commits that include the local files. Instructions are the rule; permissions are the safety net: a variant of a command can escape a pattern.
