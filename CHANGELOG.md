# Changelog

## 0.1.2
- **Privacy lock:** the check fails closed (missing, empty or unreadable terms file, missing tools, unreadable history), reads terms written on Windows, ignores case and accents, scans file names, link targets and any file name, and judges each email on its own. New hooks: pre-commit checks what a commit records; pre-push checks every commit and tag a push would publish to that remote (content, paths, messages, author, merges), not just the current files. Hooks are installed as stubs that run the installed kit's copy. `!text` in the terms file allows an exact text such as a public commit identity; it must contain a term and be longer than it. Findings name terms by number.
- **Project permissions:** the template blocks adding the local files to git, force-push in every form, skipping hooks, history rewriting, git configuration and publishing with `gh`; resets, restores, stashes, remotes and recursive deletes ask; writes to the local folder are allowed. Kickoff adds a local pre-commit guard (no commits on the main branch, no local files in a commit) where the repo has no hooks of its own.
- **Install:** the installed kit is pinned to a release tag (editing the kit no longer changes running sessions); the personal layer moves to `~/repos/jacquard-personal/` because Claude Code protects `~/.claude/`; read permissions for the kit; the skill links step checks before linking.
- **Commands:** every command stops when Jacquard is not loaded (not a Jacquard project, or imports not approved); `/back` stops when Away is not active; `/kit-update` can move a plain local folder into the personal repo.
- **Kickoff:** reads the personal preferences itself; stops if local files are already tracked; the interview has a default for every question, counts blocks consistently, uses plain words for review and publishing, and proposes the stack once; the proposal adds name, hosting, irreversibles and where Away works; placeholders always resolve; the initial audit for adopted projects is offered; stricter verification.
- **Consistency with agreed decisions:** the Away report puts "Needs your OK" first; an Away profile only narrows (where Away works, publishing off, shared files as the core's single exception); migrations need a fresh backup; nobody commits on `main`.
- **One rule in one place:** risk levels and the floor move to core standards; `<local>` is defined once; duplicated git, review and loading rules now point to their source; intensity precedence and notes for collaborators are defined; reviews still run when a role was not created.

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
