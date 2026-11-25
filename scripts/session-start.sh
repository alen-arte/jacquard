#!/bin/sh
# Jacquard SessionStart hook: every job that runs when a session starts, each on its own, so one that fails never
# skips the next. Its stdout becomes context for Claude: only the jobs' reminder lines are printed. Always exits 0.
# Usage: session-start.sh <local folder>   (the hook input on stdin)
# Jobs:
#   1. away-guard.sh session-reset: a resumed, cleared or forked Away session starts in Present
#   2. kit-version.sh project: one line when the project and the installed kit differ, only when a stretch of work
#      starts (startup or resume, not /clear or compaction) and never in a cloud session
here="$(cd "$(dirname "$0")" && pwd)"
[ $# = 1 ] && [ -n "$1" ] || { echo "usage: session-start.sh <local folder>" >&2; exit 2; }
local_dir="$1"
. "$here/common.sh"
input="$(cat)"
src="$(field source)"

printf '%s' "$input" | sh "$here/away-guard.sh" session-reset "$local_dir" >/dev/null

case "$src" in startup|resume)
  [ "${CLAUDE_CODE_REMOTE:-}" = true ] || ! find_local "$local_dir" ||
    sh "$here/kit-version.sh" project "$local_path/index.md" 2>/dev/null ;;
esac
exit 0
