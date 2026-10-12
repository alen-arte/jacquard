# Installing Jacquard

Written so you can hand it to Claude Code as-is: "Install Jacquard following INSTALL.md". Each step that writes outside the current folder needs your OK.

## Before anything: verify against current docs

Claude Code evolves fast. Check the official documentation and adapt these steps if something changed, reporting what you adapted:
- Personal skills live in `~/.claude/skills/<name>/SKILL.md`; `disable-model-invocation: true` keeps them out of context until invoked; `$ARGUMENTS` and `${CLAUDE_SKILL_DIR}` work.
- `CLAUDE.local.md` is loaded and is not tracked; `@~/...` imports work from it; the first external import shows an approval dialog.
- Imports and skills work through symbolic links.
- The permission rule syntax used in `templates/project/settings.local.json`.
- The hook events the Away guard uses (`PermissionRequest`, `Elicitation`, `SessionStart`), their decision output, and that `CLAUDE_CODE_SESSION_ID` matches the hooks' `session_id` in Bash and hook subprocesses.

Last verified with Claude Code 2.1.296 (2026-10-11). Worth knowing:
- Model and effort can be set per subagent launch and per skill turn (`effort` in a skill's frontmatter); the main session's model is yours (`/model`, `/effort`). `core/economy.md` uses these.
- Every subagent except the built-in Explore and Plan loads `CLAUDE.local.md` and its imports.
- Claude Code's Chrome integration does not run in WSL; a headless browser run from the command line works for `render_check`.
- Imports outside the project, including through a link such as `.jacquard`, load **only after the approval dialog is accepted**. Until then nothing from Jacquard loads, silently.
- `~/.claude/` is a protected folder: writes there always ask, whatever the rules say. That is why the personal layer, which projects write into, lives in `~/repos/`.
- Permission rules on a link must match both the link and its target to allow; either one to deny.
- `CLAUDE.local.md` is not ignored by git on its own; kickoff excludes it in `.git/info/exclude`.
- `/memory` does not list imported files; `/context` does.
- When a skill and a command share a name, the skill wins for project commands; for `~/.claude/commands/` it is undocumented, hence the stop rule in step 2.
- Deny rules are a safety net, not a wall: a variant such as `git -C . push` can escape a pattern.
- Permission modes decide whether Claude Code asks before each action, not what Claude decides or reports. Away needs **auto** mode (Shift+Tab): the default mode asks before every edit and an unattended block stalls. Deny rules apply in every mode.
- A `PermissionRequest` hook runs whenever Claude Code is about to show a permission prompt, whatever the mode. The Away guard (`scripts/away-guard.sh`, hooks in the permissions template) uses it to deny prompts in the Away session only; it never allows anything. Hooks from settings files run only after the workspace trust dialog is accepted.

## 1. The kit

Your working copy, and an installed copy pinned to a release, so editing the kit never changes the rules of a running session:

```bash
git clone https://github.com/<you>/jacquard ~/repos/jacquard
git -C ~/repos/jacquard worktree add --detach ~/.claude/jacquard v0.2.6   # the latest release tag
```

Only using the kit, never editing it: `git clone --branch v0.2.6 https://github.com/<you>/jacquard ~/.claude/jacquard` is enough.

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

After updating the kit, remove links left dangling by a renamed or deleted skill (for example `kit-update`, now `jacquard-update`); this only touches broken links that point into the kit:

```bash
for l in ~/.claude/skills/*; do
  [ -L "$l" ] && [ ! -e "$l" ] && case "$(readlink "$l")" in *jacquard*) echo "removing dangling link $l"; rm "$l";; esac
done
```

## 3. Your personal layer (private)

1. Create a **private** repository from the `personal/` folder of this kit.
2. Clone it to `~/repos/jacquard-personal/` (not under `~/.claude/`: see above).
3. Fill `preferences.md` (only the keys you want to change) and `privacy-terms.txt` (your name, handles, collaborators, project names).

## 4. Permissions

Let commands read the kit and your preferences without asking each time. Add to `permissions.allow` in `~/.claude/settings.json`:

```json
"Read(~/.claude/jacquard/**)", "Read(~/repos/jacquard-personal/**)"
```

Each project's own rules (writes to its local folder, git safety net) come from kickoff.

## 5. First use

In a project folder, run `/kickoff`. Then start a new session there (the new `CLAUDE.local.md` loads at session start) and approve the external imports dialog. Check with `/context` that `CLAUDE.local.md`, the core standards, your preferences and the project index are loaded, and nothing else from Jacquard.

## Updating the installed kit

When a new release is tagged, and no Away block is running in any project:

```bash
git -C ~/.claude/jacquard fetch --tags      # skip if you tagged it in your working clone
git -C ~/.claude/jacquard checkout --detach v0.2.6
```

New sessions use it. Run step 2 again (it links new commands and skips existing ones), then `/jacquard-update` in each project to bring its files up to date, piece by piece.

To see whether a project or the install lags behind, `/jacquard-update --check` compares versions without changing anything.

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

Install the privacy hooks in your clone of the kit. The pre-commit hook checks what each commit records; the pre-push hook checks every commit and tag the push would publish to that remote (content, paths, messages, author), not just the current files. They are small stubs that run the installed kit's copy, so a branch without the scripts, or with changed ones, cannot skip or alter the check:

```bash
for h in pre-commit pre-push; do
  printf '#!/bin/sh\nexec "$HOME/.claude/jacquard/scripts/hooks/%s" "$@"\n' "$h" > ~/repos/jacquard/.git/hooks/$h
  chmod +x ~/repos/jacquard/.git/hooks/$h
done
```

Both fail closed: without the installed kit, `iconv`, or your terms file, nothing is committed or published. Your commit identity is checked too; to keep your email private, use your host's no-reply address in this repo, and list it as allowed in `privacy-terms.txt` with a leading `!`.
