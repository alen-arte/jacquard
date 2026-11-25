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
here="$(cd "$(dirname "$0")" && pwd -P)"
. "$here/common.sh"
# Nothing inherited may change what git or a shell does: every GIT_*, husky's switch, shell start files, the loader
for v in $(env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p; s/^\(LD_[A-Za-z0-9_]*\)=.*/\1/p'); do unset "$v"; done
unset HUSKY BASH_ENV ENV

[ $# = 2 ] || { echo "usage: protected-push.sh <remote> <branch | refs/tags/<tag>>" >&2; exit 2; }
remote="$1"; dest="$2"
[ "${CLAUDE_CODE_REMOTE:-}" != true ] || die "this is a cloud session: protected pushes go from the computer"
top="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not in a git repo"
cd "$top" || die "cannot enter $top"
local_folder
! away_active "$local_dir" || die "Away is on: Away never pushes"
case "$remote" in ""|-*|*[!A-Za-z0-9._-]*) die "the remote must be a remote's name, not a URL: $(printf '%s' "$remote" | plain)" ;; esac
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
