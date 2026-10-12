#!/bin/sh
# Jacquard Away guard: while a session is in Away, nobody is there to answer a
# permission prompt or an MCP server's question, so the block would stall.
# The guard answers "no" for that session only, and tells Claude to park the step.
# It only ever denies or declines; it never allows anything.
#
# Usage: away-guard.sh <on|off|permission|elicitation|session-start> <local folder> [HH:MM]
#   on [HH:MM]     run by /away (after the OK) and /away-resume, with the block's end time if it has one
#   off            run by /back and the end of the block
#   permission     PermissionRequest hook: deny with a park message
#   elicitation    Elicitation hook: decline
#   session-start  SessionStart hook: a resumed or cleared Away session starts in Present
# The marker <project>/<local folder>/away/.away-active holds the Away session's id and, on its
# second line, when the guard expires (epoch seconds): the end time plus a margin, or a default
# when the block has no end time, so a user who comes back without /back is not left with a guard
# that denies every prompt. A marker without that line (kit 0.2.7) never expires.
margin=3600            # after the end time
no_end_time=43200      # a block with no end time: 12 h from on
cmd="$1"; local_dir="$2"; end="$3"
case "$cmd" in on|off|permission|elicitation|session-start) ;; *)
  echo "usage: away-guard.sh <on|off|permission|elicitation|session-start> <local folder> [HH:MM]" >&2; exit 2 ;; esac
[ -n "$local_dir" ] || { echo "away-guard: missing local folder" >&2; exit 2; }
[ $# -le 3 ] && { [ -z "$end" ] || [ "$cmd" = on ]; } || { echo "away-guard: only on takes an end time, and nothing after it" >&2; exit 2; }
case "$end" in ""|[01][0-9]:[0-5][0-9]|2[0-3]:[0-5][0-9]) ;; *) echo "away-guard: end time must be HH:MM (00:00–23:59)" >&2; exit 2 ;; esac
case "/$local_dir/" in */../*) echo "away-guard: local folder must not contain .." >&2; exit 2 ;; esac
# The project root: the hooks get CLAUDE_PROJECT_DIR (where the session started); the Bash tool may not,
# and may sit in a subfolder: then the nearest folder up that holds <local>/index.md. None: refuse.
root="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$root" ]; then
  d="$(pwd -P)"
  while [ -n "$d" ] && [ ! -f "$d/$local_dir/index.md" ]; do [ "$d" = / ] && d="" || d="$(dirname "$d")"; done
  root="$d"
fi
case "$local_dir" in
  /*) dir="$local_dir/away" ;;
  *) [ -n "$root" ] || { echo "✗ away-guard: no $local_dir/index.md here or above $(pwd -P), and no CLAUDE_PROJECT_DIR" >&2; exit 1; }
     dir="$root/$local_dir/away" ;;
esac
marker="$dir/.away-active"

# Hooks get their input on stdin, and its session id decides; on and off use the environment's.
input=""
case "$cmd" in permission|elicitation|session-start) input="$(cat)" ;; esac
# First occurrence of a string field: the top-level ones come before tool_input.
field() { printf '%s' "$input" | tr '\n' ' ' | grep -o "\"$1\" *: *\"[^\"]*\"" | head -n 1 | sed 's/.*: *"\(.*\)"$/\1/'; }
session="$(field session_id)"; session="${session:-$CLAUDE_CODE_SESSION_ID}"
owner() { [ -n "$session" ] && [ -f "$marker" ] && [ "$(head -n 1 "$marker")" = "$session" ]; }
# Expired only when the second line is a number in the past; anything else keeps the guard on (fail safe).
expired() { exp="$(sed -n 2p "$marker")"; case "$exp" in ""|*[!0-9]*) return 1 ;; esac; [ "$(date +%s)" -gt "$exp" ]; }
# This session's guard is on: an expired marker is cleared and no longer counts.
mine() { owner || return 1; expired || return 0; rm -f "$marker"; return 1; }
# Epoch seconds of the next HH:MM (today, else tomorrow), from date's own fields: portable (no date -d)
next_time() {
  set -- $(date '+%s %H %M %S') "${end%:*}" "${end#*:}"
  # Two-digit fields lose a leading zero, so the shell does not read them as octal
  target=$(( $1 - (${2#0} * 3600 + ${3#0} * 60 + ${4#0}) + (${5#0} * 3600 + ${6#0} * 60) ))
  [ "$target" -gt "$1" ] || target=$((target + 86400))
  echo "$target"
}

case "$cmd" in
  on)
    [ -n "$CLAUDE_CODE_SESSION_ID" ] || { echo "✗ away-guard: CLAUDE_CODE_SESSION_ID is not set (older Claude Code?): Away runs without the guard" >&2; exit 1; }
    if [ -f "$marker" ] && ! mine; then
      echo "away-guard: another session's Away marker was here; that session loses its guard" >&2
    fi
    if [ -n "$end" ]; then expires=$(( $(next_time) + margin )); else expires=$(( $(date +%s) + no_end_time )); fi
    mkdir -p "$dir" && rm -f "$marker" && printf '%s\n%s\n' "$CLAUDE_CODE_SESSION_ID" "$expires" > "$marker" || exit 1
    echo "✓ Away guard on for this session ($marker), until $(date -d "@$expires" '+%H:%M' 2>/dev/null || date -r "$expires" '+%H:%M' 2>/dev/null)" ;;
  off)
    if owner; then rm -f "$marker"; echo "✓ Away guard off"; else echo "✓ Away guard was not on for this session ($marker)"; fi ;;
  permission)
    # Never its own switch-off, spelled exactly as the rules do (no escapes, nothing chained):
    # if that prompts, the user who ended Away answers it.
    if [ "$(field tool_name)" = Bash ]; then
      raw="$(printf '%s' "$input" | tr '\n' ' ' | grep -o '"command" *: *"[^"\\]*"' | head -n 1 | sed 's/^"command" *: *"//; s/"$//')"
      case "$raw" in "~/.claude/jacquard/scripts/away-guard.sh off $local_dir"|"$HOME/.claude/jacquard/scripts/away-guard.sh off $local_dir") exit 0 ;; esac
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
