#!/bin/sh
# Tests for scripts/bash-guard.sh, the PreToolUse hook on Bash. Run from anywhere: tests/scripts/bash-guard.test.sh
. "$(dirname "$0")/lib.sh"
. "$here/push-guard-lib.sh"
bg="$kc/scripts/bash-guard.sh"; guard="$kc/scripts/away-guard.sh"
is_json() { command -v python3 >/dev/null || return 0; printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; }

# hook <command as it appears inside a JSON string>: output in $out (session s1, project $r)
hook() { out="$(printf '{"session_id":"s1","cwd":"%s","tool_name":"Bash","tool_input":{"command":"%s","description":"push it"}}' "${cwd:-$r}" "$1" | CLAUDE_PROJECT_DIR="$r" "$bg" .jacquard 2>/dev/null)"; }
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
expect none B1 'git commit -m \"$(cat <<'"'"'EOF'"'"'\nR64: push guard (fix; tests)\n\nCo-Authored-By: x\nEOF\n)\"'
expect none B1 'git commit -m \"R64: guard (push; fix)\"'
expect none B1 "grep -E 'push|fetch' scripts"
expect ask B1 "rg --pre 'git push --no-verify origin main' x ."
expect none B1 'git add src/push-notifications.ts'
expect none B1 "~/.claude/jacquard/scripts/personal-sync.sh 'R64: push guard'"
expect none B1 '~/.claude/jacquard/scripts/push-guard.sh install'
expect none B1 '~/.claude/jacquard/scripts/push-guard.sh check'

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
expect ask B2 "grep 'x' f; git push origin main"
expect ask B2 'git commit -m \"$(cat <<'"'"'EOF'"'"'\nx\nEOF\n)\"; git push origin main'
expect ask B2 'git commit -m \"$(cat <<'"'"'EOF'"'"'\nx\nEOF\ngit push origin main\nEOF\n)\"'
expect ask B2 'git commit -m \"$(git push origin main)\"'
expect ask B2 '~/.claude/jacquard/scripts/push-guard.sh install --widen'
expect ask B2 '/tmp/pp origin main; echo protected-push'
# Quotes are read in one pass: an apostrophe inside "…" (or a quote inside '…') does not hide what follows
expect ask B2 "git commit -m \\\"it's done\\\"; git push origin r1-x; echo 'ok'"
expect ask B2 "grep \\\"'\\\" x ; git push origin feature-x ; echo \\\"'\\\""
expect ask B2 "~/.claude/jacquard/scripts/personal-sync.sh \\\"it's\\\"; git push origin r1-x; echo 'ok'"
expect ask B2 "grep '\\\"' x; git push origin r1-x; echo '\\\"'"
expect ask B2 "git commit -m \\\"it's\\\" \\\"\$(git fetch)\\\" 'x'"
expect none B2 "git commit -m \\\"it's done\\\""
expect none B2 "grep -n \\\"don't push\\\" core/git.md"
# A second line is never plain, even inside quotes or after a # comment; neither is an unclosed quote
expect ask B2 "git log #'\\ngit push origin r1-x\\n#'"
expect ask B2 "grep 'a\\ngit push origin r1-x\\n' x"
expect ask B2 "grep 'x; git push origin r1-x"
expect ask B2 "grep \\\\' x; git push origin r1-x; echo \\\\'"
expect ask B2 "grep \\\"\\\"'' x; git push origin r1-x"
expect none B2 "grep \\\"\\\"'' x"
# $ or a backtick next to git counts on every line: a quote after a # or in an unquoted heredoc hides nothing
expect ask B2 "true #'\\ngit \$(printf pu)sh --no-verify origin main\\n#'"
expect ask B2 "cat <<EOF\\nit's\\nEOF\\ngit \$(printf pu)sh origin r1-x\\n#'"
# A backslash before a line break joins the lines, as the shell does: pu\⏎sh is push
expect ask B2 'git pu\\\nsh --no-verify origin main'
expect ask B2 "git status #'\\ngit pu\\\\\\nsh --no-verify origin main\\n#'"
expect ask B2 'g\\\nit pu\\\nsh origin r1-x'
# Git's lower-level pushes count as push
expect ask B2 'git send-pack https://example.com/r.git main'
expect ask B2 'git http-push https://example.com/r.git main'
expect none B2 "grep \\\"pattern\$\\\" f"
expect none B2 "git log --grep='fix\$'"
# A command too long to read in time, or one the guard cannot read, is never left to the rules
expect ask B2 "git log $(awk 'BEGIN { while (n++ < 12000) printf "x x x x x " }')"
case "$out" in *"too long"*) ;; *) fail "B2 a command past the length cap asks, saying it is too long: $out";; esac
expect ask B2 "grep \\\"$(printf '\303')'\\\" x; git push origin r1-x"
case "$(hook '~/.claude/jacquard/scripts/protected-push.sh origin main'; printf '%s' "$out")" in
  *"pushes main to origin"*) ;; *) fail "B2 the protected-push prompt names the destination and the remote: $out";; esac

# B3 · Present: a guard out of date denies (approving would not help: the stub refuses); no guard in that repo asks
printf '\n' >> "$kc/scripts/push-guard/hook.sh"
expect deny B3 'git push origin r1-x'
case "$out" in *"out of date"*) ;; *) fail "B3 the reason says the guard is out of date: $out";; esac
sc install
new_project b2; cd "$tmp/b1" || exit 1; r="$tmp/b1"
cwd="$tmp/b2" expect ask B3 'git push origin r1-x'
case "$out" in *"No push guard"*) ;; *) fail "B3 the check runs in the command's folder (b2, no stub), not the project's (b1): $out";; esac
unset cwd

# B6 · An own remote (project.md › Git › Own remotes) takes the plain form too, and so does <branch>:<branch>
git init -q --bare "$tmp/b1-personal.git"; git remote add personal "$tmp/b1-personal.git"
printf -- '- **Own remotes** (x): `personal`\n' >> .jacquard/project.md; sc install
for c in 'git push personal demo' 'git push -u personal ux/a' 'git push personal demo:demo' 'git push origin r1-x:r1-x'; do
  expect none B6 "$c"
done
for c in 'git push personal demo:main' 'git push personal demo:other' 'git push personal demo:' 'git push -u -personal x'; do
  expect ask B6 "$c"
done
expect ask B6 'git push stranger demo'
case "$out" in *"Own remotes"*) ;; *) fail "B6 a remote off the list asks, naming project.md › Git › Own remotes: $out";; esac

# B4 · Away (this session): every push and fetch is denied with a park message; read-only work and commits pass
CLAUDE_PROJECT_DIR="$r" CLAUDE_CODE_SESSION_ID=s1 "$guard" on .jacquard >/dev/null 2>&1
for c in 'git push origin r1-x' 'git fetch origin' 'cd x && git  push -u origin r1' 'g\\it push origin main' 'env git push origin r1' \
         '~/.claude/jacquard/scripts/protected-push.sh origin main' 'git status; git fetch' 'git push personal demo:demo'; do
  expect deny B4 "$c"
  case "$out" in *park*) ;; *) fail "B4 the denial says to park the step: $out";; esac
done
expect deny B4 "git commit -m \\\"it's done\\\"; git push origin r1-x; echo 'ok'"
expect deny B4 "grep \\\"'\\\" x ; git push origin feature-x ; echo \\\"'\\\""
expect deny B4 "git log #'\\ngit push origin r1-x\\n#'"
expect deny B4 "true #'\\ngit \$(printf pu)sh --no-verify origin main\\n#'"
expect deny B4 'git pu\\\nsh --no-verify origin main'
expect deny B4 'git send-pack https://example.com/r.git main'
expect deny B4 "git log $(awk 'BEGIN { while (n++ < 12000) printf "x x x x x " }')"
case "$out" in *park*) ;; *) fail "B4 a command past the length cap is denied with the park message: $out";; esac
expect none B4 'grep -rn \"git push\" scripts'
expect none B4 'git commit -m \"R1: push button\"'

# B5 · The old PreToolUse entry (away-guard.sh pre-bash) hands over
out="$(printf '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"git push origin r1-x"}}' | CLAUDE_PROJECT_DIR="$r" "$guard" pre-bash .jacquard 2>/dev/null)"
[ "$(decision)" = deny ] || fail "B5 away-guard.sh pre-bash must hand over to bash-guard.sh (got: $out)"
out="$(printf '{"session_id":"s2","tool_name":"Bash","tool_input":{"command":"git fetch origin"}}' | CLAUDE_PROJECT_DIR="$r" "$bg" .jacquard 2>/dev/null)"
[ -z "$out" ] || fail "B5 another session's Away does not stop this one (got: $out)"
CLAUDE_PROJECT_DIR="$r" CLAUDE_CODE_SESSION_ID=s1 "$guard" off .jacquard >/dev/null 2>&1

finish "bash-guard"
