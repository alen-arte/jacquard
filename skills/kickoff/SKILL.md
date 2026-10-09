---
name: kickoff
description: "Start a new project with Jacquard, or adopt an existing one: short interview, role and stack proposal, then the project's local files."
argument-hint: "[optional: one line about the project]"
disable-model-invocation: true
---

Run the Jacquard kickoff for the project in the current directory. Context from the user: $ARGUMENTS

Read first: `~/.claude/jacquard/core/standards.md`, `~/.claude/jacquard/core/method.md`, and the interview in `${CLAUDE_SKILL_DIR}/interview.md`. The local folder name comes from preferences (`local_folder`, default `.jacquard`); below it is `<local>`.

## 0. Check

- If `<local>/index.md` already exists, this project already uses Jacquard: stop and suggest `/kit-update`.
- `git status`: if the tree has uncommitted changes, say so; kickoff only writes files excluded from git, but the user should know.

## 1. Starting point

Ask block 0 of the interview (A new, B new with material, C existing own project, D someone else's project with a role).

## 2. Read before asking (B, C, D)

Read-only scan, nothing is changed:
- Material the user points to (B), or the repo (C, D): structure, stack and versions, `CLAUDE.md` and `.claude/`, docs, roadmap or planning folders, tests and CI, git remotes and branches, what is tracked.
- Existing rules from other systems: Claude Code memories for this project (`~/.claude/projects/<project-path-slug>/memory/`), role or rule files, commands. List them; do not change them yet.
- Summarise in a few lines what exists. Then ask only what could not be read.

## 3. Interview

Blocks 1–6 of `interview.md`, skipping what does not apply or was already read. At most three questions per screen, tappable options with a marked default (use the interactive question tool when available), "Block n of N" in each screen. Stack questions (A, B): propose the stack with reasons and alternatives, **checking current stable versions in official documentation now**, never from memory.

## 4. Proposal (one screen, one OK)

- Starting point and phase
- Roles to create, each with one line of why; domain fluency per role; domain advisors with their triggers; roles not created and why
- Stack (A, B) with versions and the date checked
- Boundaries with collaborators, push policy, default intensity
- Documents created now and documents that come later (`core/method.md`)
- Away profile highlights
- For C and D: the **adoption plan** (section 6)

Wait for the OK. Apply changes the user asks for and show only what changed.

## 5. Generate

1. Create `<local>/`. If the personal repo exists (`~/.claude/jacquard-personal/`), create `projects/<project-slug>/` there and make `<local>` a link to it; otherwise a plain folder, and say so.
2. From `~/.claude/jacquard/templates/project/`: `index.md`, `project.md`, `away-profile.md` filled in; `CLAUDE.local.md` at the repo root (if one exists, add the imports and keep its content); append `git-exclude.txt` lines to `.git/info/exclude` (no duplicates); `.claude/settings.local.json` merged with any existing file, never overwritten.
3. Roles: from `~/.claude/jacquard/roles/`, filled with the placeholders described in `roles/README.md`, into `<local>/roles/`.
4. Documents to create now, from `~/.claude/jacquard/templates/docs/`, into `<local>/docs/`. Only those.
5. Write the kit version (from `~/.claude/jacquard/CHANGELOG.md`) in `index.md`.

## 6. Adoption (C, D)

Adoption touches **only the working-system files** (roles, rules, memories, commands, guiding documents the user chooses). Product code is never changed by kickoff.

**Return point first, before any change:**
- Tracked files: if the tree has uncommitted changes, offer a checkpoint commit on the current branch and wait for the OK (C only). In someone else's repository (D), never create commits for this.
- Untracked files that will change (role or rule folders, the project's memories, personal commands): copy them into one dated archive in `~/jacquard-backups/` and show the exact command to restore it.

- Map every existing rule, role, memory, command and document to its place in Jacquard: kept as is, moved, merged, replaced by the core, or retired.
- Conflicts between an existing rule and Jacquard: never resolved silently. Show both texts, the practical effect and a recommendation; the user decides each.
- Nothing is deleted: copies of everything replaced go to `<local>/migration-backup/YYYY-MM-DD/` first. Files outside the project (old memories, old commands) are only touched with the user's explicit OK per file.
- Converting existing guiding documents to the Jacquard format (IDs, data lines, archive of finished items), or extracting the markdown source of an artifact-only document, is **optional**: ask per document. If converted, keep the original as backup.
- D: the other person's planning and rules stay read-only; their areas become boundaries in `project.md`; nothing of Jacquard is referenced from tracked files.

## 7. Verify

- `git status` shows nothing new tracked; `.git/info/exclude` has the lines.
- The files that load at session start are only `CLAUDE.local.md` and its imports (core standards, personal preferences, project index): list them with their line counts.
- Tell the user: the new `CLAUDE.local.md` loads from the next session; approve the external imports dialog then, and check with `/context`. Without that approval nothing from Jacquard loads.
- The project's checks still pass.
- `scripts/privacy-check.sh` is not needed here (the project is not the public kit).

## 8. Report

Report blocks from the core standards, with **What comes next** naming the first roadmap items or the next phase step. If the import check above is still pending, it goes in **I need your OK**.
