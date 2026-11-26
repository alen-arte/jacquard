#!/bin/sh
# Jacquard: the one way Claude pushes a protected destination: the main branch, a branch that is not free in
# project.md › Git, or a tag. An exact `ask` rule makes Claude Code ask you each time, showing the remote and the
# destination; the push guard lets the push through only when this script itself runs it. Never in Away, never in a
# cloud session (protected pushes go from the computer). Fast-forward only, one destination, tags never follow.
# Usage, from the project repo: protected-push.sh <remote> <branch | refs/tags/<tag>>
#   <remote> is a remote's name (never a URL); a branch is pushed from the local branch of the same name.
set -f
PATH=/usr/bin:/bin
export PATH
export LC_ALL=C   # bytes, not characters: names are ASCII, so an accented letter never passes a [A-Za-z] test
[ -r /proc/self/status ] || { echo "✗ protected-push.sh: this system has no /proc, so the push guard cannot see this script run the push: push it from your terminal" >&2; exit 1; }
# Only by its real path: a link elsewhere would also load the common.sh beside the link
real="$(readlink -f "$0" 2>/dev/null)"
[ -n "$real" ] && [ "$0" = "$real" ] || { echo "✗ protected-push.sh: run it by its real path${real:+, $real}" >&2; exit 1; }
here="${real%/*}"
. "$here/common.sh"
# Nothing inherited may change what git or a shell does: every GIT_*, husky's switch, shell start files, the loader,
# and where git finds the user's own settings (HOME from the system, never from the command)
for v in $(env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p; s/^\(LD_[A-Za-z0-9_]*\)=.*/\1/p'); do unset "$v"; done
unset HUSKY BASH_ENV ENV XDG_CONFIG_HOME
HOME="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6)"
[ -n "$HOME" ] || die "cannot read your home folder from the system"
export HOME

[ $# = 2 ] || { echo "usage: protected-push.sh <remote> <branch | refs/tags/<tag>>" >&2; exit 2; }
remote="$1"; dest="$2"
[ "${CLAUDE_CODE_REMOTE:-}" != true ] || die "this is a cloud session: protected pushes go from the computer"
top="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not in a git repo"
cd "$top" || die "cannot enter $top"
local_folder
! away_active "$local_dir" || die "Away is on: Away never pushes"
remote_ok "$remote" || die "the remote must be a remote's name, not a URL: $(printf '%s' "$remote" | plain)"
git remote | grep -qxF -e "$remote" || die "no remote called $remote"
full="$(dest_ref "$dest")" || die "the destination must be a branch name or refs/tags/<tag>: $(printf '%s' "$dest" | plain)"
git rev-parse -q --verify "$full" >/dev/null || die "there is no local $full to push"

# What goes up, named before it leaves
case "$full" in
  refs/heads/*)
    if git rev-parse -q --verify "refs/remotes/$remote/$dest" >/dev/null; then
      echo "→ $remote $dest: $(git rev-list --count "refs/remotes/$remote/$dest..$full") commit(s)"
      git log --oneline "refs/remotes/$remote/$dest..$full" | plain | capped 20
    else
      echo "→ $remote $dest: a branch $remote does not have yet (as far as this computer knows)"
    fi ;;
  *) echo "→ $remote ${full#refs/tags/}: tag at $(git rev-parse --short "$full^{}")" ;;
esac
# A child process, never exec: the push guard reads this script as the push's parent
git push --no-follow-tags "$remote" "$full:$full"
st=$?
exit "$st"
