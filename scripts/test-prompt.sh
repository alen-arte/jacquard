#!/usr/bin/env bash
# Prints the prompt for one Jacquard test file: the preamble, the files to read
# and each case's ID and "Given" text. Case titles and the pass and fail criteria
# are never printed, so the subagent under test cannot see the expected answer.
# Usage: scripts/test-prompt.sh tests/<group>/<name>.md
set -euo pipefail

file="${1:?usage: test-prompt.sh tests/<group>/<name>.md}"
[ -f "$file" ] || { echo "no such test file: $file" >&2; exit 1; }
root="$(cd "$(dirname "$0")/.." && pwd)"

cat <<EOF
Dry run of the Jacquard kit. Kit root: $root
Read the files listed under "Reads", from the kit root. Where any kit file names ~/.claude/jacquard/, read that path from the kit root instead.
Ignore any project index already in your context: the project is the one each case describes. Assume the core standards (core/standards.md) and that project's index were loaded at session start, unless a case says otherwise. You may only read files; never write, edit, run commands or launch agents.
For each case, reply with the exact next message you would send or the action you would take, under 120 words, headed by the case ID. Do not explain the rules back.

EOF

awk '
  /^Reads:/                 { print; print ""; next }
  /^### /                   { print $1, $2; keep = 0; next }
  /^[ \t]*\*\*Given:\*\*/         { keep = 1 }
  /^[ \t]*\*\*(Pass|Fail) if:\*\*/ { keep = 0 }
  keep                      { print }
' "$file"
