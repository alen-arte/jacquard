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
# The project root: the hooks get CLAUDE_PROJECT_DIR (where the session started); the Bash tool may not,
# and may sit in a subfolder: then the nearest folder up that holds <local>/index.md, else the git root.
root="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$root" ]; then
  d="$(pwd -P)"
  while [ -n "$d" ] && [ ! -f "$d/$local_dir/index.md" ]; do [ "$d" = / ] && d="" || d="$(dirname "$d")"; done
  root="${d:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
fi
case "$local_dir" in /*) dir="$local_dir/away" ;; *) dir="$root/$local_dir/away" ;; esac
marker="$dir/.away-active"

# Hooks get their input on stdin, and its session id decides; on and off use the environment's.
input=""
case "$cmd" in permission|elicitation|session-start) input="$(cat)" ;; esac
# First occurrence of a string field: the top-level ones come before tool_input.
field() { printf '%s' "$input" | tr '\n' ' ' | grep -o "\"$1\" *: *\"[^\"]*\"" | head -n 1 | sed 's/.*: *"\(.*\)"$/\1/'; }
session="$(field session_id)"; session="${session:-$CLAUDE_CODE_SESSION_ID}"
mine() { [ -n "$session" ] && [ -f "$marker" ] && [ "$(cat "$marker")" = "$session" ]; }

case "$cmd" in
  on)
    [ -n "$CLAUDE_CODE_SESSION_ID" ] || { echo "✗ away-guard: CLAUDE_CODE_SESSION_ID is not set (older Claude Code?): Away runs without the guard" >&2; exit 1; }
    if [ -f "$marker" ] && ! mine; then
      echo "away-guard: another session's Away marker was here; that session loses its guard" >&2
    fi
    mkdir -p "$dir" && rm -f "$marker" && printf '%s\n' "$CLAUDE_CODE_SESSION_ID" > "$marker" || exit 1
    echo "✓ Away guard on for this session" ;;
  off)
    if mine; then rm -f "$marker"; echo "✓ Away guard off"; else echo "✓ Away guard was not on for this session"; fi ;;
  permission)
    # Never its own switch-off (a bare Bash call, nothing chained): if that prompts, the user who ended Away answers it.
    if [ "$(field tool_name)" = Bash ]; then
      case "$(field command)" in
        *[\;\&\|\`\$\(\)\<\>]*) ;;
        *away-guard.sh\ off\ *|*away-guard.sh\"\ off\ *) exit 0 ;;
      esac
    fi
    mine && cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "deny",
      "message": "Away mode is on and nobody is here to answer this permission prompt, so it was denied automatically. Do not retry it or wait for an answer: use a safe equivalent the settings already allow, or park the step in the Away journal (what it needed and why) and continue with other work. If the user is actually back, ask them to type /back, which turns this guard off."
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
