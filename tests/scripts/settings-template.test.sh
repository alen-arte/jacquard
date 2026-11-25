#!/usr/bin/env bash
# Tests for templates/project/claude-settings.local.template.json. Run from anywhere: tests/scripts/settings-template.test.sh
# Exits 0 when every case passes; prints one line per failure.
. "$(dirname "$0")/lib.sh"
template="$kit/templates/project/claude-settings.local.template.json"
[ -f "$template" ] || { echo "✗ $template missing"; exit 1; }

# S1 · The template is valid JSON as shipped (placeholders sit inside strings)
if command -v python3 >/dev/null; then
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$template" 2>/dev/null || fail "S1 the template is not valid JSON"
else
  echo "(S1 JSON validity not checked: no python3)" >&2
fi

# The allow list, one rule per line
allow="$(awk '/"allow": \[/ { on = 1; next } on && /\]/ { exit } on' "$template" | sed 's/^ *"//; s/",\{0,1\} *$//')"
[ -n "$allow" ] || fail "S2 no allow list found"

# S3 · No allow rule for a program with writing or executing forms, nor a blanket Bash rule.
# Read-only commands need no rule: Claude Code runs its built-in read-only set without asking.
for p in sed sort find tee awk xargs python python3 node perl ruby bash sh zsh npx cp mv rm chmod curl wget dd; do
  printf '%s\n' "$allow" | grep -qE "^Bash\\($p( |\\*|:|\\))" && fail "S3 allow rule for '$p' lets its writing or executing forms through"
done
printf '%s\n' "$allow" | grep -qxE 'Bash|Bash\(\*\)' && fail "S3 blanket Bash allow rule"

# S4 · The kit's own scripts that Claude runs as routine are allowed, on the project's roadmap only
# (a wildcard would let --write rewrite any file with markers, outside every Edit rule)
for m in --check --write; do
  printf '%s\n' "$allow" | grep -qxF "Bash(~/.claude/jacquard/scripts/roadmap-index.sh $m {{LOCAL_FOLDER}}/docs/roadmap.md)" || fail "S4 no exact allow rule for roadmap-index.sh $m"
done
printf '%s\n' "$allow" | grep -q 'roadmap-index\.sh.*\*' && fail "S4 roadmap-index.sh rule with a wildcard"
# Every rule for a kit script the rules spell is matched by the spelling in core/
grep -qF '~/.claude/jacquard/scripts/roadmap-index.sh --write <local>/docs/roadmap.md' "$kit/core/docs-system.md" || fail "S4b core/docs-system.md spells roadmap-index.sh differently from the allow rule"
grep -qF '~/.claude/jacquard/scripts/roadmap-index.sh --write {{LOCAL_FOLDER}}/docs/roadmap.md' "$kit/templates/docs/roadmap.md" || fail "S4c the roadmap template spells roadmap-index.sh differently from the allow rule"

# S4d · structure-check.sh reads only, so it runs without asking, bare or with arguments; no looser spelling
# (a rule without the space, structure-check.sh*, would also match any other file whose name starts the same)
for r in "Bash(~/.claude/jacquard/scripts/structure-check.sh)" "Bash(~/.claude/jacquard/scripts/structure-check.sh *)"; do
  printf '%s\n' "$allow" | grep -qxF "$r" || fail "S4d no allow rule $r"
done
[ "$(printf '%s\n' "$allow" | grep -c 'structure-check')" = 2 ] || fail "S4d structure-check.sh must have exactly the two allow rules"
# Every path the kit spells for it is the one the rules allow, never behind an interpreter or a VAR= prefix
spelled="$kit/core $kit/roles $kit/skills $kit/templates $kit/agents $kit/tests/core $kit/tests/commands $kit/tests/roles"
# shellcheck disable=SC2086
grep -rhoE '[^ `(]*scripts/structure-check\.sh' $spelled 2>/dev/null |
  grep -vxF '~/.claude/jacquard/scripts/structure-check.sh' | grep -q . && fail "S4e a kit file spells structure-check.sh with a path the allow rules do not match"
# shellcheck disable=SC2086
grep -rhoE '(sh|bash|zsh|env|[A-Za-z_][A-Za-z0-9_]*=[^ `]*) +[^ `]*scripts/structure-check\.sh' $spelled 2>/dev/null | grep -q . &&
  fail "S4e a kit file runs structure-check.sh behind an interpreter or a variable, which the allow rules do not match"

# S4f · No allow rule covers a kit script beyond the exact ones above (a folder-wide rule would also let
# roadmap-index.sh --write rewrite any file)
printf '%s\n' "$allow" | grep '\.claude/jacquard/' | grep -vxF \
  -e 'Bash(~/.claude/jacquard/scripts/away-guard.sh on {{LOCAL_FOLDER}} *)' \
  -e 'Bash(~/.claude/jacquard/scripts/away-guard.sh off {{LOCAL_FOLDER}})' \
  -e 'Bash(~/.claude/jacquard/scripts/roadmap-index.sh --check {{LOCAL_FOLDER}}/docs/roadmap.md)' \
  -e 'Bash(~/.claude/jacquard/scripts/roadmap-index.sh --write {{LOCAL_FOLDER}}/docs/roadmap.md)' \
  -e 'Bash(~/.claude/jacquard/scripts/structure-check.sh)' \
  -e 'Bash(~/.claude/jacquard/scripts/structure-check.sh *)' \
  -e 'Bash(~/.claude/jacquard/scripts/cloud.sh status)' \
  -e 'Bash(~/.claude/jacquard/scripts/personal-sync.sh)' \
  -e "Bash(~/.claude/jacquard/scripts/personal-sync.sh *)" \
  -e 'Bash(~/.claude/jacquard/scripts/push-guard.sh install)' \
  -e 'Bash(~/.claude/jacquard/scripts/push-guard.sh check)' | grep -q . && fail "S4f an allow rule for a kit script outside the exact list"

# S4h · personal-sync.sh is the one allowed way to back up the personal layer: bare or with its message, no looser
# spelling (personal-sync.sh* would match any file whose name starts the same); core spells it the same way
for r in "Bash(~/.claude/jacquard/scripts/personal-sync.sh)" "Bash(~/.claude/jacquard/scripts/personal-sync.sh *)"; do
  printf '%s\n' "$allow" | grep -qxF "$r" || fail "S4h no allow rule $r"
done
[ "$(printf '%s\n' "$allow" | grep -c 'personal-sync')" = 2 ] || fail "S4h personal-sync.sh must have exactly the two allow rules"
grep -qF '`~/.claude/jacquard/scripts/personal-sync.sh' "$kit/core/git.md" || fail "S4h core/git.md does not spell personal-sync.sh as the allow rules do"

# S4g · cloud.sh: only `status` runs without asking (it fetches and counts); `prepare` pushes and `land` commits,
# so they keep the confirmation; core spells the allowed form exactly
[ "$(printf '%s\n' "$allow" | grep -c 'cloud\.sh')" = 1 ] || fail "S4g cloud.sh must have exactly one allow rule, for status"
grep -qF '`~/.claude/jacquard/scripts/cloud.sh status`' "$kit/core/git.md" || fail "S4g core/git.md spells cloud.sh status differently from the allow rule"

# S5 · The local folder can be written from the terminal through its link
grep -qF '"additionalDirectories": ["{{PERSONAL_PROJECT_FOLDER}}"]' "$template" || fail "S5 no additionalDirectories entry for the personal project folder"

# S6 · The deny rule that keeps personal settings out of git stays, and does not catch the template's own name
grep -qF '"Bash(git add *settings.local.json*)"' "$template" || fail "S6 deny rule for git add *settings.local.json* is missing"
case "$(basename "$template")" in *settings.local.json*) fail "S6 the template's name matches its own deny rule";; esac

# S7 · The installed kit is a trust boundary: no file tool may change it (its scripts run from hooks and allow rules).
# Claude Code consults only Edit(path) for writes; a Write(path) rule is accepted but never matched.
grep -qF '"Edit(~/.claude/jacquard/**)"' "$template" || fail "S7 no Edit deny for ~/.claude/jacquard/**"
awk '/"deny": \[/ { on = 1; next } on && /\]/ { exit } on' "$template" | grep -qF '"Edit(~/.claude/jacquard/**)"' || fail "S7 the Edit rule for ~/.claude/jacquard/** must be in deny"
grep -qE '"(Write|MultiEdit|NotebookEdit)\(' "$template" && fail "S7 a Write/MultiEdit/NotebookEdit path rule is never consulted: use Edit(path)"

# S8 · Git with remotes: fetching from origin runs without asking, but no form that runs a program (--upload-pack);
# pushing a work branch is allowed only where the project fills the push placeholder (its own origin); the main
# branches, HEAD, @, every branch, tags and deleting remote branches are denied in every form the rules can see.
# Claude Code checks deny, then ask, then allow: a broad ask rule would hide the narrow allows, so none is left.
ask="$(awk '/"ask": \[/ { on = 1; next } on && /\]/ { exit } on' "$template" | sed 's/^ *"//; s/",\{0,1\} *$//')"
deny="$(awk '/"deny": \[/ { on = 1; next } on && /\]/ { exit } on' "$template" | sed 's/^ *"//; s/",\{0,1\} *$//')"
for r in "Bash(git fetch)" "Bash(git fetch origin)" "Bash(git fetch origin *)"; do
  printf '%s\n' "$allow" | grep -qxF "$r" || fail "S8 no allow rule $r"
done
printf '%s\n' "$allow" "$ask" | grep -qxE 'Bash\(git (fetch|push) ?\*\)' && fail "S8 a blanket fetch or push rule (it would hide or widen the narrow ones)"
printf '%s\n' "$allow" | grep -q '^Bash(git push' && fail "S8 push is allowed only through the project's push placeholder"
printf '%s\n' "$allow" | grep -q '^{{PUSH_ALLOW_RULES' || fail "S8 no push placeholder in allow"
for r in "Bash(git *--upload-pack*)" "Bash(git *--receive-pack*)" "Bash(git *--exec*)" \
  "Bash(git push)" "Bash(git push origin)" "Bash(git push -u origin)" \
  "Bash(git push * main)" "Bash(git push * main *)" "Bash(git push *:main*)" "Bash(git push *heads/main*)" \
  "Bash(git push * master)" "Bash(git push * master *)" "Bash(git push *:master*)" "Bash(git push *heads/master*)" \
  "Bash(git push * HEAD)" "Bash(git push * HEAD *)" "Bash(git push * @)" "Bash(git push * @ *)" \
  "Bash(git push *--all*)" "Bash(git push *--tags*)" \
  "Bash(git push *--delete*)" "Bash(git push * -d *)" "Bash(git push * -d)" "Bash(git push * :*)" \
  "Bash(git push * -*)" "Bash(git push *refs/*)" "Bash(git push *'*)" 'Bash(git push *\"*)' "Bash(git fetch *--u*)" \
  "Bash(git fetch * +*)" "Bash(git fetch *:*)"; do
  printf '%s\n' "$deny" | grep -qxF "$r" || fail "S8 no deny rule $r"
done
# S8b · git takes any unique abbreviation of a long option and bundles short ones (--m is --mirror, -qf forces), so
# after the remote no option at all goes through; -u before the remote stays allowed
printf '%s\n' "$allow" | grep -q '^{{PUSH_ALLOW_RULES[^}]*private' || fail "S8b the push placeholder must say the origin is the user's own and private"

# S9 · Allowed pushes and fetches never prompt, so the PermissionRequest hook never sees them: bash-guard.sh runs before
# every Bash command, in Present and in Away
grep -qF '"matcher": "Bash", "hooks": [{ "type": "command", "command": "\"$HOME/.claude/jacquard/scripts/bash-guard.sh\" \"{{LOCAL_FOLDER}}\""' "$template" || fail "S9 no PreToolUse Bash hook running bash-guard.sh"

# S10 · The push guard: Claude's commands carry JACQUARD_AGENT (the stub tells Claude's pushes from the user's by it);
# installing the stub is one exact allowed command; protected pushes go only through protected-push.sh, which always asks
python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1])).get("env", {}).get("JACQUARD_AGENT") == "1" else 1)' "$template" 2>/dev/null ||
  fail "S10 env must set JACQUARD_AGENT to 1"
for r in 'Bash(~/.claude/jacquard/scripts/push-guard.sh install)' 'Bash(~/.claude/jacquard/scripts/push-guard.sh check)'; do
  printf '%s\n' "$allow" | grep -qxF "$r" || fail "S10 no exact allow rule $r"
done
[ "$(printf '%s\n' "$allow" | grep -c 'push-guard')" = 2 ] || fail "S10 push-guard.sh must have exactly the two allow rules (install, check)"
printf '%s\n' "$ask" | grep -qxF 'Bash(~/.claude/jacquard/scripts/protected-push.sh *)' || fail "S10 no ask rule for protected-push.sh"
printf '%s\n' "$allow" | grep -q 'protected-push' && fail "S10 no allow rule may cover protected-push.sh"
grep -qF '`~/.claude/jacquard/scripts/protected-push.sh' "$kit/core/git.md" || fail "S10 core/git.md does not spell protected-push.sh as the ask rule does"

# S11 · What would turn the guard off is denied: its markers, husky's switch, other git settings, redirects into git's
# files, the hook files themselves and the Away marker; editing Claude Code's settings asks
for r in 'Bash(git push *--no-v*)' 'Bash(git push *$*)' 'Bash(git push *`*)' 'Bash(git push *{*)' 'Bash(git *<(*)' 'Bash(git *>(*)' \
  'Bash(env -i*)' 'Bash(env - *)' 'Bash(*CLAUDECODE*)' 'Bash(*CLAUDE_CODE_ENTRYPOINT*)' 'Bash(*JACQUARD_AGENT*)' 'Bash(*HUSKY*)' \
  'Bash(*hooksPath*)' 'Bash(*GIT_CONFIG*)' 'Bash(*HOME=*)' 'Bash(*>*.git/*)' 'Bash(*>*gitconfig*)' 'Bash(*>*config/git*)' \
  'Edit(/.git/**)' 'Edit(/.husky/pre-push)' 'Edit(/.husky/_/**)' 'Edit(/{{LOCAL_FOLDER}}/away/.away-active)'; do
  printf '%s\n' "$deny" | grep -qxF "$r" || fail "S11 no deny rule $r"
done
printf '%s\n' "$ask" | grep -qxF 'Edit(/.claude/**)' || fail "S11 editing .claude/ must ask"

finish "settings-template"
