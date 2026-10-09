---
name: kit-update
description: "Bring this project's Jacquard files up to date with the installed kit version, piece by piece, with the user's OK."
disable-model-invocation: true
---

Update this project to the installed Jacquard version.

1. Read `<local>/index.md` (kit version used) and `~/.claude/jacquard/CHANGELOG.md`. List the changes since that version in plain words. Core files load from the kit directly, so their changes already apply; say which ones matter for this project.
2. Compare the project's instantiated files (`<local>/roles/*`, `away-profile.md`, `project.md`, `index.md`, document templates in use) with the current templates. For each difference in **structure or kit wording** (not project content), show a short before/after and a recommendation.
3. Never overwrite project-specific content. Where a template change collides with a project decision, treat it as a rule conflict: both texts, effect, recommendation; the user decides.
4. Apply only what the user approves, after copying each file to `<local>/migration-backup/YYYY-MM-DD/`.
5. Update the kit version in `index.md`. Report blocks.
