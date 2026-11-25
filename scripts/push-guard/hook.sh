#!/bin/sh
# Jacquard push guard: what the pre-push stub runs when Claude pushes. git passes the remote name and URL, and one line
# per ref on stdin: <local ref> <local sha> <remote ref> <remote sha>. The stub sets JQ_MAIN, JQ_FREE (the free
# branches), JQ_LOCAL (the local folder) and JQ_SH_EXE (the real /bin/sh), and has checked this file's sum.
# Goes through: free branches and the kit's work branches, fast-forward only. Everything else (the main branch, any
# other branch, tags, anything outside refs/heads/) only when protected-push.sh itself runs this push: the process
# that started `git push` is that script, run as itself, for this remote and this one destination (read in /proc;
# without /proc, never). Refused always: deleting, a push that is not a fast-forward, any push while Away is on.
set -f
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/../common.sh"
refuse() { echo "✗ Jacquard push guard: $1 Push refused." >&2; exit 1; }
remote="$1"
away_active "$JQ_LOCAL" && refuse "Away is on: Away never pushes."

# free <branch>: pushed without asking. Never main, master or the main branch, whatever the case.
free() {
  lc="$(printf '%s' "$1" | tr 'A-Z' 'a-z')"
  case "$lc" in main|master|"$(printf '%s' "$JQ_MAIN" | tr 'A-Z' 'a-z')") return 1 ;; esac
  for f in $JQ_FREE; do [ "$1" = "$f" ] && return 0; done
  printf '%s\n' "$1" | grep -Eqx '(away|cloud)/[A-Za-z0-9._/-]+|(r|rf|p)[0-9]+(-[A-Za-z0-9._-]+)?'
}

# ppid <pid>, argv <pid> (one argument per line)
ppid() { sed -n 's/^PPid:[[:space:]]*//p' "/proc/$1/status" 2>/dev/null; }
argv() { tr '\0' '\n' < "/proc/$1/cmdline" 2>/dev/null; }

# authorized <remote> <full remote ref>: the git process running this push was started by protected-push.sh, run as
# the kernel runs it (`/bin/sh <its real path> <remote> <destination>`, nothing else), with no variable in its starting
# environment that makes a shell run other code, for exactly this remote and destination.
authorized() {
  [ -r "/proc/$$/status" ] || return 1
  pid=$$; i=0
  while :; do   # up from this hook, past the stub (and husky's runner), to the git process
    pid="$(ppid "$pid")"; i=$((i + 1))
    case "$pid" in ""|0|1|*[!0-9]*) return 1 ;; esac
    [ "$i" -le 8 ] || return 1
    [ "$(argv "$pid" | sed -n 1p | sed 's|.*/||')" = git ] && break
  done
  p="$(ppid "$pid")"; case "$p" in ""|0|1|*[!0-9]*) return 1 ;; esac
  [ "$(argv "$p" | wc -l | tr -d ' ')" = 4 ] || return 1
  [ "$(argv "$p" | sed -n 1p)" = /bin/sh ] || return 1
  [ "$(readlink "/proc/$p/exe")" = "$JQ_SH_EXE" ] || return 1
  [ "$(argv "$p" | sed -n 2p)" = "$(cd "$here/.." && pwd -P)/protected-push.sh" ] || return 1   # its real path, as is
  [ "$(argv "$p" | sed -n 3p)" = "$1" ] || return 1
  [ "$(dest_ref "$(argv "$p" | sed -n 4p)")" = "$2" ] || return 1
  ! tr '\0' '\n' < "/proc/$p/environ" | grep -Eq '^(BASH_ENV|ENV|LD_[A-Za-z0-9_]*)='
}

lines="$(cat)"
count=0; protected=""
while read -r lref lsha rref rsha; do
  [ -n "$rref" ] || continue
  count=$((count + 1))
  case "$lsha" in *[!0]*) ;; *) refuse "Deleting $rref is not something Claude does." ;; esac
  case "$rsha" in *[!0]*)
    git cat-file -e "$rsha^{commit}" 2>/dev/null && git merge-base --is-ancestor "$rsha" "$lsha" 2>/dev/null ||
      refuse "$rref is not a fast-forward (the remote has commits this push would drop)." ;;
  esac
  case "$rref" in refs/heads/*) free "${rref#refs/heads/}" && continue ;; esac
  protected="$rref"
done <<EOF
$lines
EOF
[ -n "$protected" ] || exit 0
[ "$count" = 1 ] || refuse "$protected is protected and goes alone, through protected-push.sh."
authorized "$remote" "$protected" ||
  refuse "$protected is protected: only ~/.claude/jacquard/scripts/protected-push.sh $remote <branch> pushes it, and it asks first. Or run the push in your terminal (not with ! inside Claude)."
exit 0
