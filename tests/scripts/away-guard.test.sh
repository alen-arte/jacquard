#!/bin/sh
# Tests for scripts/away-guard.sh. Run from anywhere: tests/scripts/away-guard.test.sh
# Exits 0 when every case passes; prints one line per failure.
here="$(cd "$(dirname "$0")" && pwd)"
guard="$here/../../scripts/away-guard.sh"
[ -x "$guard" ] || { echo "✗ $guard missing or not executable"; exit 1; }

tmp="$(mktemp -d)" || exit 1
trap 'rm -rf "$tmp"' EXIT
export CLAUDE_PROJECT_DIR="$tmp"
marker="$tmp/.local/away/.away-active"
fails=0
fail() { echo "✗ $1"; fails=$((fails + 1)); }

# run <session id or "-"> <subcommand> [stdin]: output in $out, status in $st
run() {
  if [ "$1" = "-" ]; then
    out="$(printf '%s' "${3:-}" | env -u CLAUDE_CODE_SESSION_ID "$guard" "$2" .local 2>/dev/null)"; st=$?
  else
    out="$(printf '%s' "${3:-}" | CLAUDE_CODE_SESSION_ID="$1" "$guard" "$2" .local 2>/dev/null)"; st=$?
  fi
}
is_json() { command -v python3 >/dev/null || { echo "(JSON validity not checked: no python3)" >&2; return 0; }; printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; }

# Off by default: nothing is denied
run s1 permission '{"session_id":"s1"}'
[ "$st" = 0 ] && [ -z "$out" ] || fail "C1 no marker: permission must print nothing and exit 0"

# Turning on needs a session id
run - on
[ "$st" != 0 ] && [ ! -e "$marker" ] || fail "C2 on without a session id must fail and write no marker"

# On: marker holds this session's id
run s1 on
[ "$st" = 0 ] && [ "$(cat "$marker" 2>/dev/null)" = s1 ] || fail "C3 on must write the session id to the marker"

# Same session: permission prompt denied with a message telling Claude to park
run s1 permission '{"session_id":"s1","tool_name":"Bash"}'
case "$out" in *'"hookEventName": "PermissionRequest"'*'"behavior": "deny"'*park*) ;; *) fail "C4 same session: permission must be denied with a park message";; esac
is_json "$out" || fail "C4b deny output must be valid JSON"
case "$out" in *'"interrupt": true'*) fail "C4c deny must not interrupt Claude";; esac

# Another session in the same project is untouched
run s2 permission '{"session_id":"s2"}'
[ "$st" = 0 ] && [ -z "$out" ] || fail "C5 other session: permission must print nothing"

# MCP elicitation declined in the Away session only
run s1 elicitation '{"session_id":"s1","mcp_server_name":"x"}'
case "$out" in *'"hookEventName": "Elicitation"'*'"action": "decline"'*) ;; *) fail "C6 same session: elicitation must be declined";; esac
is_json "$out" || fail "C6b decline output must be valid JSON"
run s2 elicitation '{"session_id":"s2"}'
[ -z "$out" ] || fail "C7 other session: elicitation must print nothing"

# Without the env variable, the session id comes from the hook input
run - permission '{"session_id":"s1","tool_input":{"command":"echo \"session_id\":\"s2\""}}'
case "$out" in *'"behavior": "deny"'*) ;; *) fail "C8 id from hook input: must deny for the marker's session";; esac
run - permission '{"tool_input":{"command":"echo \"session_id\":\"s1\""},"session_id":"s2"}'
[ -z "$out" ] || fail "C9 an id quoted inside tool input must not count as the session id"

# Session start: compaction keeps Away on; another session starting leaves it alone
run s1 session-start '{"session_id":"s1","source":"compact"}'
[ -e "$marker" ] || fail "C10 compaction must keep the marker"
run s2 session-start '{"session_id":"s2","source":"startup"}'
[ -e "$marker" ] || fail "C11 a new session elsewhere must keep another session's marker"
[ -z "$out" ] || fail "C11b session-start must print nothing (stdout becomes context)"

# Resuming the Away session starts in Present: marker cleared
run s1 session-start '{"session_id":"s1","source":"resume"}'
[ ! -e "$marker" ] || fail "C12 resume of the Away session must clear the marker"

# Off only clears this session's marker
run s1 on
run s2 off
[ -e "$marker" ] || fail "C13 off from another session must keep the marker"
run s1 off
[ "$st" = 0 ] && [ ! -e "$marker" ] || fail "C14 off must clear this session's marker"
run s1 off
[ "$st" = 0 ] || fail "C15 off with no marker must succeed"

# Misuse
out="$(CLAUDE_CODE_SESSION_ID=s1 "$guard" permission 2>/dev/null)"; st=$?
[ "$st" = 2 ] && [ -z "$out" ] || fail "C16 a missing local folder must exit 2 and print nothing"
out="$(CLAUDE_CODE_SESSION_ID=s1 "$guard" on ../x 2>/dev/null)"; st=$?
[ "$st" = 2 ] && [ ! -e "$tmp/../x/away/.away-active" ] || fail "C17 a local folder with .. must be refused"

# The guard never denies its own switch-off (a misspelt or unallowed off must still reach the user)
run s1 on
run s1 permission '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"~/.claude/jacquard/scripts/away-guard.sh off .local"}}'
[ -z "$out" ] || fail "C18 the guard's own off command must not be denied"
for inp in '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"git commit -m \"away-guard.sh: turn off on /back\""}}' \
           '{"session_id":"s1","tool_name":"Read","tool_input":{"file_path":"scripts/away-guard.sh","offset":10}}' \
           '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"bash -c \"true; echo away-guard.sh off x\""}}' \
           '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"~/.claude/jacquard/scripts/away-guard.sh off .jacquard; git push"}}' \
           '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"~/.claude/jacquard/scripts/away-guard.sh off .local \\"x\\"; git push"}}' \
           '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"~/.claude/jacquard/scripts/away-guard.sh off .local\ngit push"}}'; do
  run s1 permission "$inp"
  case "$out" in *'"behavior": "deny"'*) ;; *) fail "C18b only the bare off command is exempt: $inp";; esac
done

# The hook input's session id wins over the environment, and a nested session_id does not count
run s2 permission '{"session_id":"s1","tool_input":{"session_id":"s2"}}'
case "$out" in *'"behavior": "deny"'*) ;; *) fail "C19 hook input session_id (first, top level) decides, not a nested one or the env";; esac

# Clear and fork start in Present
run s1 session-start '{"session_id":"s1","source":"clear"}'
[ ! -e "$marker" ] || fail "C20 /clear of the Away session must clear the marker"
run s1 on
run s1 session-start '{"session_id":"s1","source":"fork"}'
[ ! -e "$marker" ] || fail "C21 a fork of the Away session must clear the marker"

# A second Away elsewhere warns before taking over
run s1 on
err="$(CLAUDE_CODE_SESSION_ID=s2 "$guard" on .local 2>&1 >/dev/null)"
case "$err" in *"another session"*) ;; *) fail "C22 on over another session's marker must warn";; esac
run s2 off

# Without CLAUDE_PROJECT_DIR, on/off resolve the repo root, not the current folder
repo="$tmp/repo"; mkdir -p "$repo/sub" "$repo/.local" && git init -q "$repo" && echo x > "$repo/.local/index.md"
( cd "$repo/sub" && env -u CLAUDE_PROJECT_DIR CLAUDE_CODE_SESSION_ID=s1 "$guard" on .local >/dev/null 2>&1 )
[ -f "$repo/.local/away/.away-active" ] && [ ! -e "$repo/sub/.local" ] || fail "C23 on from a subfolder must write the marker at the repo root"
( cd "$repo/sub" && env -u CLAUDE_PROJECT_DIR CLAUDE_CODE_SESSION_ID=s1 "$guard" off .local >/dev/null 2>&1 )
[ ! -e "$repo/.local/away/.away-active" ] || fail "C24 off from a subfolder must clear the marker at the repo root"

# Started in a subfolder that holds the local folder (a monorepo package): that folder, not the git root
mkdir -p "$repo/pkg/.local" && echo x > "$repo/pkg/.local/index.md"
( cd "$repo/pkg" && env -u CLAUDE_PROJECT_DIR CLAUDE_CODE_SESSION_ID=s1 "$guard" on .local >/dev/null 2>&1 )
[ -f "$repo/pkg/.local/away/.away-active" ] || fail "C27 on must use the nearest folder that holds <local>/index.md"
( cd "$repo/pkg" && env -u CLAUDE_PROJECT_DIR CLAUDE_CODE_SESSION_ID=s1 "$guard" off .local >/dev/null 2>&1 )

# Outside any project (no <local>/index.md up the tree, no CLAUDE_PROJECT_DIR), on and off refuse
out="$(cd "$tmp" && env -u CLAUDE_PROJECT_DIR CLAUDE_CODE_SESSION_ID=s1 "$guard" on .nowhere 2>&1)"; st=$?
[ "$st" = 1 ] && [ ! -e "$tmp/.nowhere" ] || fail "C28 on outside a project must fail and write nothing"

# An absolute local folder is used as is; a symlink at the marker is replaced, not followed
abs="$tmp/abs"; target="$tmp/target.txt"; echo keep > "$target"
mkdir -p "$abs/away" && ln -s "$target" "$abs/away/.away-active"
CLAUDE_CODE_SESSION_ID=s1 "$guard" on "$abs" >/dev/null 2>&1
[ "$(cat "$target")" = keep ] && [ ! -L "$abs/away/.away-active" ] && [ "$(cat "$abs/away/.away-active")" = s1 ] || fail "C25 on must replace a symlinked marker without writing through it"

# Every on/off the rules spell matches an allow rule of the permissions template exactly
kit="$here/../.."
spelled="$(grep -rhoE '[~$A-Za-z/._{}-]*away-guard\.sh (on|off) <local>' "$kit/core" "$kit/skills" | sort -u)"
[ -n "$spelled" ] || fail "C26 no on/off spelling found in core/ or skills/"
grep -q 'away-guard.sh on' "$kit/templates/project/settings.local.json" || fail "C26 the permissions template has no guard rules (template change not committed?)"
printf '%s\n' "$spelled" | while IFS= read -r c; do
  rule="Bash($(printf '%s' "$c" | sed 's/<local>/{{LOCAL_FOLDER}}/'))"
  grep -qF "\"$rule\"" "$kit/templates/project/settings.local.json" || echo "✗ C26 no allow rule for: $c"
done | grep . && fails=$((fails + 1))

[ "$fails" = 0 ] && echo "✓ away-guard: all cases pass" && exit 0
echo "✗ away-guard: $fails failing"; exit 1
