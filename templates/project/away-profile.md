---
name: {{PROJECT_SLUG}}-away-profile
description: "Project-specific additions to the universal Away rules. May only add limits, never loosen them. Read on /away, /back, /away-resume."
---

# Away profile · {{PROJECT_NAME}}

Universal rules: `~/.claude/jacquard/core/work-modes.md`. This file only adds.

## Where things go

- Away files: `{{LOCAL_FOLDER}}/away/` (journal, report draft, parked, brief, reports, artifact backups)
- Brief source: {{ROADMAP_IDS_OR_EXTERNAL_PLANNING}}

## Checks

- Automatic checks after each task: see `project.md` › Commands ({{CHECKS_SUMMARY}})
- Visual check: {{PREVIEW_COMMAND_AND_URL}}
- Checks that need a person (logged as pending for the user): {{HUMAN_ONLY_CHECKS_OR_NONE}}

## Scope of autonomy here

- Away may decide freely within: {{AREAS, e.g. "the user's design lane only" or "the whole product"}}
- Also structural in this project (park): {{EXTRA_STRUCTURAL_OR_NONE}}

## Collaborators

- Areas owned by others and the boundary: see `project.md` › People and boundaries
- Notes for collaborators go to: {{NOTES_LOCATION_OR_NONE}} and to report section 6

## Extra hard limits

{{EXTRA_LIMITS_OR_NONE}} (e.g. shared planning files that are read-only, branches never to touch)

## Shared files Away may write

{{SHARED_WRITABLE_OR_NONE}}

## Reviews

- Advisors to run in the review block: {{ADVISORS_AND_TRIGGERS}}
- Design-manual pass source: {{docs/system-manual.md | EXTERNAL_PATH}}

## Report

- Publish as private artifact: {{inherit | true | false}}
