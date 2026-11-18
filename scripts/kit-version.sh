#!/bin/sh
# Jacquard: which kit version each project uses, against this installed kit. It only reads.
# Usage: kit-version.sh project <index.md>   one project: one line of context when it is behind or ahead of the
#                                            installed kit, else nothing
#        kit-version.sh all [<personal layer>]  every project in <personal layer>/projects/*/index.md
#                                              (default $JACQUARD_PERSONAL, else ~/repos/jacquard-personal), one line each
# The installed version is the first "## <version>" heading of this kit's CHANGELOG.md ("## Unreleased" skipped);
# a project's is the first x.y.z after "Kit version:" in its index.md (bold marks and a leading v allowed).
# Only digits and dots from index.md ever reach the output. Exit 0, or 2 on a usage error.
here="$(cd "$(dirname "$0")/.." && pwd)"
die() { echo "kit-version: $1" >&2; exit 2; }

installed="$(awk '/^## [0-9]+\.[0-9]+\.[0-9]+/ { print $2; exit }' "$here/CHANGELOG.md" 2>/dev/null)"
# version_of <index.md>: the project's kit version, or nothing
version_of() { awk 'match($0, /Kit version\**:\**[ \t]*\**v?[0-9]+\.[0-9]+\.[0-9]+/) { s = substr($0, RSTART, RLENGTH); sub(/.*[^0-9.]/, "", s); print s; exit }' "$1" 2>/dev/null; }
# behind <a> <b>: a is an older version than b
behind() { awk -v a="$1" -v b="$2" 'BEGIN { split(a, x, "."); split(b, y, "."); for (i = 1; i <= 3; i++) { if (x[i] + 0 < y[i] + 0) exit 0; if (x[i] + 0 > y[i] + 0) exit 1 } exit 1 }'; }

case "$1" in
  project)
    [ $# = 2 ] || die "usage: kit-version.sh project <index.md>"
    [ -n "$installed" ] || exit 0
    v="$(version_of "$2")"; [ -n "$v" ] || exit 0
    if behind "$v" "$installed"; then
      echo "Jacquard: this project is on kit $v; the installed kit is $installed. Say so in one line in your first reply and offer /jacquard-update; do not run it unasked. If this session goes into Away, note it in the Away report instead of asking."
    elif behind "$installed" "$v"; then
      echo "Jacquard: this project is on kit $v, newer than the installed kit $installed, so some of its rules may be missing here. Say so in one line in your first reply: reinstall the kit at the latest tag (INSTALL.md, Updating the installed kit)."
    fi
    ;;
  all)
    [ $# -le 2 ] || die "usage: kit-version.sh all [<personal layer>]"
    layer="${2:-${JACQUARD_PERSONAL:-$HOME/repos/jacquard-personal}}"
    [ -d "$layer/projects" ] || die "no projects folder in $layer"
    echo "installed kit: ${installed:-unknown}"
    for i in "$layer"/projects/*/index.md; do
      [ -f "$i" ] || continue
      p="${i%/index.md}"; p="${p##*/}"; v="$(version_of "$i")"
      if [ -z "$v" ]; then echo "$p: no kit version in its index.md"
      elif [ -n "$installed" ] && behind "$v" "$installed"; then echo "$p: $v → $installed (run /jacquard-update there)"
      elif [ -n "$installed" ] && behind "$installed" "$v"; then echo "$p: $v, newer than the installed kit (reinstall the kit: INSTALL.md)"
      else echo "$p: $v (up to date)"; fi
    done
    ;;
  *) die "usage: kit-version.sh <project <index.md> | all [<personal layer>]>" ;;
esac
exit 0
