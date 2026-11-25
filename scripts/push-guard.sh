#!/bin/sh
# Jacquard push guard: a git pre-push stub that stops Claude from pushing anything but the free branches
# (project.md › Git) and the kit's work branches; the main branch, any other branch and tags go only through
# protected-push.sh, which asks first. Pushes from your own terminal are not checked.
# Usage, from the project repo:
#   push-guard.sh install [--privacy]   write the stub (never in Away). Run by Claude, it only re-pins: anything that
#                                       lets more through (a new free branch, another main branch, new remote URLs,
#                                       changed husky files, a first install with free branches) is refused
#   push-guard.sh install --widen       the same, widening allowed: its own `ask` rule, so the user says yes
#   push-guard.sh check                 is the stub in place, current, and nothing working around it
# The stub goes where git looks: the repo's shared hooks folder, or .husky/pre-push (excluded) where husky v9 runs the
# hooks. Someone else's pre-push hook is left alone: install refuses, and every push there asks. --privacy (or an old
# privacy stub found there, the kit's own repo) makes the stub run the kit's privacy check after the guard.
# Exit 0; 1 on a refusal or a failed check (the reason on stderr); 4 from check when no Jacquard stub is there (none,
# or someone else's hook); 2 on a usage error.
set -f
here="$(cd "$(dirname "$0")" && pwd -P)"
kit="$(cd "$here/.." && pwd -P)"
. "$here/common.sh"
. "$here/push-guard/stub.sh"
. "$here/push-guard/state.sh"
cmd="$1"; privacy=0; widen=0
case "$cmd:$*" in "install:install"|"check:check") ;; "install:install --privacy") privacy=1 ;; "install:install --widen") widen=1 ;;
  *) echo "usage: push-guard.sh install [--privacy | --widen] | check" >&2; exit 2 ;; esac

top="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not in a git repo"
cd "$top" || die "cannot enter $top"
local_folder
read_values
hook_target
tool="$(sum_tool)"
kind=3; if [ -e "$target" ] || [ -L "$target" ]; then stub_kind; kind=$?; fi

case "$cmd" in
  install)
    away_active "$local_dir" && die "Away is on: the push guard is installed in Present"
    [ "$kind" != 2 ] || die "$target is someone else's pre-push hook: left as it is. Every push asks here; note it in project.md › Git."
    [ "$husky" = 0 ] || { [ -f .husky/_/h ] && [ -f .husky/_/pre-push ]; } || die "core.hooksPath is .husky/_ but husky's runner files are missing"
    if is_claude && [ "$widen" = 0 ] && widening; then
      die "this install would let more through than the guard in place (free branches: ${free:-none}; or the main branch, the remotes or husky's files changed). Run ~/.claude/jacquard/scripts/push-guard.sh install --widen, which asks the user."
    fi
    mkdir -p "$(dirname "$target")" || die "cannot create $(dirname "$target")"
    tmpf="$(mktemp "$(dirname "$target")/.pre-push.XXXXXX")" || die "cannot write in $(dirname "$target")"
    stub_text "$privacy" "$(husky_sums)" "$(remotes_sum)" > "$tmpf" && chmod 555 "$tmpf" && mv -f "$tmpf" "$target" ||
      { rm -f "$tmpf"; die "could not write $target"; }
    if [ "$husky" = 1 ]; then
      ex="$(git rev-parse --git-path info/exclude)"
      grep -qx '/.husky/pre-push' "$ex" 2>/dev/null || echo '/.husky/pre-push' >> "$ex"
    fi
    echo "✓ push guard at $target · free branches: ${free:-none}, plus the kit's work branches (core/git.md › Branches); everything else through protected-push.sh"
    ;;
  check)
    [ "$kind" = 0 ] || { echo "no Jacquard push guard at $target" >&2; exit 4; }
    bad=0
    [ "$(ls -l "$target" | cut -c1-10)" = "-r-xr-xr-x" ] || { echo "$target is not read-only (555)" >&2; bad=1; }
    stub_text "$privacy" "$(stub_value husky)" "$(remotes_sum)" | cmp -s - "$target" ||
      { echo "$target differs from what install writes now (the kit, project.md › Git or a remote's URL changed)" >&2; bad=1; }
    config_redirects
    husky_state
    [ "$bad" = 0 ] || exit 1
    ;;
esac
exit 0
