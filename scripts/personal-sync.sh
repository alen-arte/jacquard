#!/bin/sh
# Jacquard personal-layer backup (core git.md › Personal layer backup): from a project repo, commits that project's
# folder in the personal layer and pushes the layer's main to its private remote. No git command has to reach into
# another repo (git -C, cd elsewhere, push to main stay denied); this script is the one allowed way, and it:
#   - refuses during Away (hard limit: no pushes) and when the layer is not on main or has an operation half done;
#   - commits only projects/<name>/ (what the layer ignores stays out; other projects' changes are named, never taken);
#   - pushes only to a private GitHub repo with no other collaborators, fast-forward only, after listing what goes up;
#   - when the remote went ahead, fetches and stops: it never merges or rebases.
# Usage (inside the project repo): personal-sync.sh ['message']   default message: "<name>: docs"
# Exit 0: backed up, or nothing to back up · 1: refused (nothing pushed) · 2: usage.
set -eu
. "$(cd "$(dirname "$0")" && pwd)/common.sh"   # die, plain, capped, local_folder, away_active, private_remote; clears GIT_* paths

[ $# -le 1 ] || { echo "usage: ${0##*/} ['message']" >&2; exit 2; }
repo="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repo: run this inside a Jacquard project"
cd "$repo"
local_folder
[ -L "$local_dir" ] || die "$local_dir is not a link into the personal layer: run this inside a Jacquard project"

# the link must end exactly at <layer>/projects/<name>
[ -d "${JACQUARD_PERSONAL:-$HOME/repos/jacquard-personal}" ] || die "no personal layer at ${JACQUARD_PERSONAL:-~/repos/jacquard-personal}"
root="$(readlink -f "${JACQUARD_PERSONAL:-$HOME/repos/jacquard-personal}")"
target="$(readlink -f "$local_dir")"
name="${target#"$root/projects/"}"
[ "$target" = "$root/projects/$name" ] || die "$local_dir does not point into $root/projects/: nothing done"
case "$name" in [a-z0-9]*) ;; *) die "unusual project folder name: lowercase letters, digits, '.', '_' and '-' only" ;; esac
case "$name" in */*|*[!a-z0-9._-]*) die "unusual project folder name ($(printf '%s\n' "$name" | plain)): lowercase letters, digits, '.', '_' and '-' only" ;; esac
! away_active "$target" || die "an Away block is running in this project: the backup waits for Present"

# the layer: a repo of its own, on main, nothing half done
cd "$root"
[ "$(git rev-parse --show-toplevel 2>/dev/null)" = "$root" ] || die "$root is not the top of a git repo: nothing done"
[ "$(git symbolic-ref -q --short HEAD || true)" = main ] || die "the personal layer is not on main: nothing done"
gd="$(git rev-parse --absolute-git-dir)"
for f in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply index.lock; do
  [ ! -e "$gd/$f" ] || die "the personal layer has an operation half done ($f): finish it first; nothing done"
done
remote="$(git config --get branch.main.remote || echo origin)"
remote_ok "$remote" || die "unusual remote for the layer's main: nothing done"
git remote get-url "$remote" >/dev/null 2>&1 || die "the personal layer has no remote $remote: nothing done"
private_remote
# what is compared before pushing must come from the repo that was checked
[ "$(git remote get-url "$remote")" = "$urls" ] || die "$remote fetches from one URL and pushes to another: nothing done"

# commit this project's folder only (the pathspec keeps anything else already staged out of it)
msg="$(printf '%s\n' "${1:-}" | plain | cut -c1-200 | sed -n '1,20p')"
[ -n "$(printf '%s' "$msg" | tr -d ' \n')" ] || msg="$name: docs"
# a git repo of its own inside the folder cannot travel inside this one: left out and named
nested="$(find "projects/$name" -mindepth 2 -name .git -prune -print | sed 's#/\.git$##')"
set -- "projects/$name"
while IFS= read -r d; do [ -z "$d" ] || set -- "$@" ":(exclude)$d"; done <<EOF
$nested
EOF
git add -A -- "$@"
# files backed up for the first time also reach the cloud on the next prepare: named, so real data can still be ignored
first="$(git -c core.quotePath=false diff --cached --name-only --diff-filter=A -- "$@" | plain)"
[ -z "$first" ] || printf 'Backed up for the first time (if one holds real data or names, ignore it in the layer and remove it):\n%s\n' \
  "$(printf '%s\n' "$first" | capped)"
if git diff --cached --quiet -- "$@"; then committed=0; else git commit -q -m "$msg" -- "$@"; committed=1; fi
[ -z "$nested" ] || printf 'Not backed up (a git repo of its own inside the project folder):\n%s\n' "$(printf '%s\n' "$nested" | plain | capped)"
others="$(git status --porcelain -- . ":(exclude)projects/$name" | plain)"
[ -z "$others" ] || printf 'Left as they are (not this project):\n%s\n' "$(printf '%s\n' "$others" | capped)"

# push main, fast-forward only, after saying what goes up
kept="$( [ $committed = 0 ] || echo ' (the commit stays on this computer)')"
st=0; git ls-remote --exit-code "$remote" refs/heads/main >/dev/null 2>&1 || st=$?
[ $st = 0 ] || [ $st = 2 ] || die "could not reach $remote: nothing pushed$kept"
up="refs/remotes/$remote/main"
if [ $st = 2 ]; then   # first backup: the remote has no main yet
  git update-ref -d "$up" 2>/dev/null || true
  ahead="$(git log --format='%h %s' main | plain)"
  printf 'First backup to %s (%s commits)\n' "$slug" "$(printf '%s\n' "$ahead" | grep -c .)"
  git push -q "$remote" refs/heads/main:refs/heads/main
  echo "✓ personal layer backed up"; exit 0
fi
git fetch -q "$remote" "+refs/heads/main:refs/remotes/$remote/main" || die "could not reach $remote: nothing pushed$kept"
git merge-base --is-ancestor "$up" main || die "the layer's remote has commits this computer does not have: bring them in first (in the personal layer, git pull --rebase), then run this again. Nothing pushed$( [ $committed = 0 ] || echo '; the commit stays on this computer')"
ahead="$(git log --format='%h %s' "$up..main" | plain)"
[ -n "$ahead" ] || { echo "✓ nothing to back up for $name"; exit 0; }
printf 'Backing up to %s:\n%s\n' "$slug" "$(printf '%s\n' "$ahead" | sed 's/^/  /')"
git push -q "$remote" refs/heads/main:refs/heads/main
echo "✓ personal layer backed up"
