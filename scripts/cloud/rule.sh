# Jacquard cloud bridge, sourced by cloud.sh: the one rule for what travels between the local folder and the cloud,
# both ways (kit.sh uses it to send, cloud.sh to land and to report).

# What travels, both ways: every file in the local folder except what the personal layer ignores and the names
# doc_problem refuses. Prints "+<file>" for each file that
# travels and "-<why>: <file>" for each left out (never one the layer ignores), relative to the local folder. A file
# deleted here and not committed yet does not travel: the cloud mirrors this computer. Call it only as
# var="$(travelling)", so that under set -e its die stops the script.
travelling() {
  all="$(git -C "$proj" -c core.quotePath=false ls-files --cached --others --exclude-standard -- .)"
  [ -n "$all" ] || return 0
  rc=0; ign="$(printf '%s\n' "$all" | git -C "$proj" -c core.quotePath=false check-ignore --no-index --stdin)" || rc=$?
  [ "$rc" -le 1 ] || die "the private-file check failed (rc=$rc): nothing done"
  printf '%s\n' "$all" | while IFS= read -r f; do
    [ -z "$ign" ] || ! printf '%s\n' "$ign" | grep -qxF -e "$f" || continue   # tracked, then ignored: never travels
    case "$f" in */) echo "-a repository inside the folder: $(printf '%s' "$f" | plain)"; continue ;; esac
    why="$(doc_problem "$f")"; [ -z "$why" ] || { echo "-$why: $(printf '%s' "$f" | plain)"; continue; }
    [ -f "$proj/$f" ] || [ -L "$proj/$f" ] || continue
    inside_local "$f" || die "a folder in $local_dir is a link out of it ($f): nothing done"
    echo "+$f"
  done
}

# A path in the local folder whose nearest existing folder, links resolved, is still inside it, with no file in the
# way of the folders it needs: what travels is read, and what lands is written or deleted, only there. Needs proj_real.
inside_local() {
  d="$(dirname "$proj/$1")"
  while [ ! -e "$d" ] && [ ! -L "$d" ]; do d="$(dirname "$d")"; done
  [ -d "$d" ] || return 1
  d="$(cd "$d" && pwd -P)" || return 1
  case "$d/" in "$proj_real"/*) ;; *) return 1 ;; esac
}

# The rule for a name that travels, both ways. Prints why not, or nothing.
# - unusual: a control character, a quote or a backslash (git quotes such names, so they arrive with a quote), a name
#   that is not valid UTF-8, or one plain would change (C1 controls, bidi overrides, in any locale);
# - a part that starts with a dot: internal marks (away/.away-active), and also .., .git, .gitignore, .gitattributes;
# - <file>.cloud: a copy waiting to be merged, on this computer only;
# - a name that looks like settings or keys (backups of settings.local.json among them).
doc_problem() {
  case "$1" in *[[:cntrl:]]*|*\"*|*\\*) echo "unusual file name"; return ;; esac
  printf '%s' "$1" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1 || { echo "unusual file name"; return; }
  [ "$(printf '%s' "$1" | plain)" = "$1" ] || { echo "unusual file name"; return; }
  case "$1" in .*|*/.*) echo "name starts with a dot"; return ;; esac
  case "$1" in *.cloud) echo "a copy waiting to be merged"; return ;; esac
  case "${1##*/}" in *settings*.json|*.pem|*.key|*.p12|*.pfx|id_*|*credential*) echo "looks like settings or keys" ;; esac
}
