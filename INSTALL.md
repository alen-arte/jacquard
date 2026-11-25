# Installing Jacquard

Written so you can hand it to Claude Code as-is: "Install Jacquard following INSTALL.md". Each step that writes outside the current folder needs your OK.

## Before anything: verify against current docs

Claude Code evolves fast. Check the official documentation and adapt these steps if something changed, reporting what you adapted:
- Personal skills live in `~/.claude/skills/<name>/SKILL.md`; `disable-model-invocation: true` keeps them out of context until invoked; `$ARGUMENTS` and `${CLAUDE_SKILL_DIR}` work.
- `CLAUDE.local.md` is loaded and is not tracked; `@~/...` imports work from it; the first external import shows an approval dialog.
- Imports and skills work through symbolic links.
- The permission rule syntax used in `templates/project/claude-settings.local.template.json`, including `permissions.additionalDirectories`, and that Claude Code still runs its built-in read-only commands without a rule.
- User subagents in `~/.claude/agents/` load through symbolic links, with `tools` and `maxTurns` in their frontmatter (the QA reviewer, step 2).
- The hook events the Away guard uses (`PermissionRequest`, `Elicitation`, `SessionStart`), their decision output, and that `CLAUDE_CODE_SESSION_ID` matches the hooks' `session_id` in Bash and hook subprocesses.
- Only with cloud sync (step 6): a cloud session sets `CLAUDE_CODE_REMOTE=true`, loads a `CLAUDE.local.md` committed on its branch next to the project's `CLAUDE.md`, and runs the `SessionStart` hook of the branch's `.claude/settings.json`.

Last verified with Claude Code 2.1.296 (2026-10-11; the permissions page re-checked 2026-10-12). Worth knowing:
- Model and effort can be set per subagent launch and per skill turn (`effort` in a skill's frontmatter); the main session's model is yours (`/model`, `/effort`). `core/economy.md` uses these.
- Every subagent except the built-in Explore and Plan loads `CLAUDE.local.md` and its imports.
- Claude Code's Chrome integration does not run in WSL; a headless browser run from the command line works for `render_check`.
- Imports outside the project, including through a link such as `.jacquard`, load **only after the approval dialog is accepted**. Until then nothing from Jacquard loads, silently.
- `~/.claude/` is a protected folder: allow rules never pre-approve a write there; it asks in the default mode and goes to the classifier in auto mode (an explicit deny still blocks it). That is why the personal layer, which projects write into, lives in `~/repos/`, and why the installed kit needs its own deny (step 4).
- Permission rules on a link must match both the link and its target to allow; either one to deny. A terminal write through a link that leads outside the working directories asks even in auto mode, unless the target is a working directory: hence `additionalDirectories` for the personal project folder.
- Read-only commands (`ls`, `cat`, `grep`, `find` without actions, `diff`, read-only `git`) run without asking and need no rule; a prefix rule such as `Bash(sed *)` would also allow their writing forms.
- `CLAUDE.local.md` is not ignored by git on its own; kickoff excludes it in `.git/info/exclude`.
- `/memory` does not list imported files; `/context` does.
- When a skill and a command share a name, the skill wins for project commands; for `~/.claude/commands/` it is undocumented, hence the stop rule in step 2.
- Deny rules are a safety net, not a wall: a variant such as `git -C . push` can escape a pattern.
- Permission modes decide whether Claude Code asks before each action, not what Claude decides or reports. Away needs **auto** mode (Shift+Tab): the default mode asks before every edit and an unattended block stalls. Deny rules apply in every mode.
- A `PermissionRequest` hook runs whenever Claude Code is about to show a permission prompt (that it fires in auto mode, where the classifier decides most actions, is still to be confirmed in a real session). The Away guard (`scripts/away-guard.sh`, hooks in the permissions template) uses it to deny prompts in the Away session only; it never allows anything. Hooks from settings files run only after the workspace trust dialog is accepted.

## 1. The kit

Your working copy, and an installed copy pinned to a release, so editing the kit never changes the rules of a running session:

```bash
git clone https://github.com/<you>/jacquard ~/repos/jacquard
git -C ~/repos/jacquard worktree add --detach ~/.claude/jacquard v0.2.15   # the latest release tag
```

Only using the kit, never editing it: `git clone --branch v0.2.15 https://github.com/<you>/jacquard ~/.claude/jacquard` is enough.

## 2. Commands

Link each skill into `~/.claude/skills/`, stopping at any name already taken:

```bash
mkdir -p ~/.claude/skills
for s in ~/.claude/jacquard/skills/*/; do
  n=$(basename "$s")
  if [ -e ~/.claude/skills/"$n" ] || [ -e ~/.claude/commands/"$n".md ]; then echo "skip $n: already exists"; continue; fi
  ln -s "${s%/}" ~/.claude/skills/"$n"
done
```

For each name skipped: back up the existing skill or command and ask before replacing it.

Link the reviewer subagents into `~/.claude/agents/` the same way (today only `jacquard-qa-reviewer`; each adds one line to every session's context):

```bash
mkdir -p ~/.claude/agents
for a in ~/.claude/jacquard/agents/*.md; do
  n=$(basename "$a")
  if [ -e ~/.claude/agents/"$n" ]; then echo "skip $n: already exists"; continue; fi
  ln -s "$a" ~/.claude/agents/"$n"
done
```

Check with `/agents` that `jacquard-qa-reviewer` is listed.

After updating the kit, remove links left dangling by a renamed or deleted skill (for example `kit-update`, now `jacquard-update`); this only touches broken links that point into the kit:

```bash
find -L ~/.claude/skills ~/.claude/agents -maxdepth 1 -type l 2>/dev/null | while IFS= read -r l; do
  case "$(readlink "$l")" in *jacquard*) echo "removing dangling link $l"; rm "$l";; esac
done
```

## 3. Your personal layer (private)

1. Create a **private** repository from the `personal/` folder of this kit.
2. Clone it to `~/repos/jacquard-personal/` (not under `~/.claude/`: see above).
3. Fill `preferences.md` (only the keys you want to change) and `privacy-terms.txt` (your name, handles, collaborators, project names).
4. Backups: in Present, after work is committed or a project's documents change, Claude runs `scripts/personal-sync.sh` from the project repo. It commits that project's folder in your personal layer and pushes the layer's `main`, fast-forward only. It refuses unless `gh` is signed in and the layer's `main` tracks a private GitHub repo where you are the only collaborator. The project sessions never run git in the layer directly.

## 4. Permissions

Let commands read the kit and your preferences without asking each time. Add to `permissions.allow` in `~/.claude/settings.json`:

```json
"Read(~/.claude/jacquard/**)", "Read(~/repos/jacquard-personal/**)"
```

Each project's own rules (writes to its local folder, git safety net) come from kickoff.

**The installed kit is a trust boundary.** Its scripts run from hooks (on permission prompts, MCP questions and session start) and from allow rules without asking, so a change to them could run anything. Change `~/.claude/jacquard` only by installing a release tag yourself, in a terminal (step 1, or "Updating the installed kit" below), never by editing it. Each project's permissions deny edits there; add the same rule to your user settings to cover every project, including those set up before 0.2.8:

```json
"permissions": { "deny": ["Edit(~/.claude/jacquard/**)"] }
```

The rule refuses Claude's file tools and the writing commands Claude Code recognizes in the terminal (`sed -i`, `tee`) when they name the path in full. It does not refuse everything: a redirect written with `~` or `$HOME` asks instead of being refused, and other programs (`cp`, a script that writes files itself) and git operations inside the folder (`checkout`, `reset`) are not covered. For a hard wall, use Claude Code's sandbox.

## 5. First use

In a project folder, run `/kickoff`. Then start a new session there (the new `CLAUDE.local.md` loads at session start) and approve the external imports dialog. Check with `/context` that `CLAUDE.local.md`, the core standards, your preferences and the project index are loaded, and nothing else from Jacquard.

## 6. Optional: working from cloud sessions

To keep working from a Claude Code cloud session (phone, web) with the same kit, set `cloud_sync: on` in your `preferences.md`. Turning it on is your standing OK for the pushes this needs, and for making the kit branch the default one, on the project's private repo only (`core/git.md` › Cloud sync). Needs `gh`, signed in, `python3` and `iconv`.

The cloud clones only the repo it is attached to, so `scripts/cloud.sh prepare` puts the kit on a branch of that repo, `cloud/<branch>`: your branch's files, plus the framework, your preferences and everything in the project's local folder. What the personal layer git-ignores never travels, nor a name with a part that starts with a dot, an unusual name, a `<file>.cloud`, a file shaped like settings or keys, the local folder's `migration-backup/` (copies kept on your computer, still backed up in the personal layer), or a link. Deletions made in the cloud come back too, with brakes that `land` explains. Every sync stays in that branch's history, so a file that should leave the cloud needs the `cloud/` branches deleted, not only ignored. That branch becomes the repo's default branch, so new cloud sessions start on it, and it is never merged into `main`. It refuses to push unless the repo's one push URL is a private GitHub repo with no other collaborators. When `origin` is shared with other people, add a private repo of your own as a second remote and name it in the project's local git config: `git config jacquard.cloudRemote <name>`. When the repo deploys or runs workflows (a deploy preview, a scheduled job on the default branch), it stops and asks you to choose: that separate remote, or the `git config jacquard.cloudDeployOk "…"` it prints, a yes to exactly what it found (it asks again when something new appears). A deploy app with no file and no deployment yet cannot be seen. `cloud.sh land` brings the cloud's commits and documents back to your computer. Before you share a repo or make it public, delete its `cloud/` branches there: they hold your preferences and project documents. Never check out a `cloud/` branch on your computer: it would replace your `CLAUDE.local.md`.

## Updating the installed kit

When a new release is tagged, and no Away block is running in any project:

```bash
git -C ~/.claude/jacquard fetch --tags      # skip if you tagged it in your working clone
git -C ~/.claude/jacquard checkout --detach v0.2.15
```

New sessions use it. Run step 2 again (it links new commands and skips existing ones), then `/jacquard-update` in each project to bring its files up to date, piece by piece.

To see whether a project or the install lags behind, `/jacquard-update --check` compares versions without changing anything; `/jacquard-update --all`, from any session, lists every project in your personal layer with what each needs. A project behind the installed kit also says so when a session starts, if it has the kit's `SessionStart` hook (in the permissions template; a project set up before 0.2.7 gets it from `/jacquard-update`). That hook runs `scripts/session-start.sh`, which runs each session-start job on its own; settings from before it name `away-guard.sh session-start`, which hands over to it, so they keep working until `/jacquard-update` offers the new entry. Projects without the hook are covered by `--all` only.

### Upgrading from 0.1.1

0.1.1 linked `~/.claude/jacquard` to the working repo and kept the personal layer in `~/.claude/jacquard-personal/`. Once, with your OK for each step:

```bash
mv ~/.claude/jacquard-personal ~/repos/jacquard-personal
ln -s ~/repos/jacquard-personal ~/.claude/jacquard-personal   # temporary, so 0.1.1 projects still load
rm ~/.claude/jacquard                       # the link, not the repo
git -C ~/repos/jacquard worktree add --detach ~/.claude/jacquard v0.1.2
```

Then step 4 (permissions), the hooks in "Publishing changes to the kit" (they replace the 0.1.1 pre-push hook), and `/jacquard-update` in each project: it re-points `<local>` and the imports in `CLAUDE.local.md`, and brings the permissions and the pre-commit guard up to date. When every project is updated, remove the temporary link: `rm ~/.claude/jacquard-personal`.

## Publishing changes to the kit

Install the privacy hooks in your clone of the kit. The pre-commit hook checks what each commit records; the pre-push hook checks every commit and tag the push would publish to that remote (content, paths, messages, author), not just the current files. The pre-push hook asks the remote what it already has (`git ls-remote`), a second connection: an SSH key without an agent asks for its passphrase twice. They are small stubs that run the installed kit's copy, so a branch without the scripts, or with changed ones, cannot skip or alter the check:

```bash
for h in pre-commit pre-push; do
  printf '#!/bin/sh\nexec "$HOME/.claude/jacquard/scripts/hooks/%s" "$@"\n' "$h" > ~/repos/jacquard/.git/hooks/$h
  chmod +x ~/repos/jacquard/.git/hooks/$h
done
```

Both fail closed: without the installed kit, `iconv`, or your terms file, nothing is committed or published. Your commit identity is checked too; to keep your email private, use your host's no-reply address in this repo, and list it as allowed in `privacy-terms.txt` with a leading `!`. To publish an image you reviewed (metadata removed), allow that exact file with a line `=<id> <path>` (from 0.2.8 of the installed kit; the refusal explains how).
