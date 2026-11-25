#!/bin/sh
# Tests for scripts/bash-guard.sh, the PreToolUse hook on Bash. Run from anywhere: tests/scripts/bash-guard.test.sh
. "$(dirname "$0")/lib.sh"
. "$here/push-guard-lib.sh"
bg="$kc/scripts/bash-guard.sh"; guard="$kc/scripts/away-guard.sh"
is_json() { command -v python3 >/dev/null || return 0; printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; }

# hook <command as it appears inside a JSON string>: output in $out (session s1, project $r)
hook() { out="$(printf '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"%s","description":"push it"}}' "$1" | CLAUDE_PROJECT_DIR="$r" "$bg" .jacquard 2>/dev/null)"; }
decision() { printf '%s' "$out" | sed -n 's/.*"permissionDecision": "\([a-z]*\)".*/\1/p'; }
expect() { # expect <none|ask|deny> <case> <command>
  hook "$3"; d="$(decision)"; [ -n "$d" ] || d=none
  [ "$d" = "$1" ] || fail "$2: '$3' must be $1 (got $d: $out)"
  [ -z "$out" ] || is_json "$out" || fail "$2: not valid JSON: $out"
}

new_project b1
sc install

# B1 · Present, guard in place: the plain push is left to the rules; read-only work and commits pass
expect none B1 'git push origin r1-x'
expect none B1 'git push -u origin away/r1-x'
expect none B1 'grep -n \"git push\" core/git.md'
expect none B1 'git log --oneline -n 5'
expect none B1 'git commit -m \"R64: push guard\"'
expect none B1 'npm run test'

# B2 · Present: every other way of saying push asks, and so do $ or a backtick next to git
expect ask B2 'git push origin ma\\in'
expect ask B2 'git push origin {main,r1}'
expect ask B2 'git push origin r1:heads/production'
expect ask B2 'HUSKY=0 git push origin main'
expect ask B2 'env -u CLAUDECODE git push origin r1'
expect ask B2 'g\\it push origin main'
expect ask B2 'git status; git push origin r1'
expect ask B2 'git push origin r1\ngit push origin main'
expect ask B2 '~/.claude/jacquard/scripts/protected-push.sh origin main'
expect ask B2 'sh ~/.claude/jacquard/scripts/protected-push.sh origin main'
expect ask B2 'git $(echo pu)sh origin main'
expect ask B2 'grep -n x f; git push origin main'
expect none B2 'git log --oneline | head'

# B3 · Present, guard not in place (stale or missing): the plain push asks, with the reason
printf '\n' >> "$kc/scripts/push-guard/hook.sh"
expect ask B3 'git push origin r1-x'
case "$out" in *"not in place"*) ;; *) fail "B3 the reason says the guard is not in place: $out";; esac
sc install

# B4 · Away (this session): every push and fetch is denied with a park message; read-only work and commits pass
CLAUDE_PROJECT_DIR="$r" CLAUDE_CODE_SESSION_ID=s1 "$guard" on .jacquard >/dev/null 2>&1
for c in 'git push origin r1-x' 'git fetch origin' 'cd x && git  push -u origin r1' 'g\\it push origin main' 'env git push origin r1' \
         '~/.claude/jacquard/scripts/protected-push.sh origin main' 'git status; git fetch'; do
  expect deny B4 "$c"
  case "$out" in *park*) ;; *) fail "B4 the denial says to park the step: $out";; esac
done
expect none B4 'grep -rn \"git push\" scripts'
expect none B4 'git commit -m \"R1: push button\"'

# B5 · The old PreToolUse entry (away-guard.sh pre-bash) hands over
out="$(printf '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"git push origin r1-x"}}' | CLAUDE_PROJECT_DIR="$r" "$guard" pre-bash .jacquard 2>/dev/null)"
[ "$(decision)" = deny ] || fail "B5 away-guard.sh pre-bash must hand over to bash-guard.sh (got: $out)"
out="$(printf '{"session_id":"s2","tool_name":"Bash","tool_input":{"command":"git fetch origin"}}' | CLAUDE_PROJECT_DIR="$r" "$bg" .jacquard 2>/dev/null)"
[ -z "$out" ] || fail "B5 another session's Away does not stop this one (got: $out)"
CLAUDE_PROJECT_DIR="$r" CLAUDE_CODE_SESSION_ID=s1 "$guard" off .jacquard >/dev/null 2>&1

finish "bash-guard"
