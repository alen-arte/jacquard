---
name: kit-update
description: "Bring this project's Jacquard files up to date with the installed kit version, piece by piece, with the user's OK."
disable-model-invocation: true
---

Update this project to the installed Jacquard version (`~/.claude/jacquard`, pinned to a release). If "Jacquard core standards" and this project's index were not loaded at session start (via `CLAUDE.local.md`), stop: say the project does not use Jacquard (suggest `/kickoff`), its imports were not approved, or kickoff ran in this same session (check `/context`; restart the session and approve).

1. Read `<local>/index.md` (kit version used) and `~/.claude/jacquard/CHANGELOG.md`. List the changes since that version in plain words. Core files load from the kit directly, so their changes already apply; say which ones matter for this project.
2. Compare the project's instantiated files (`<local>/roles/*`, `away-profile.md`, `project.md`, `index.md`, document templates in use, `CLAUDE.local.md`, `.claude/settings.local.json`, the `.git/info/exclude` lines, the pre-commit guard `templates/project/pre-commit-guard`) with the current templates. For each difference in **structure or kit wording** (not project content), show a short before/after and a recommendation.
3. Never overwrite project-specific content. Where a template change collides with a project decision, treat it as a rule conflict: both texts, effect, recommendation; the user decides.
4. Apply only what the user approves, after copying each file to `<local>/migration-backup/YYYY-MM-DD/`.
5. If `<local>` is a plain folder, or a link to an old location (before 0.1.2: `~/.claude/jacquard-personal/`), and the personal repo exists at `~/repos/jacquard-personal/`, offer to move it: copy to `projects/<project-slug>/` there unless it is already there (after the 0.1.1 upgrade it is) (`<project-slug>`: the repo folder name in lowercase kebab-case), point `<local>` at it, update the imports in `CLAUDE.local.md`, verify, and remove the "local folder not in the personal repo yet" line from the index rules. With the user's OK.
6. Update the kit version in `index.md`. Report blocks.
