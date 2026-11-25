#!/bin/sh
# Jacquard SessionStart hook: every job that runs when a session starts, each on its own, so one that fails never
# skips the next. Its stdout becomes context for Claude: only the jobs' reminder lines are printed. Always exits 0.
# Usage: session-start.sh <local folder>   (the hook input on stdin)
# Jobs, the cheapest first (a job that hangs uses up the hook's time and skips the rest):
#   1. one line when this session does not mark itself as Claude (CLAUDECODE, CLAUDE_CODE_ENTRYPOINT, JACQUARD_AGENT
#      all empty): the push guard tells Claude's pushes from yours by them. Never in a cloud session (no guard there)
#   2. away-guard.sh session-reset: a resumed, cleared or forked Away session starts in Present
#   3. kit-version.sh project: one line when the project and the installed kit differ, only when a stretch of work
#      starts (startup or resume, not /clear or compaction) and never in a cloud session
here="$(cd "$(dirname "$0")" && pwd)"
[ $# = 1 ] && [ -n "$1" ] || { echo "usage: session-start.sh <local folder>" >&2; exit 2; }
local_dir="$1"
. "$here/common.sh"
input="$(cat)"
src="$(field source)"
cloud=0; [ "${CLAUDE_CODE_REMOTE:-}" = true ] && cloud=1

[ "$cloud" = 1 ] || [ -n "${CLAUDECODE:-}${CLAUDE_CODE_ENTRYPOINT:-}${JACQUARD_AGENT:-}" ] ||
  echo "Jacquard: this session does not mark itself as Claude (CLAUDECODE, CLAUDE_CODE_ENTRYPOINT and JACQUARD_AGENT are empty), so the push guard would take Claude's pushes for the user's. Say so in one line in your first reply, and push nothing until the user has looked (a Claude Code update may have renamed them)."

printf '%s' "$input" | sh "$here/away-guard.sh" session-reset "$local_dir" >/dev/null

case "$src" in startup|resume)
  [ "$cloud" = 1 ] || ! find_local "$local_dir" ||
    sh "$here/kit-version.sh" project "$local_path/index.md" 2>/dev/null ;;
esac
exit 0
