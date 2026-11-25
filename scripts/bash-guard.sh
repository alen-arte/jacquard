#!/bin/sh
# Jacquard PreToolUse hook on Bash, in Present and in Away: the pushes allow rules let run without a prompt reach them
# only in their one plain form, with the push guard in place. One rule set for both modes; Away only answers "no"
# where Present asks.
# Usage: bash-guard.sh <local folder>   (the hook input on stdin; prints a decision, or nothing to leave it to the rules)
#   - read-only commands (grep, rg, git log/diff/show/status) and `git commit -m`, with no shell operators: nothing
#   - `git push [-u] origin <branch>` and nothing else: Away denies; Present runs push-guard.sh check, and asks when
#     the guard is not in place (the pre-push stub then decides what goes up)
#   - any other command that mentions push once quotes and backslashes are gone, or puts $ or a backtick next to git:
#     Away denies, Present asks
#   - a fetch: Away denies
here="$(cd "$(dirname "$0")" && pwd)"
[ $# = 1 ] && [ -n "$1" ] || { echo "usage: bash-guard.sh <local folder>" >&2; exit 2; }
local_dir="$1"
input="$(cat)"
# The command as JSON wrote it (escapes kept): its first "command" field, which only tool_input has
cmd="$(printf '%s' "$input" | tr '\n' ' ' | grep -oE '"command" *: *"([^"\\]|\\.)*"' | head -n 1 | sed -E 's/^"command" *: *"//; s/"$//')"
away=0; printf '%s' "$input" | sh "$here/away-guard.sh" active "$local_dir" 2>/dev/null && away=1

# decide <deny|ask> <reason>: the hook's answer (the reason carries no quotes or backslashes)
decide() {
  r="$(printf '%s' "$2" | tr -d '"\\' | tr '\n' ' ')"
  printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "PreToolUse",\n    "permissionDecision": "%s",\n    "permissionDecisionReason": "%s"\n  }\n}\n' "$1" "$r"
  exit 0
}
park="Away mode is on: Away never pushes or fetches (core/git.md › Push). Do not retry it: park the step in the Away journal and continue with other work. If the user is actually back, ask them to type /back."

# Escaped quotes are plain quotes in the command; any other escape (a line break, a backslash) is not simple
bare="$(printf '%s' "$cmd" | sed 's/\\"//g')"
case "$bare" in *'\'*|*[';&|$`<>()']*) simple=0 ;; *) simple=1 ;; esac
if [ "$simple" = 1 ] && printf '%s\n' "$bare" | grep -Eq '^(grep|rg|git (log|diff|show|status|commit -m))( |$)'; then exit 0; fi

if printf '%s\n' "$cmd" | grep -Eqx 'git push( -u)? origin [A-Za-z0-9._/-]+'; then
  [ "$away" = 0 ] || decide deny "$park"
  why="$(cd "${CLAUDE_PROJECT_DIR:-.}" && sh "$here/push-guard.sh" check 2>&1)" ||
    decide ask "The push guard is not in place here ($why), so nothing stops this push from reaching a protected branch: it asks. Approve only a push you asked for."
  exit 0
fi

plain="$(printf '%s' "$cmd" | tr -d "\\\\'\"")"
[ "$away" = 1 ] && printf '%s\n' "$plain" | grep -Eq 'git[[:space:]]+fetch' && decide deny "$park"
if printf '%s\n' "$plain" | grep -qi 'push' || { printf '%s\n' "$plain" | grep -q 'git' && printf '%s\n' "$cmd" | grep -q '[$`]'; }; then
  [ "$away" = 0 ] || decide deny "$park"
  decide ask "This command could push, but it is not the plain form git push origin <branch>: protected destinations go through ~/.claude/jacquard/scripts/protected-push.sh, which asks. Approve only a push you asked for."
fi
exit 0
