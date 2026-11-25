# Jacquard push guard, sourced by push-guard.sh: what the pre-push stub says and where it goes. One definition for
# install (writes it) and check (compares the installed one with what install would write now). Needs common.sh,
# run from the repo's top folder with local_dir set (local_folder).

# The kit's files the stub pins: what authorizes a push. A change to any stops Claude's pushes until install runs again.
pinned="scripts/push-guard/hook.sh scripts/protected-push.sh scripts/common.sh"

# read_values: the main branch and the free branches from <local>/project.md › Git. Sets main, free.
# No main branch named: main (everything not free is protected anyway). Free branches: the names in backticks on the
# "Free branches" line; never main, master or the main branch, in any case.
read_values() {
  pm="$local_dir/project.md"
  main="$(sed -nE 's/^- \*\*(Shared m|M)ain branch:\*\* *`?([A-Za-z0-9._\/-]+).*/\2/p' "$pm" 2>/dev/null | head -n 1)"
  main="${main:-main}"
  free="$(sed -n 's/^- \*\*Free branches\*\*[^:]*://p' "$pm" 2>/dev/null | head -n 1 | grep -o '`[^`]*`' | tr -d '`' | tr '\n' ' ')"
  free="${free% }"
  lc_main="$(printf '%s' "$main" | tr 'A-Z' 'a-z')"
  git check-ref-format --branch "$main" >/dev/null 2>&1 || die "project.md › Git names an unusual main branch: $(printf '%s' "$main" | plain)"
  for b in $free; do
    case "$b" in *[!A-Za-z0-9._/-]*) die "project.md › Git: unusual free branch name $(printf '%s' "$b" | plain)" ;; esac
    git check-ref-format --branch "$b" >/dev/null 2>&1 || die "project.md › Git: unusual free branch name $b"
    case "$(printf '%s' "$b" | tr 'A-Z' 'a-z')" in main|master|"$lc_main")
      die "project.md › Git lists $b as a free branch: the main branch always asks, nothing installed" ;; esac
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
sums_of() { (cd "$kit" && for f in $pinned; do $tool "$kit/$f"; done) | awk '{ print $1 "  " $2 }'; }

# husky_sums: sums of husky's own runner files, pinned in the stub at install (check compares them).
husky_sums() { [ "$husky" = 1 ] || return 0; $tool .husky/_/h .husky/_/pre-push | awk '{ printf "%s ", $1 }'; }

# stub_text <privacy 0|1> <husky sums>: the stub. Its values are the paths and names validated above, in single quotes.
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
PATH=/usr/bin:/bin
export PATH
in="\$(mktemp)" || exit 1
trap 'rm -f "\$in"' EXIT
cat > "\$in"
if [ -n "\${CLAUDECODE:-}\${CLAUDE_CODE_ENTRYPOINT:-}\${JACQUARD_AGENT:-}" ]; then
  printf '%s\n' '$(sums_of | sed -n 1p)' '$(sums_of | sed -n 2p)' '$(sums_of | sed -n 3p)' | $tool -c --status - 2>/dev/null ||
    { echo "✗ Jacquard push guard: the installed kit changed since this hook was written: push refused. Run /jacquard-update, or push from your terminal." >&2; exit 1; }
  JQ_MAIN='$main' JQ_FREE='$free' JQ_LOCAL='$(pwd -P)/$local_dir' JQ_SH_EXE='$sh_exe' /bin/sh '$kit/scripts/push-guard/hook.sh' "\$@" < "\$in" || exit 1
fi
EOF
  [ "$1" = 1 ] && printf "'%s/scripts/hooks/pre-push' \"\$@\" < \"\$in\"\n" "$kit"
  return 0
}
