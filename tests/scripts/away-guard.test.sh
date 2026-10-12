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
is_json() { command -v python3 >/dev/null || return 0; printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; }

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

[ "$fails" = 0 ] && echo "✓ away-guard: all cases pass" && exit 0
echo "✗ away-guard: $fails failing"; exit 1
