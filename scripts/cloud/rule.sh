# Jacquard cloud bridge, sourced by cloud.sh: the one rule for what travels between the local folder and the cloud,
# both ways (prepare sends by it, land takes back by it, status reports by it), and the predicates both sides share.

# What travels: every file in the local folder except what the personal layer ignores and the names doc_problem
# refuses. Prints "+<file>" for each file that travels and "-<why>: <file>" for each left out (never one the layer
# ignores), relative to the local folder, in git's order. A file deleted here and not committed yet does not travel:
# the cloud mirrors this computer. A link is named and left out. Call it only as var="$(travelling)", so that under
# set -e its die stops the script.
travelling() {
  _all="$(git -C "$proj" -c core.quotePath=false ls-files --cached --others --exclude-standard -- .)"
  [ -n "$_all" ] || return 0
  _rc=0; _ign="$(printf '%s\n' "$_all" | git -C "$proj" -c core.quotePath=false check-ignore --no-index --stdin)" || _rc=$?
  [ "$_rc" -le 1 ] || die "the private-file check failed (rc=$_rc): nothing done"
  [ -z "$_ign" ] || _all="$(printf '%s\n' "$_all" | grep -vxF -e "$_ign" || true)"   # tracked, then ignored: never travels
  _seen=""
  printf '%s\n' "$_all" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in */) echo "-a repository inside the folder: $(printf '%s' "$f" | plain)"; continue ;; esac
    _why="$(doc_problem "$f")"; [ -z "$_why" ] || { echo "-$_why: $(printf '%s' "$f" | plain)"; continue; }
    [ ! -L "$proj/$f" ] || { echo "-a link: $f"; continue; }
    [ -f "$proj/$f" ] || continue
    [ "${f%/*}" = "$_seen" ] || { inside_local "$f" || die "a folder in $local_dir is a link out of it ($f): nothing done"; _seen="${f%/*}"; }
    echo "+$f"
  done
}

# A path in the local folder whose nearest existing folder, links resolved, is still inside it, with no file in the
# way of the folders it needs: what travels is read, and what lands is written or deleted, only there. Needs proj_real.
inside_local() {
  _d="$(dirname "$proj/$1")"
  while [ ! -e "$_d" ] && [ ! -L "$_d" ]; do _d="$(dirname "$_d")"; done
  [ -d "$_d" ] || return 1
  _d="$(cd "$_d" && pwd -P)" || return 1
  case "$_d/" in "$proj_real"/*) ;; *) return 1 ;; esac
}

# The rule for a name that travels, both ways. Prints why not, or nothing.
# - unusual: a control character, a quote or a backslash (git quotes such names, so they arrive with a quote), a name
#   that is not valid UTF-8, or one plain would change (C1 controls, bidi overrides, in any locale);
# - a part that starts with a dot: internal marks (away/.away-active), and also .., .git, .gitignore, .gitattributes;
# - <file>.cloud: a copy waiting to be merged, on this computer only;
# - secret_shape.
doc_problem() {
  case "$1" in *[[:cntrl:]]*|*\"*|*\\*) echo "unusual file name"; return ;; esac
  printf '%s' "$1" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1 || { echo "unusual file name"; return; }
  [ "$(printf '%s' "$1" | plain)" = "$1" ] || { echo "unusual file name"; return; }
  case "$1" in .*|*/.*) echo "name starts with a dot"; return ;; esac
  case "$1" in *.cloud) echo "a copy waiting to be merged"; return ;; esac
  ! secret_shape "$1" || echo "looks like settings or keys"
}

# A file shaped like settings, keys or credentials (backups of settings.local.json among them), in any case; never a
# markdown document, so a plan about credentials still travels. Provisional until the user decides where the
# migration backups live.
secret_shape() {
  _b="$(printf '%s' "${1##*/}" | tr '[:upper:]' '[:lower:]')"
  case "$_b" in *.md) return 1 ;; esac
  case "$_b" in
    *settings*.json|*.pem|*.key|*.p12|*.pfx|*.jks|*.keystore|*.ppk|*.kdbx|id_rsa*|id_dsa*|id_ecdsa*|id_ed25519*) return 0 ;;
    *secret*|*credential*) return 0 ;;   # not *token*: design tokens are ordinary files
  esac
  return 1
}

# The local folder's own instruction files: what every session loads or obeys. land never deletes them and names
# them when they change.
local_instruction() {
  case "$1" in index.md|project.md|away-profile.md|roles/*) return 0 ;; esac
  return 1
}

# 0 when the personal layer ignores the local file $1, 1 when it does not; a failed check stops the script.
layer_ignored() {
  _rc=0; printf '%s\n' "$1" | git -C "$proj" check-ignore -q --no-index --stdin || _rc=$?   # --stdin: a path, never a pattern
  [ "$_rc" -le 1 ] || die "the private-file check failed (rc=$_rc): nothing more done"
  return "$_rc"
}

# The left-out entries of travelling's output ($1) worth a person's eye, one per line, capped: dot names are internal
# marks and stay silent.
left_out() { printf '%s\n' "$1" | sed -n '/^-name starts with a dot: /d; s/^-\([^:]*\): /⚠ not sent to the cloud (\1): /p' | capped; }
