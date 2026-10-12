---
name: kickoff
description: "Start a new project with Jacquard, or adopt an existing one: short interview, role and stack proposal, then the project's local files."
argument-hint: "[optional: one line about the project]"
disable-model-invocation: true
---

Run the Jacquard kickoff for the project in the current directory. Context from the user: $ARGUMENTS

Read first: `~/.claude/jacquard/core/standards.md`, `~/.claude/jacquard/core/method.md`, the interview in `${CLAUDE_SKILL_DIR}/interview.md`, and the personal preferences `~/repos/jacquard-personal/preferences.md` if it exists (else `~/.claude/jacquard/core/preferences.default.md`): they set the reply language, the technical depth and `local_folder`. Names used below: `<local>` = `local_folder` (default `.jacquard`); `<project-slug>` = the repo folder name in lowercase kebab-case (templates write `{{PROJECT_SLUG}}`). The interview's default intensity is `default_intensity` from preferences.

## 0. Check

- If `<local>/index.md` already exists, this project already uses Jacquard: stop and suggest `/jacquard-update`.
- If `CLAUDE.local.md`, `.claude/settings.local.json` or `<local>` is already tracked by git (`git ls-files --error-unmatch <path>`), stop: excluding it would not work and personal files would reach the repo. Explain and ask how to proceed.
- `git status`: if the tree has uncommitted changes, say so; kickoff only writes files excluded from git, but the user should know.

## 1. Starting point

Ask block 0 of the interview (A new, B new with material, C existing own project, D someone else's project with a role).

## 2. Read before asking (B, C, D)

Read-only scan, nothing is changed:
- Material the user points to (B), or the repo (C, D): structure, stack and versions, `CLAUDE.md` and `.claude/`, docs, roadmap or planning folders, tests and CI, git remotes and branches, what is tracked.
- Existing rules from other systems: Claude Code memories for this project (`~/.claude/projects/<project-path-slug>/memory/`), role or rule files, commands. List them; do not change them yet.
- Summarise in a few lines what exists. Then ask only what could not be read.

## 3. Interview

The blocks of `interview.md` that apply, by its rules. Keep the answers in a running summary in this conversation; step 5 writes them to `project.md`. Without the interactive question tool, use numbered options with the default marked.

## 4. Proposal (one screen, one OK)

- Project name and slug; starting point and phase
- Roles to create, each with one line of why; domain fluency per role; domain advisors with their triggers; roles not created and why
- Stack (A, B), proposed once, here: the latest stable versions that work together, **checked in official documentation now**, never from memory, with the date; flag any release younger than 30 days; hosting and environments. Without web access, mark versions "unverified".
- Visual check (`render_check`), when there is an interface: what the repo already has, or a proposal (a browser tool is a dependency, so it is part of this OK); otherwise "none" (`~/.claude/jacquard/core/visual-qa.md`)
- What is irreversible here: derived from the stack and the domain risks; the user confirms
- Boundaries with collaborators, push policy (A, B with no remote and no collaborators: stated, not asked), default intensity
- Documents created now and documents that come later (`core/method.md`)
- Away profile: where Away works (default: the whole product), checks that need a person, advisors for the review block
- For C and D: the **adoption plan** (section 6)

Wait for the OK. Apply changes the user asks for and show only what changed.

## 5. Generate

1. Create `<local>/`. If the personal repo exists (`~/repos/jacquard-personal/`), create `projects/<project-slug>/` there and make `<local>` a link to it. Otherwise a plain folder: say so, and write "local folder not in the personal repo yet" in the index rules (`/jacquard-update` moves it later).
2. From `~/.claude/jacquard/templates/project/`: `index.md`, `project.md`, `away-profile.md` filled from the summary; `CLAUDE.local.md` at the repo root (if one exists, add the imports and keep its content); append `git-exclude.txt` lines to `.git/info/exclude` (no duplicates); `claude-settings.local.template.json` into `.claude/settings.local.json`, merged with any existing file, never overwritten.
   - A placeholder the summary does not cover takes the default written inside it, or "none".
   - In `.claude/settings.local.json`, `{{LOCAL_FOLDER}}` becomes `<local>` wherever it appears (rules and the Away guard hooks); replace each other `{{…}}` entry with real rules or delete it. Never leave a placeholder there.
3. If `git rev-parse --git-path hooks` is `.git/hooks` and it has no `pre-commit`, copy `~/.claude/jacquard/templates/project/pre-commit-guard` there as `pre-commit` (executable), filling `{{MAIN}}` with the main branch from `project.md` and `{{LOCAL_FOLDER_REGEX}}` with `<local>` with its dots escaped (`\.jacquard`). It refuses commits on the main branch (except the first commit of a new repo) and commits that include the local files. Otherwise say the repo has its own hooks and rely on the rule.
4. Roles: from `~/.claude/jacquard/roles/`, filled with the placeholders described in `roles/README.md`, into `<local>/roles/`.
5. Documents to create now, from `~/.claude/jacquard/templates/docs/`, into `<local>/docs/`, in `docs_language`. Only those.
6. Write the kit version (from `~/.claude/jacquard/CHANGELOG.md`) in `index.md`.

## 6. Adoption (C, D)

Adoption touches **only the working-system files** (roles, rules, memories, commands, guiding documents the user chooses). Product code is never changed by kickoff.

**Return point first, before any change:**
- Tracked files: if the tree has uncommitted changes, offer a checkpoint commit on a new branch (`checkpoint/before-jacquard`, never on the main branch) and wait for the OK (C only); say that the user's work continues on that branch. In someone else's repository (D), never create commits for this.
- Untracked files that will change (role or rule folders, the project's memories, personal commands): copy them into one dated archive in `~/jacquard-backups/` and show the exact command to restore it.

- Map every existing rule, role, memory, command and document to its place in Jacquard: kept as is, moved, merged, replaced by the core, or retired.
- Conflicts between an existing rule and Jacquard: never resolved silently. Show both texts, the practical effect and a recommendation; the user decides each.
- Nothing is deleted: copies of everything replaced go to `<local>/migration-backup/YYYY-MM-DD/` first. Files outside the project (old memories, old commands) are only touched with the user's explicit OK per file.
- Converting existing guiding documents to the Jacquard format (IDs, data lines, archive of finished items), or extracting the markdown source of an artifact-only document, is **optional**: ask per document. If converted, keep the original as backup.
- D: the other person's planning and rules stay read-only; their areas become boundaries in `project.md`; nothing of Jacquard is referenced from tracked files.
- **Initial audit** (`core/method.md`): offer it, with its own OK, once the files exist: a full audit per `core/review.md`. Its findings become roadmap items or `RF#`.

## 7. Verify

- `git status --porcelain` shows no new or modified tracked file; `git check-ignore -v` confirms `<local>`, `CLAUDE.local.md` and `.claude/settings.local.json` are excluded.
- `.claude/settings.local.json` is valid JSON, and neither it nor the pre-commit guard has a `{{` left.
- The files that load at session start are only `CLAUDE.local.md` and its imports (core standards, personal preferences, project index): list them with their line counts.
- Tell the user: the new `CLAUDE.local.md` loads from the next session; approve the external imports dialog then, and check with `/context`. Without that approval nothing from Jacquard loads, and the other commands (`/away`, `/rigor`…) work only from that next session.
- The project's checks still pass.

## 8. Report

Report blocks from the core standards, with **What comes next** naming the first roadmap items or the next phase step. If the import check above is still pending, it goes in **I need your OK**.
