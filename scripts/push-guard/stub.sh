# Jacquard push guard, sourced by push-guard.sh: what the pre-push stub says and where it goes. One definition for
# install (writes it) and check (compares the installed one with what install would write now). Needs common.sh,
# run from the repo's top folder with local_dir set (local_folder).

# The kit's files the stub pins: what authorizes a push. A change to any stops Claude's pushes until install runs again.
pinned="scripts/push-guard/hook.sh scripts/protected-push.sh scripts/common.sh"

# branches_on <label>: the names in backticks on project.md › Git's line that starts with "- **<label>"
branches_on() { sed -n "s/^- \*\*$1[^:]*://p" "$local_dir/project.md" 2>/dev/null | head -n 1 | grep -o '`[^`]*`' | tr -d '`' | tr '\n' ' '; }

# read_values: the main branch and the free branches from <local>/project.md › Git. Sets main, free.
# No main branch named: main (everything not free is protected anyway). A free branch is never main, master, the main
# branch (in any case) or a branch on the "Branches that publish or deploy" line.
read_values() {
  main="$(sed -nE 's/^- \*\*(Shared m|M)ain branch:\*\* *`?([A-Za-z0-9._\/-]+).*/\2/p' "$local_dir/project.md" 2>/dev/null | head -n 1)"
  main="${main:-main}"
  free="$(branches_on 'Free branches\*\*')"; free="${free% }"
  publish=" $(branches_on 'Branches that publish or deploy\*\*')$(branches_on 'Branches only the user pushes')"
  lc_main="$(printf '%s' "$main" | tr 'A-Z' 'a-z')"
  git check-ref-format --branch "$main" >/dev/null 2>&1 || die "project.md › Git names an unusual main branch: $(printf '%s' "$main" | plain)"
  for b in $free; do
    case "$b" in *[!A-Za-z0-9._/-]*) die "project.md › Git: unusual free branch name $(printf '%s' "$b" | plain)" ;; esac
    git check-ref-format --branch "$b" >/dev/null 2>&1 || die "project.md › Git: unusual free branch name $b"
    case "$(printf '%s' "$b" | tr 'A-Z' 'a-z')" in main|master|"$lc_main")
      die "project.md › Git lists $b as a free branch: the main branch always asks, nothing installed" ;; esac
    case "$publish " in *" $b "*) die "project.md › Git lists $b both as free and as a branch that publishes: nothing installed" ;; esac
  done
}

# hook_target: where git looks for pre-push. Sets target and husky (1 when husky v9 runs the hooks). Any other
# core.hooksPath: refuse (git would never run a stub written elsewhere).
hook_target() {
  hp="$(git config --get core.hooksPath)"
  case "$hp" in
    "") husky=0; target="$(cd "$(git rev-parse --git-common-dir)" && pwd -P)/hooks/pre-push" ;;
    .husky/_) husky=1; target="$(pwd -P)/.husky/pre-push" ;;
    *) die "core.hooksPath is $(printf '%s' "$hp" | plain): git would not run the push guard there" ;;
  esac
}

# The tool that checks sha256 sums, by absolute path (the stub runs with PATH=/usr/bin:/bin).
sum_tool() {
  if [ -x /usr/bin/sha256sum ]; then echo "/usr/bin/sha256sum"; elif [ -x /usr/bin/shasum ]; then echo "/usr/bin/shasum -a 256"
  else die "no sha256sum or shasum in /usr/bin: cannot pin the kit's files"; fi
}
# The pinned files' sum lines as the tool prints them, each in single quotes, on one line (paths have no quotes)
sums_quoted() { for f in $pinned; do $tool "$kit/$f"; done | sed "s/.*/'&'/" | tr '\n' ' '; }
# Pinned in the stub's comments, compared by check: husky's own runner files, and every remote's URL (a sum, so a URL
# with a token in it is never written down)
husky_sums() { [ "$husky" = 1 ] || return 0; $tool .husky/_/h .husky/_/pre-push | awk '{ printf "%s ", $1 }'; }
remotes_sum() { git config --get-regexp '^remote\..*\.url$' | sort | $tool | cut -d' ' -f1; }

# stub_kind: what the file at $target is. 0: a Jacquard stub (its privacy line sets privacy=1), 1: the kit repo's old
# privacy stub (sets privacy=1), 2: someone else's hook.
stub_kind() {
  if sed -n 2p "$target" | grep -q '^# Jacquard push guard:'; then grep -q "/scripts/hooks/pre-push' " "$target" && privacy=1; return 0; fi
  [ "$(grep -c . "$target")" = 2 ] && grep -qx 'exec ".*/\.claude/jacquard/scripts/hooks/pre-push" "\$@"' "$target" && { privacy=1; return 1; }
  return 2
}
# stub_value <name>: a value the installed stub holds (JQ_MAIN, JQ_FREE, JQ_LOCAL), or a pinned comment (husky, remotes)
stub_value() { sed -n "s/.* $1='\([^']*\)'.*/\1/p; s/^# $1: //p" "$target" | head -n 1; }

# widening: the stub install would write lets more through than the one at $target ($kind from stub_kind): another main
# branch or local folder, a new free branch, changed husky runner files or remote URLs; with no Jacquard stub there,
# any free branch or husky. Claude may only re-pin; widening asks (install --widen).
widening() {
  if [ "$kind" != 0 ]; then [ -n "$free" ] || [ "$husky" = 1 ]; return; fi
  [ "$(stub_value JQ_MAIN)" = "$main" ] && [ "$(stub_value JQ_LOCAL)" = "$(pwd -P)/$local_dir" ] || return 0
  [ "$(stub_value husky)" = "$(husky_sums)" ] && [ "$(stub_value remotes)" = "$(remotes_sum)" ] || return 0
  old=" $(stub_value JQ_FREE) "
  for b in $free; do case "$old" in *" $b "*) ;; *) return 0 ;; esac; done
  return 1
}

# stub_text <privacy 0|1> <husky sums> <remotes sum>: the stub. Its values are the paths and names validated above, in
# single quotes. The ref lines stay in memory (a file could be rewritten between the check and the push).
stub_text() {
  sh_exe="$(readlink -f /bin/sh 2>/dev/null || echo /bin/sh)"
  for v in "$kit" "$(pwd -P)/$local_dir" "$sh_exe"; do
    case "$v" in *"'"*|*'
'*) die "a path with a quote or a line break cannot go in the stub: $(printf '%s' "$v" | plain)" ;; esac
  done
  cat <<EOF
#!/bin/sh
# Jacquard push guard: written by push-guard.sh install from the installed kit and project.md › Git. Never edit it:
# /jacquard-update writes it again. A push run by Claude goes through the kit's check; yours from a terminal does not.
# husky: $2
# remotes: $3
PATH=/usr/bin:/bin
export PATH
in="\$(cat)"
if [ -n "$(for m in $claude_markers; do printf '${%s:-}' "$m"; done)" ]; then
  printf '%s\n' $(sums_quoted) | $tool -c --status - 2>/dev/null ||
    { echo "✗ Jacquard push guard: the installed kit changed since this hook was written: push refused. Run /jacquard-update, or push from your terminal." >&2; exit 1; }
  printf '%s\n' "\$in" | JQ_MAIN='$main' JQ_FREE='$free' JQ_LOCAL='$(pwd -P)/$local_dir' JQ_SH_EXE='$sh_exe' /bin/sh '$kit/scripts/push-guard/hook.sh' "\$@" || exit 1
fi
EOF
  [ "$1" = 1 ] && printf "printf '%%s\\\\n' \"\$in\" | '%s/scripts/hooks/pre-push' \"\$@\"\n" "$kit"
  return 0
}
