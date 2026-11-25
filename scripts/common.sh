# Jacquard: helpers shared by the scripts that run from a project repo (cloud.sh, personal-sync.sh) and by its hooks
# (away-guard.sh, session-start.sh). Sourced, never run.

# git must act on the repos these scripts name, never on one an inherited environment points to
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES \
  GIT_NAMESPACE GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT   # the user's own GIT_CONFIG_GLOBAL/NOSYSTEM stay

die() { echo "✗ $*" >&2; exit 1; }
# Text someone else can write (commit subjects, file names, git's messages about them), printed without terminal
# controls: C0, DEL, C1 and bidi overrides.
plain() { LC_ALL=C awk '{ gsub(/[\001-\037\177]/, ""); gsub(/\302[\200-\237]/, ""); gsub(/\342\200[\252-\256]|\342\201[\246-\251]/, ""); print }'; }
# A list read on stdin, indented, its first $1 lines (10 by default) and how many more: a list is never a flood.
capped() { awk -v m="${1:-10}" 'NF { n++; if (n <= m) print "  " $0 } END { if (n > m) print "  … and " n - m " more" }'; }

# The project's local folder, run from the repo root: the one folder whose index.md CLAUDE.local.md imports with a
# relative path (default .jacquard). Sets local_dir.
local_folder() {
  local_dir=""
  if [ -f CLAUDE.local.md ]; then
    local_dir="$(tr -d '\r' < CLAUDE.local.md | sed -n 's#^@\([^~/][^ ]*\)/index\.md$#\1#p')"
    [ "$(printf '%s\n' "$local_dir" | grep -c .)" -le 1 ] || die "CLAUDE.local.md imports more than one local index.md: keep one"
  fi
  local_dir="${local_dir:-.jacquard}"
  case "$local_dir" in .|..|*[!A-Za-z0-9._-]*) die "unusual local folder name in CLAUDE.local.md ($(printf '%s\n' "$local_dir" | plain)): letters, digits, '.', '_' and '-' only" ;; esac
}

# The local folder $1 as a full path, in local_path (an absolute $1 as is): under CLAUDE_PROJECT_DIR, which hooks get;
# else under the nearest folder up from here that holds $1/index.md (the Bash tool may sit in a subfolder). Returns 1
# when there is none.
find_local() {
  case "$1" in /*) local_path="$1"; return 0 ;; esac
  _d="${CLAUDE_PROJECT_DIR:-}"
  if [ -z "$_d" ]; then
    _d="$(pwd -P)"
    while [ -n "$_d" ] && [ ! -f "$_d/$1/index.md" ]; do [ "$_d" = / ] && _d="" || _d="$(dirname "$_d")"; done
  fi
  [ -n "$_d" ] || return 1
  local_path="$_d/$1"
}

# A hook's input (JSON on stdin, kept in $input): the first occurrence of string field $1. The top-level fields come
# before tool_input, so a value quoted inside a command never counts.
field() { printf '%s' "$input" | tr '\n' ' ' | grep -o "\"$1\" *: *\"[^\"]*\"" | head -n 1 | sed 's/.*: *"\(.*\)"$/\1/'; }

# The full ref a protected push names (protected-push.sh, push-guard/hook.sh): a branch name, or refs/tags/<tag>.
# Prints it; fails on anything else (another refs/ path, an option, a refspec, characters outside the list).
dest_ref() {
  case "$1" in ""|-*|*[!A-Za-z0-9._/-]*) return 1 ;; esac
  case "$1" in
    refs/tags/?*) git check-ref-format "$1" || return 1; printf '%s\n' "$1" ;;
    refs/*) return 1 ;;
    *) git check-ref-format --branch "$1" >/dev/null 2>&1 || return 1; printf 'refs/heads/%s\n' "$1" ;;
  esac
}

# An Away block is running in the project whose local folder is $1: its marker exists and has not expired (the
# second line, epoch seconds, as away-guard.sh writes it; anything but a past number keeps it on, fail safe).
away_active() {
  [ -f "$1/away/.away-active" ] || return 1
  _exp="$(sed -n 2p "$1/away/.away-active")"
  case "$_exp" in ""|*[!0-9]*) return 0 ;; esac
  [ "$(date +%s)" -le "$_exp" ]
}

# The one push URL of $remote must be a plain GitHub address of a private repo with no other collaborators.
# Fail closed. Sets slug (owner/repo).
private_remote() {
  command -v gh >/dev/null || die "gh is missing: cannot check $remote is private, nothing pushed"
  urls="$(git remote get-url --push --all "$remote")"
  [ "$(printf '%s\n' "$urls" | grep -c .)" = 1 ] || die "$remote pushes to several URLs: this goes to one private repo only, nothing pushed"
  slug="$(printf '%s\n' "$urls" | sed -nE 's#^(https://github\.com/|git@github\.com:|ssh://git@github\.com/)([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)$#\2#p')"
  slug="${slug%.git}"
  [ -n "$slug" ] || die "$remote pushes to $(printf '%s\n' "$urls" | sed -E 's#//[^/@]*@#//#' | plain), which is not a plain GitHub address: cannot check it is private, nothing pushed"
  [ "$(gh repo view "$slug" --json visibility -q .visibility 2>/dev/null)" = PRIVATE ] \
    || die "$slug is not private (or could not be checked): nothing pushed"
  [ "$(gh api "repos/$slug/collaborators" --jq length 2>/dev/null)" = 1 ] \
    || die "$slug has other collaborators (or could not be checked): this only goes to a repo only you can see; nothing pushed"
}
