---
name: {{PROJECT_SLUG}}-away-profile
description: "Project-specific additions to the universal Away rules. May only add limits, never loosen them. Read on /away, /back, /away-resume."
---

# Away profile · {{PROJECT_NAME}}

Universal rules: `~/.claude/jacquard/core/work-modes.md` and `away-run.md`. This file only adds.

## Where things go

- Away files: `{{LOCAL_FOLDER}}/away/` (brief, journal, report draft, reports)
- Brief source: {{ROADMAP_IDS_OR_EXTERNAL_PLANNING}}

## Checks

- Automatic checks after each task: see `project.md` › Commands ({{CHECKS_SUMMARY}})
- Visual check: `project.md` › `render_check` ({{RENDER_CHECK_SUMMARY, default "none: reported as no real visual check"}})
- Checks that need a person (logged as pending for the user): {{HUMAN_ONLY_CHECKS, default none}}

## Scope of autonomy here

- Where Away works (narrows `work-modes.md` section 3, never widens it): {{AREAS, default "the whole product"; e.g. "the user's design lane only"}}
- Also structural in this project (park): {{EXTRA_STRUCTURAL, default none}}

## Collaborators

- Areas owned by others and the boundary: see `project.md` › People and boundaries
- Notes for collaborators go to: {{NOTES_LOCATION, default "only in reports"}} (as in `project.md`) and to the Away report, section 6

## Extra hard limits

{{EXTRA_LIMITS, default none}} (e.g. shared planning files that are read-only, branches never to touch)

## Tools that confirm on their own

Allowed in settings but still ask before acting, so the gate's permission audit treats them as asking: {{SELF_CONFIRMING_TOOLS, default none known; e.g. "Supabase MCP `apply_migration` and destructive SQL (`execute_sql` with DROP, DELETE, TRUNCATE)"}}. Add one whenever a block meets a new one.

## Shared files Away may write

The exception in `work-modes.md` section 5, approved by the user: {{SHARED_WRITABLE, default none}}

## Reviews

- Advisors to run in the review block: {{ADVISORS_AND_TRIGGERS}}
- Design-manual pass source: {{docs/system-manual.md | EXTERNAL_PATH}}

## Report

- Publish as private artifact: {{inherit | false}} (a profile can only turn it off)
