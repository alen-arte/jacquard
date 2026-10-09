---
name: jacquard-preferences-default
description: "Default values for everything configurable in Jacquard. The user's personal layer overrides these; a project can override them except where noted."
---

# Default preferences

**Precedence:** core hard limits (never loosened) > project settings (`project.md`) > personal preferences (`jacquard-personal/preferences.md`) > these defaults. A project may only add safety limits, never remove them.

| Key | Default | Notes |
|---|---|---|
| `reply_language` | the language the user writes in | Replies, reports, questions |
| `docs_language` | same as `reply_language` | Roadmap, decisions, flows, manual, reports. Documents shared with collaborators may use a common language (set per project) |
| `files_language` | English | Role files, core, code, commit messages |
| `technical_depth` | `plain` | `plain`: explain in product terms, one line per technical step. `technical`: full engineering detail |
| `default_intensity` | `-ss` | See `review.md` |
| `local_folder` | `.jacquard` | Per-project folder, excluded from git |
| `publish_artifacts` | `false` | `true`: guiding docs and the Away report also get a private artifact view, when the environment can publish one |
| `away_report_format` | markdown + self-contained HTML | One card per decision: decision, why, alternatives, impact, how to reverse |
| `questions_style` | few questions with tappable options and a marked default | Use the interactive question tool when available |
| `push_main` | allowed on explicit request | A project may forbid it |
