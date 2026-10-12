#!/bin/sh
# Jacquard Away guard: while a session is in Away, nobody is there to answer a
# permission prompt or an MCP server's question, so the block would stall.
# The guard answers "no" for that session only, and tells Claude to park the step.
# It only ever denies or declines; it never allows anything.
#
# Usage: away-guard.sh <on|off|permission|elicitation|session-start> <local folder>
#   on / off       run by /away (after the OK), /away-resume and /back
#   permission     PermissionRequest hook: deny with a park message
#   elicitation    Elicitation hook: decline
#   session-start  SessionStart hook: a resumed or cleared Away session starts in Present
# The marker <project>/<local folder>/away/.away-active holds the Away session's id.
cmd="$1"; local_dir="$2"
case "$cmd" in on|off|permission|elicitation|session-start) ;; *)
  echo "usage: away-guard.sh <on|off|permission|elicitation|session-start> <local folder>" >&2; exit 2 ;; esac
[ -n "$local_dir" ] || { echo "away-guard: missing local folder" >&2; exit 2; }
case "/$local_dir/" in */../*) echo "away-guard: local folder must not contain .." >&2; exit 2 ;; esac
case "$local_dir" in /*) dir="$local_dir/away" ;; *) dir="${CLAUDE_PROJECT_DIR:-$PWD}/$local_dir/away" ;; esac
marker="$dir/.away-active"

# Hooks get their input on stdin; the session id comes from the environment, else from that input.
input=""
case "$cmd" in permission|elicitation|session-start) input="$(cat)" ;; esac
field() { printf '%s' "$input" | tr '\n' ' ' | sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p"; }
session="${CLAUDE_CODE_SESSION_ID:-$(field session_id)}"
mine() { [ -n "$session" ] && [ -f "$marker" ] && [ "$(cat "$marker")" = "$session" ]; }

case "$cmd" in
  on)
    [ -n "$CLAUDE_CODE_SESSION_ID" ] || { echo "✗ away-guard: CLAUDE_CODE_SESSION_ID is not set (older Claude Code?): Away runs without the guard" >&2; exit 1; }
    mkdir -p "$dir" && printf '%s\n' "$CLAUDE_CODE_SESSION_ID" > "$marker" || exit 1
    echo "✓ Away guard on for this session" ;;
  off)
    if mine; then rm -f "$marker"; echo "✓ Away guard off"; else echo "✓ Away guard was not on for this session"; fi ;;
  permission)
    mine && cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "deny",
      "message": "Away mode is on and nobody is here to answer this permission prompt, so it was denied automatically. Do not retry it or wait for an answer: use a safe equivalent the settings already allow, or park the step in the Away journal (what it needed and why) and continue with other work."
    }
  }
}
EOF
    ;;
  elicitation)
    mine && cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "Elicitation",
    "action": "decline"
  }
}
EOF
    ;;
  session-start)
    [ "$(field source)" = compact ] || { mine && rm -f "$marker"; } ;;
esac
exit 0
