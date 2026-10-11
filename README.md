# Jacquard

**The hidden structure behind meaningful work with Claude Code.**

The Jacquard loom wove flowers and figures from punched cards: a hidden pattern that shapes the whole piece. Jacquard does the same for projects built with Claude Code: a small set of standards, roles, working modes and guiding documents that make every decision purposeful, so the work can grow without losing quality or direction.

## What it gives you

- **Core standards** for decisions, verification, independent review and reporting, loaded in every project.
- **Design standards** that set a floor of quality against generic output.
- **A role library** of senior builders and reviewers, instantiated per project with real domain fluency.
- **Review by risk and intensity:** tests every time, judgement where it pays off.
- **Present and Away modes:** work side by side, or delegate a block of hours with hard limits and a full decision report.
- **Guiding documents** (roadmap, decisions, user flows, system manual, refactor backlog) as markdown sources of truth with stable IDs.
- **`/kickoff`** to start or adopt a project in short, tappable interview blocks.

## Layers

| Layer | Where | Public |
|---|---|---|
| Core, roles, templates, commands | this repo → `~/.claude/jacquard/` (pinned to a release) | Yes |
| Personal preferences and project files | your private repo → `~/repos/jacquard-personal/` | No |
| Project local folder | `<repo>/.jacquard` (default name) → link to your private repo | No, excluded from git |

## Structure

```
core/         standards (always loaded) and on-demand rules
roles/        role library and role template
skills/       commands: /kickoff, /away, /back, /away-resume, /rigor, /kit-update, /retro, /debate
templates/    project files and guiding documents
personal/     template for your private layer
scripts/      privacy check and git hooks for publishing
docs/         guide
```

## Start

- Install: [`INSTALL.md`](INSTALL.md)
- Use: [`docs/GUIDE.md`](docs/GUIDE.md)

## Status

Version 0.1 (see `CHANGELOG.md`): complete first version, in validation on real projects.

## Feedback

Questions, ideas and problems: [open an issue](../../issues).

## License

MIT
