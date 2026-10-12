# Changelog

## 0.2.7
- **Away guard** (`scripts/away-guard.sh`, hooks in the permissions template): a technical backstop so an Away block never stalls on a prompt the gate's audit missed. `/away` turns it on after the OK and `/away-resume` in its new session; `/back` (or the end of the block) turns it off. While it is on, a `PermissionRequest` hook denies the prompt with a message telling Claude to use a safe equivalent or park the step, and an `Elicitation` hook declines an MCP server's question. The marker (`<local>/away/.away-active`) holds the Away session's id (`CLAUDE_CODE_SESSION_ID`), so a second session open in the same project is never affected and never switches it off; a `SessionStart` hook clears it when the Away session is resumed or cleared, and keeps it on compaction. It only ever denies or declines, never allows. Kickoff fills `{{LOCAL_FOLDER}}` in the hooks; `/jacquard-update` brings them to existing projects. Script tests in `tests/scripts/`.
- **Privacy check reads encoded content** (`scripts/privacy-check.sh`): UTF-16 files (with or without BOM) are converted and checked; base64 runs (standard or URL-safe, 8+ characters) are decoded and checked as extra lines; binary or compressed content (gzip, zip, bzip2, xz, zstd, 7z, or anything with NUL bytes that is not UTF-16) cannot be read, so it is refused and listed. In `--staged` and `--objects` modes, the blobs git calls binary are read the same way.
- **Privacy check, smaller fixes:** the LICENSE exception applies only to the copyright lines of the top-level `LICENSE` (a file named like the old label, or a `LICENSE` elsewhere, no longer hides content); macOS portability (no `find -printf`; picks `C.UTF-8` or `en_US.UTF-8`, whichever exists). Script tests in `tests/scripts/privacy-check.test.sh`.
- **Pre-push checks against the remote's real refs** (`scripts/hooks/pre-push`): it lists what the remote at the push URL has (`git ls-remote`), instead of trusting the tracking refs, which after a `remote set-url` describe the old URL; if it cannot list them, every commit is checked.
- **Pre-commit guard:** also refuses a commit on a detached HEAD outside a rebase, cherry-pick, revert or bisect (it would belong to no branch and could reach main with a push of `HEAD`).
- **Away branch rule** (`core/git.md`): already on an `away/…` branch, Away continues on it; a brief that changes nothing tracked creates no branch. The gate says which. Hook tests in `tests/scripts/git-hooks.test.sh`.
- **QA as a defined subagent** (`agents/jacquard-qa-reviewer.md`, pilot of one): read-only tools (`Read, Grep, Glob`) and a cap of 40 turns, linked into `~/.claude/agents/` by `INSTALL.md` step 2. `core/review.md` launches QA with it when installed, with the model and effort still passed per launch; the prompt carries the check results, since QA cannot run commands. Other reviews stay general-purpose until the pilot is measured with `/retro`.

## 0.2.6
- **Away no longer stalls on a permission prompt** (`core/work-modes.md`): the gate audits, silently, every task's tools and commands against `allow`/`ask`/`deny` (project and user settings) and against tools that confirm on their own even when allowed (an MCP server that confirms schema changes), and writes only what would ask: the user adds an allow now, or the step is parked, or (for a self-confirming tool) it runs right after the OK while the user is there. The gate also reads the user's feedback memories about Away: stricter ones are followed, looser ones are a rule conflict. An assigned migration runs only if its tool runs without a prompt; otherwise it is parked with the SQL, backup and restore steps ready. A new rail: before a command the audit did not cover, match it against `ask`/`deny` and the self-confirming tools, and use a safe equivalent with commands the template already allows (a WIP commit instead of `stash`, `reset`, `checkout --`; test-first, or `git revert` twice, to see a check fail without a fix; only the commands `project.md` lists, never `npx`) or park the step.
- **`/away-resume` re-audits** the remaining tasks and the items parked for a permission, while the user is present.
- **Templates:** the Away profile gets "Tools that confirm on their own"; the permissions template denies `git stash … --output` (it can overwrite any file) and abbreviated `git reset --h…` (git accepts `--har` for `--hard`), and asks before `git revert --abort`. Resets and stashes still ask: loosening them was considered and dropped, since an abbreviated `--hard` slips past the deny and the rail above makes them unnecessary.
- **One definition, many uses** (`core/standards.md`, `core/design-standards.md` #10, `core/review.md`, roles): whatever applies in more than one place is defined once and consumed; the builder searches by event, state and property before building, keeps confirmed values when extracting, and names reused or extracted definitions in the handoff note (new point 6); reviewers get those files and search the repo, not only the diff; the engineering advisor runs on the affected area when duplication remains that the task did not resolve. Elements reacting to the same event share one effect and one clock.
- **`work-modes.md` split:** sections 7–9 and "Ending" move to `core/away-run.md`. `/back` reads only that file (about 4.9 KB instead of 12.6 KB; it saves reading only when `/back` runs in a session that has not read `work-modes.md` yet); `/away` and `/away-resume` read both, since resuming keeps working under sections 2–6.
- **`/jacquard-update --check`:** compares the project's kit version, the installed one and the latest release, and only reports.
- Tests: `tests/core/away-permissions.md`, `tests/core/single-source.md`, new cases for `/away-resume`, `/jacquard-update` and QA.

## 0.2.5
- **Archiving of finished batches** (`core/docs-system.md`): before every block of work (Away gate, or the first task of a batch in Present) Claude asks, in one line, whether to move each complete batch (all items ✅ or ❌) to `roadmap-done.md`; only the user's OK moves it. The roadmap keeps a single `📦` line naming the last batch moved, replaced each time; the status index counts only what is still in the roadmap. Rejected items and approved/rejected proposals still move at the next edit without asking.
- The Away gate's "needs you first" now says ⚖️ (it still said `⏸`).

## 0.2.4
- **Seven status marks** (`core/docs-system.md`): ⬜ Waiting · ⚖️ Decide (the user picks an option) · 👀 Review (built in dev, no OK yet) · 🚀 Staged (approved, only the release is left) · ✅ Done (in production) · 🔵 Approved (proposals) · ❌ Rejected (`R` or `P`, always with a reason). Replaces 🟡 and the `⏸` flag. Away ends at 👀; only the user's OK moves 👀 → 🚀; only the release moves 🚀 → ✅.
- **Rejected items are logged**: ❌ needs `rejected:` and `why:`, and the item moves to `roadmap-done.md` under "Rejected" at the next edit.
- **Status index** at the top of the roadmap (IDs by status), derived by `scripts/roadmap-index.sh --write|--check` so Claude edits only the item and never both places by hand.
- Tests for the new marks in `tests/core/proposal-marks.md`; template, guide, `/back`, Away and integration text aligned.

## 0.2.3
- **Proposal marks fixed** (`core/docs-system.md`, roadmap template, guide): approved proposals use 🔵 and ✅ never appears on a proposal (it means done; progress lives on the `R#`). 0.2.2 let "✅ Approved" through, contradicting its own marks table. Approved and declined rows leave the proposals table at the next roadmap edit: approved ones vanish (they live on as `R#`), declined ones move to `roadmap-done.md` under "Declined proposals".
- INSTALL points to the latest tag and removes dangling skill links (the `kit-update` leftover from 0.2.2).
- Planning triggers on feedback, ideas or a change of direction (not on plan mode alone); a plain request only names its `R#`; a *contradicts* point is asked explicitly; projects with external planning are covered.
- **Planning against the roadmap** (`core/standards.md`, `core/docs-system.md`): plan mode now reads the roadmap and `D#` first, tags each point of the user's input (already in / changes / contradicts / new), writes nothing to the documents until approval, and ends with a "Roadmap changes" section that is applied as the first step after approving.

## 0.2.2
- **Status marks in the roadmap** (`core/docs-system.md`): ⬜ not done, 🟡 done on a branch other than `main` (data line: branch and commit), ✅ in `main` (production); emoji because Markdown task boxes cannot show a third state. Claude sets 🟡 as each task finishes and ✅ when the branch is integrated. The proposals table puts the status first, with a bold titled entry per proposal. Fixes Away leaving finished work as open checks with free-text status.
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
