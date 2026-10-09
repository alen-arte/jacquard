# Installing Jacquard

Written so you can hand it to Claude Code as-is: "Install Jacquard following INSTALL.md". Each step that writes outside the current folder needs your OK.

## Before anything: verify against current docs

Claude Code evolves fast. Check the official documentation and adapt these steps if something changed, reporting what you adapted:
- Personal skills live in `~/.claude/skills/<name>/SKILL.md`; `disable-model-invocation: true` keeps them out of context until invoked; `$ARGUMENTS` and `${CLAUDE_SKILL_DIR}` work.
- `CLAUDE.local.md` is loaded and is not tracked; `@~/...` imports work from it; the first external import shows an approval dialog.
- Imports and skills work through symbolic links.
- The permission rule syntax used in `templates/project/settings.local.json`.

Last verified with Claude Code 2.1.295 (2026-10-09). Worth knowing:
- Imports outside the project, including through a link such as `.jacquard`, load **only after the approval dialog is accepted**. Until then nothing from Jacquard loads, silently.
- `~/.claude/` is a protected folder: writes there always ask, whatever the rules say. That is why the personal layer, which projects write into, lives in `~/repos/`.
- Permission rules on a link must match both the link and its target to allow; either one to deny.
- `CLAUDE.local.md` is not ignored by git on its own; kickoff excludes it in `.git/info/exclude`.
- `/memory` does not list imported files; `/context` does.
- When a skill and a command share a name, the skill wins for project commands; for `~/.claude/commands/` it is undocumented, hence the stop rule in step 2.
- Deny rules are a safety net, not a wall: a variant such as `git -C . push` can escape a pattern.

## 1. The kit

Your working copy, and an installed copy pinned to a release, so editing the kit never changes the rules of a running session:

```bash
git clone https://github.com/<you>/jacquard ~/repos/jacquard
git -C ~/repos/jacquard worktree add --detach ~/.claude/jacquard v0.1.2   # the latest release tag
```

Only using the kit, never editing it: `git clone --branch v0.1.2 https://github.com/<you>/jacquard ~/.claude/jacquard` is enough.

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
git -C ~/.claude/jacquard checkout --detach v0.1.3
```

New sessions use it. Run step 2 again (it links new commands and skips existing ones), then `/kit-update` in each project to bring its files up to date, piece by piece.

### Upgrading from 0.1.1

0.1.1 linked `~/.claude/jacquard` to the working repo and kept the personal layer in `~/.claude/jacquard-personal/`. Once, with your OK for each step:

```bash
mv ~/.claude/jacquard-personal ~/repos/jacquard-personal
rm ~/.claude/jacquard                       # the link, not the repo
git -C ~/repos/jacquard worktree add --detach ~/.claude/jacquard v0.1.2
```

Then step 4 (permissions), and `/kit-update` in each project: it re-points `<local>` and the imports in `CLAUDE.local.md`, and brings the permissions and the pre-commit guard up to date.

## Publishing changes to the kit

Install the privacy hooks in your clone of the kit. The pre-commit hook checks what each commit records; the pre-push hook checks every commit and tag the push would publish (content, paths, messages, author), not just the current files:

```bash
ln -s ../../scripts/hooks/pre-commit ~/repos/jacquard/.git/hooks/pre-commit
ln -s ../../scripts/hooks/pre-push ~/repos/jacquard/.git/hooks/pre-push
```

Both fail closed: without your terms file nothing is published. Your commit identity is checked too; to keep your email private, use your host's no-reply address in this repo, and list it as allowed in `privacy-terms.txt` with a leading `!`.
