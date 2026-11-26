#!/bin/sh
# Jacquard PreToolUse hook on Bash, in Present and in Away: a push that allow rules would let run without a prompt
# reaches them only in its one plain form, with the push guard in place in that repo. One rule set for both modes;
# Away answers "no" where Present asks.
# Usage: bash-guard.sh <local folder>   (the hook input on stdin; prints a decision, or nothing to leave it to the rules)
# On the command as the shell will see it (JSON escapes decoded):
#   - plain commands (no shell operators outside literal quotes, one line) that cannot push: grep (not rg: --pre runs a program), git log, diff,
#     show, status, `git commit -m`/`-F`, and the kit's own scripts but protected-push.sh: nothing. So is a commit whose
#     message is a quoted heredoc (`git commit -m "$(cat <<'EOF' … EOF )"`, literal inside)
#   - `git push [-u] origin <branch>`, alone: Away denies; Present runs push-guard.sh check in the command's folder:
#     no guard there (none installed, or someone else's hook) asks, a guard out of date or worked around denies
#   - protected-push.sh: Away denies; Present asks, naming the destination (its ask rule does too)
#   - any other command with a push verb (push, send-pack, http-push, also as git-push or a path ending in one) once
#     quotes, backslashes and backslash-newlines are gone, or one the shell computes (an expansion, a brace list, a
#     [ or ? in a word, a * that could name git or push, or a ( or ) glued to a word): Away denies, Present asks
#   - a git fetch: Away denies
#   - hook input past max_input, or a command it cannot read: Away denies, Present asks (a timed-out hook decides nothing)
# Reach: it reads the command's text and the syntax of sh, bash and zsh (the Bash tool may run zsh); it runs nothing.
# A program that builds the command (| sh, sh -c, eval, trap, alias, source, python -c, xargs, a script) is out of
# its reach: what stops that is that no allow rule lets an interpreter run without a prompt (Away: away-guard.sh
# permission says no). The git pre-push hook does not stop a hidden --no-verify; only a branch protection on the
# host would.
here="$(cd "$(dirname "$0")" && pwd)"
[ $# = 1 ] && [ -n "$1" ] || { echo "usage: bash-guard.sh <local folder>" >&2; exit 2; }
local_dir="$1"
. "$here/common.sh"
# Bytes, not characters: every character the rules look at is ASCII, and an invalid UTF-8 byte must not empty a match
export LC_ALL=C
input="$(cat)"
max_input=100000   # bytes of hook input read in well under the hook's timeout; past it, nothing is left to the rules
# JSON string escapes decoded; a \u escape or an unknown one becomes ESC, which no rule below treats as plain
cmd=""; [ "${#input}" -gt "$max_input" ] || cmd="$(hook_command | awk 'BEGIN { RS = "\001" } { s = $0; o = ""
  while ((i = index(s, "\\")) > 0) { o = o substr(s, 1, i - 1); c = substr(s, i + 1, 1); s = substr(s, i + 2)
    if (c == "n") o = o "\n"; else if (c == "\"" || c == "\\" || c == "/") o = o c
    else { o = o "\033"; if (c == "u") s = substr(s, 5) } }
  printf "%s", o s }')"

decide() {   # decide <deny|ask> <reason>: the hook's answer (the reason loses quotes and backslashes)
  r="$(printf '%s' "$2" | tr -d '"\\' | tr '\n' ' ')"
  printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "PreToolUse",\n    "permissionDecision": "%s",\n    "permissionDecisionReason": "%s"\n  }\n}\n' "$1" "$r"
  exit 0
}
away() { printf '%s' "$input" | sh "$here/away-guard.sh" active "$local_dir" 2>/dev/null; }
park="Away mode is on: Away never pushes or fetches (core/git.md › Push). Do not retry it: park the step in the Away journal and continue with other work. If the user is actually back, ask them to type /back."
nl='
'
ctl="$(printf '\033\t\r')"
kit='~/.claude/jacquard/scripts/'

# A guard that times out leaves the command to the allow rules, so a command too long to read (never decoded), or
# one it cannot read, gets a decision before anything slow runs
if [ -z "$cmd" ]; then
  away && decide deny "$park"
  decide ask "This command is too long or unreadable for the push check, so it asks. Approve only if it does what the user asked."
fi

# lit: the command with its literal quotes ('…', and "…" without $, backtick or backslash) turned into their text,
# every character but letters, digits and . _ / ~ - made _ (so x'a b'* reads xa_b*); a "…" with $, backtick or
# backslash keeps its quotes, its $, backticks and backslashes, the rest made _ too; $'…' and $"…" start with $Q.
# Quotes are read in one pass, left to right, as the shell reads them: a quote inside the other kind is a plain
# character; a backslash escapes the next one; an unclosed quote leaves ESC and the rest as written
# Plain: lit has no operator, no backslash, no #, no control character, and the command has no second line (inside
# quotes or not: a quote after a # is no quote to the shell)
lit="$(printf '%s' "$cmd" | awk -v q="'" 'BEGIN { RS = "\001" }
  function text(x, keep) { gsub("[^A-Za-z0-9._/~" keep "-]", "_", x); return x }
  { s = $0; n = length(s); o = ""; i = 1
  while (i <= n) { c = substr(s, i, 1)
    if (c == "\\") { o = o substr(s, i, 2); i += 2; continue }
    if (c == "$" && (substr(s, i + 1, 1) == q || substr(s, i + 1, 1) == "\"")) { o = o "$Q"; i++; continue }
    if (c == q) { j = index(substr(s, i + 1), q); if (!j) { o = o "\033" substr(s, i); break }
      o = o text(substr(s, i + 1, j - 1), ""); i += j + 1; continue }
    if (c != "\"") { o = o c; i++; continue }
    t = ""; lit = 1; i++
    while (i <= n && (c = substr(s, i, 1)) != "\"") {
      if (c == "\\") { t = t substr(s, i, 2); lit = 0; i += 2; continue }
      if (c == "$" || c == "`") lit = 0
      t = t c; i++ }
    if (i > n) { o = o "\033\"" t; break }
    o = o (lit ? text(t, "") : "\"" text(t, "$`\\\\") "\""); i++ }
  printf "%s", o }')"
case "$cmd" in *"$nl"*) plain=0 ;; *)
  case "$lit" in *'\'*|*[';&|$`<>()#']*|*["$ctl"]*) plain=0 ;; *) plain=1 ;; esac ;;
esac
if [ "$plain" = 1 ]; then
  case "$cmd" in
    grep\ *|"git log"|"git log "*|"git diff"|"git diff "*|"git show"|"git show "*|"git status"|"git status "*|\
    "git commit -m "*|"git commit -F "*) exit 0 ;;
  esac
  printf '%s\n' "$cmd" | grep -Eq '^~/\.claude/jacquard/scripts/[A-Za-z0-9_-]+\.sh( |$)' &&
    ! printf '%s\n' "$cmd" | grep -Eq '^~/\.claude/jacquard/scripts/protected-push\.sh|--widen' && exit 0
fi
if [ "$cmd" = "${kit}push-guard.sh install --widen" ]; then
  away && decide deny "$park"
  decide ask "This lets Claude push more without asking: it installs the push guard with this repo's free branches, main branch, remotes and husky files as they are now. Approve only if the user changed them."
fi
# A commit whose message is a quoted heredoc: literal from the first line to the one EOF line, which ends it
printf '%s\n' "$cmd" | awk -v q="'" 'NR == 1 { ok = ($0 == "git commit -m \"$(cat <<" q "EOF" q); next }
  $0 == "EOF" { eof++; last = NR } { end = $0 } END { exit !(ok && eof == 1 && last == NR - 1 && end == ")\"") }' && exit 0

case "$cmd" in *"$nl"*) ;; *)
  if printf '%s\n' "$cmd" | grep -Eqx 'git push( -u)? origin [A-Za-z0-9._/-]+'; then
    away && decide deny "$park"
    dir="$(field cwd)"; [ -d "$dir" ] || dir="${CLAUDE_PROJECT_DIR:-.}"
    why="$(cd "$dir" && sh "$here/push-guard.sh" check 2>&1)"; st=$?
    case "$st" in
      0) exit 0 ;;
      4) decide ask "No push guard in this repo ($why): nothing stops this push from reaching a protected branch, so it asks. Approve only a push you asked for." ;;
      *) decide deny "The push guard here is out of date or worked around: $why. Do not retry: say so to the user (the fix is /jacquard-update, which runs push-guard.sh install)." ;;
    esac
  fi
  if printf '%s\n' "$cmd" | grep -Eqx "${kit}protected-push\\.sh [A-Za-z0-9._-]+ [A-Za-z0-9._/-]+"; then
    away && decide deny "$park"
    set -f; set -- $cmd
    decide ask "This pushes $3 to $2, a protected destination (the main branch, a branch that is not free, or a tag). Approve only if the user asked for exactly this push."
  fi ;;
esac

# Words: runs of letters, digits and . _ / ~ -, once quotes and backslashes are gone (pu\sh and pu''sh are push),
# read as written and with every backslash-newline gone, as the shell joins those lines (pu\⏎sh is push)
joined="$(printf '%s' "$cmd" | awk 'BEGIN { RS = "\001" } { gsub(/\\\n/, ""); printf "%s", $0 }')"
words="$(printf '%s\n%s' "$cmd" "$joined" | tr -d "\\\\'\"" | tr -c 'A-Za-z0-9._/~-' '\n')"
has() { printf '%s\n' "$words" | grep -qix "$1"; }
# The verbs that push, as a word or as the last part of one (git-push, /usr/lib/git-core/git-send-pack)
push_verbs='push|send-pack|http-push'
verb() { printf '%s\n' "$words" | grep -Eqi "(^|[/-])($1)\$"; }
{ has git && verb fetch; } || verb git-fetch && away && decide deny "$park"
if verb "$push_verbs" || printf '%s\n' "$words" | grep -q 'protected-push'; then
  away && decide deny "$park"
  decide ask "This command could push, but it is not the plain form git push origin <branch>: protected destinations go only through ~/.claude/jacquard/scripts/protected-push.sh. Approve only a push the user asked for."
fi
# Computed: the shell builds part of what runs, so no word rule can read it (g$()it, ${x:-gi}t, $'\x67', {pu,x}sh,
# /usr/bin/gi[t], git-(pu|x)sh, <(…)). Read in lit, also on several lines unless there is a # or a << (a quote after
# a # or in an unquoted heredoc is no quote to the shell; then the command as written): an expansion (a backtick, or
# a $ before anything but a space, in lit nor before a closing "), a brace list, a [ or ? in a word ([ and [[ alone
# are the test command), a * in a word that could then name git or a push verb, or a ( or ) glued to a word
case "$cmd" in *"$nl"*'#'*|*'#'*"$nl"*|*"$nl"*'<<'*|*'<<'*"$nl"*) dyn="$cmd"; dollar='\$[^[:space:]]' ;;
  *) dyn="$lit"; dollar='\$[^[:space:]"]' ;; esac
computed() {
  printf '%s' "$dyn" | grep -Eq -e '`' -e "$dollar" -e '\{[^{}]*(,|\.\.)[^{}]*\}' \
    -e '[^[:space:];&|(]\(' -e '\)[^[:space:];&|)]' && return 0
  printf '%s' "$dyn" | awk -v names="git|fetch|$push_verbs" 'BEGIN { RS = "\001"; m = split(names, v, "|") }
    { n = split($0, w, /[ \t\n;&|()<>]+/)
    for (k = 1; k <= n; k++) { t = w[k]; gsub(/[\\"'"'"']/, "", t)
      if (t ~ /[[?]/ && t !~ /^(\[\[?|\]\]?)$/) exit 0
      if (t !~ /\*/) continue
      sub(/.*\//, "", t); if (t !~ /^[A-Za-z*-]+$/ || t !~ /[A-Za-z]/) continue
      gsub(/\*/, ".*", t); r = "^(" t ")$"
      for (j = 1; j <= m; j++) if (v[j] ~ r || ("git-" v[j]) ~ r) exit 0 }
    exit 1 }'
}
computed_what="an expansion, a brace list, a [ or ? in a word, a * that could name git or push, or a ( or ) glued to a word"
if computed; then
  away && decide deny "Away mode is on, and the shell computes part of this command ($computed_what), so the push check cannot read it. Write it in a plain form, or park the step in the Away journal and continue."
  decide ask "The shell computes part of this command ($computed_what), so the push check cannot read what it runs. Approve only if it does what the user asked."
fi
exit 0
