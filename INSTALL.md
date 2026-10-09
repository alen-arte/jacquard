# Installing Jacquard

Written so you can hand it to Claude Code as-is: "Install Jacquard following INSTALL.md".

## Before anything: verify against current docs

Claude Code evolves fast. Check the official documentation and adapt these steps if something changed, reporting what you adapted:
- Personal skills live in `~/.claude/skills/<name>/SKILL.md`; `disable-model-invocation: true` keeps them out of context until invoked; `$ARGUMENTS` and `${CLAUDE_SKILL_DIR}` work.
- `CLAUDE.local.md` is loaded and is not tracked; `@~/...` imports work from it; the first external import shows an approval dialog.
- Imports and skills work through symbolic links.
- The permission rule syntax used in `templates/project/settings.local.json`.

Last verified with Claude Code 2.1.295 (2026-10-09). Worth knowing:
- Imports outside the project, including through a link such as `.jacquard`, load **only after the approval dialog is accepted**. Until then nothing from Jacquard loads, silently.
- `CLAUDE.local.md` is not ignored by git on its own; kickoff excludes it in `.git/info/exclude`.
- `/memory` does not list imported files; `/context` does.
- When a skill and a command share a name, the skill wins for project commands; for `~/.claude/commands/` it is undocumented, hence the stop rule in step 2.
- Deny rules are a safety net, not a wall: the docs note that variants such as `git -C . push` can escape a pattern.

## 1. The kit

```bash
git clone https://github.com/<you>/jacquard ~/repos/jacquard
ln -s ~/repos/jacquard ~/.claude/jacquard
```

A working clone plus a link means edits to the kit apply immediately.

## 2. Commands

For each folder in `~/.claude/jacquard/skills/`, link it into `~/.claude/skills/`:

```bash
mkdir -p ~/.claude/skills
for s in ~/.claude/jacquard/skills/*/; do ln -s "$s" ~/.claude/skills/"$(basename "$s")"; done
```

If a skill or a command with the same name already exists (`~/.claude/skills/<name>` or `~/.claude/commands/<name>.md`), stop: back it up and ask before replacing it.

## 3. Your personal layer (private)

1. Create a **private** repository from the `personal/` folder of this kit.
2. Clone it to `~/.claude/jacquard-personal/`.
3. Fill `preferences.md` (only the keys you want to change) and `privacy-terms.txt` (your name, handles, collaborators, project names).

## 4. First use

In a project folder, run `/kickoff`. Then start a new session there (the new `CLAUDE.local.md` loads at session start) and approve the external imports dialog. Check with `/context` that `CLAUDE.local.md`, the core standards, your preferences and the project index are loaded, and nothing else from Jacquard.

## Publishing changes to the kit

Install the privacy check as a pre-push hook in your clone of the kit:

```bash
cat > ~/repos/jacquard/.git/hooks/pre-push <<'HOOK'
#!/bin/sh
root="$(git rev-parse --show-toplevel)"
exec "$root/scripts/privacy-check.sh" "$root"
HOOK
chmod +x ~/repos/jacquard/.git/hooks/pre-push
```
