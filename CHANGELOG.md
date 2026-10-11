# Changelog

## 0.2.2
- **Status marks in the roadmap** (`core/docs-system.md`): `[ ]` not done, `[~]` done on a branch other than `main` (data line: branch and commit), `[x]` in `main` (production). Claude sets `[~]` as each task finishes and `[x]` when the branch is integrated; the proposals table uses `☐ ◐ ☑ ✗`. Fixes Away leaving finished work as open checks with free-text status.
- **Away never uses `main`'s name:** from `main` it creates a new branch named after the brief (`away/r12-r14`); from a work branch it uses `away/<that-branch>`. The base branch is recorded in the journal.
- **`/kit-update` is now `/jacquard-update`.** Run INSTALL step 2 again to link it and remove the old `kit-update` link.

## 0.2.1
- Markdown Away reports embed the captures of visual decisions as images (relative paths: no token cost); `/back` lists them as clickable paths.

## 0.2.0
- **Economy without lowering the bar** (`core/economy.md`): tiers `light / standard / strong` mapped to models and effort in preferences (`tiers`), a `budget` profile (`lean / balanced / generous`), a floor for level-2 reviews, cost estimates in subagent runs at the Away gate and before expensive steps. Light never produces what the user receives.
- **Subagents already load the always-loaded files** (verified with Claude Code 2.1.296): every subagent except Explore and Plan loads `CLAUDE.local.md` and its imports, so prompts and role files no longer ask to re-read them.
- **Tests for the kit itself** (`tests/`, `scripts/test-prompt.sh`): two or three cases per command, role and new rule, run on demand by one light subagent per file; the prompt hides titles and criteria.
- **Visual QA in a real browser** (`core/visual-qa.md`): what to capture, where, who looks, image cost; `render_check` in project facts; "no real visual check" is never an approval.
- **Design exploration** (`core/design-exploration.md`) and the **design critic** role: concepts that differ by idea and not by intensity, an independent filter, renders of the survivors only, a protocol for rejecting every option, and design memory.
- **New commands:** `/retro` (what worked and what cost too much, from data lines and summaries) and `/debate` (two or three perspectives for a large decision, cost first).
- Closed roadmap items record `reviews`, `findings` and `rework` in their data line.
- Each review's tier and effort live in `review.md`'s intensity table, so launching a review reads one file. With `budget: lean`, the Away report is markdown only.
- `/rigor` runs its own turn at low effort; `/retro` counts at the light tier and judges at the session's effort.

## 0.1.3
- Away runs in auto mode: the gate reminds the user (Shift+Tab); the install notes explain that permission modes change prompts, not Jacquard's rules.

## 0.1.2
- **Privacy lock:** the check fails closed (missing, empty or unreadable terms file, missing tools, unreadable history), reads terms written on Windows, ignores case and accents, scans file names, link targets and any file name, and judges each email on its own. New hooks: pre-commit checks what a commit records; pre-push checks every commit and tag a push would publish to that remote (content, paths, messages, author, merges), not just the current files. Hooks are installed as stubs that run the installed kit's copy. `!Name <email>` in the terms file allows an exact commit identity such as a public no-reply one; it must be a full identity containing a term. Findings name terms by number.
- **Project permissions:** the template blocks adding the local files to git, force-push in every form, skipping hooks, history rewriting, git configuration and publishing with `gh`; resets, restores, stashes, remotes and recursive deletes ask; writes to the local folder are allowed. Kickoff adds a local pre-commit guard (no commits on the main branch, no local files in a commit) where the repo has no hooks of its own.
- **Install:** the installed kit is pinned to a release tag (editing the kit no longer changes running sessions); the personal layer moves to `~/repos/jacquard-personal/` because Claude Code protects `~/.claude/`; read permissions for the kit; the skill links step checks before linking.
- **Commands:** every command stops when Jacquard is not loaded (not a Jacquard project, or imports not approved); `/back` stops when Away is not active; `/kit-update` can move a plain local folder into the personal repo.
- **Kickoff:** reads the personal preferences itself; stops if local files are already tracked; the interview has a default for every question with options, counts blocks consistently, uses plain words for review and publishing, and proposes the stack once; the proposal adds name, hosting, irreversibles and where Away works; placeholders always resolve; the initial audit for adopted projects is offered; stricter verification.
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
