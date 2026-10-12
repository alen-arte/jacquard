#!/usr/bin/env bash
# Tests for templates/project/claude-settings.local.template.json. Run from anywhere: tests/scripts/settings-template.test.sh
# Exits 0 when every case passes; prints one line per failure.
here="$(cd "$(dirname "$0")" && pwd)"
template="$here/../../templates/project/claude-settings.local.template.json"
[ -f "$template" ] || { echo "✗ $template missing"; exit 1; }
fails=0
fail() { echo "✗ $1"; fails=$((fails + 1)); }

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
grep -qF '~/.claude/jacquard/scripts/roadmap-index.sh --write <local>/docs/roadmap.md' "$here/../../core/docs-system.md" || fail "S4b core/docs-system.md spells roadmap-index.sh differently from the allow rule"

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

[ "$fails" = 0 ] && echo "✓ settings-template: all cases pass" && exit 0
exit 1
