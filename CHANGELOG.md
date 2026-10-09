# Changelog

## 0.1.1
- Privacy check now scans files that look binary (a NUL byte) instead of skipping them silently; script is executable.
- `.gitignore` for Windows download markers (`*:Zone.Identifier`), which carry local paths.
- Install and kickoff: check loaded files with `/context` (`/memory` does not list imports); the new `CLAUDE.local.md` loads from the next session and needs the external imports approval.
- Install: notes from verification against Claude Code 2.1.295.
- README: feedback via issues.

## 0.1.0
- MIT license.
- Core standards, design standards, review system, method, git rules, documents system, default preferences.
- Role library: product designer, frontend, backend/data, QA, engineering advisor, security and privacy, domain advisor template.
- Project and document templates; personal layer template; privacy check.
- Work modes (Present and Away) with per-project Away profiles that can only add limits.
- Commands as skills: /kickoff (with interview and adoption mode), /away, /back, /away-resume, /rigor, /kit-update.
- Installation guide and user guide.
