# Jacquard push guard, sourced by push-guard.sh check: what could turn the guard off or send a push elsewhere without
# touching the stub. Each check prints one line on stderr and sets bad=1. Needs stub.sh's target and husky.

# Git settings that redirect a push (another destination, another URL) or bring settings from elsewhere.
config_redirects() {
  found="$(git config --get-regexp '^(remote\..*\.(push|pushurl)|url\..*\.(insteadof|pushinsteadof)|include\..*|includeif\..*)$' 2>/dev/null | cut -d' ' -f1)"
  [ -z "$found" ] || { echo "git settings redirect pushes or include other settings: $(printf '%s' "$found" | tr '\n' ' ' | plain)" >&2; bad=1; }
  found="$(git config --get-regexp '^alias\.' 2>/dev/null | grep -i 'push' | cut -d' ' -f1)"
  [ -z "$found" ] || { echo "a git alias runs push: $(printf '%s' "$found" | tr '\n' ' ' | plain)" >&2; bad=1; }
}

# husky v9 runs .husky/<hook> through its own runner, with node_modules/.bin first in PATH and a user init file sourced
# first: each of those could skip the stub. Their sums at install are on the stub's "# husky:" line.
husky_state() {
  [ "$husky" = 1 ] || return 0
  [ "$(husky_sums)" = "$(sed -n 's/^# husky: //p' "$target")" ] || { echo "husky's runner (.husky/_/h or .husky/_/pre-push) changed since install" >&2; bad=1; }
  for f in "${XDG_CONFIG_HOME:-$HOME/.config}/husky/init.sh" "$HOME/.huskyrc" node_modules/.bin/sh node_modules/.bin/git node_modules/.bin/env; do
    [ ! -e "$f" ] || { echo "$f exists: husky would run it before the push guard" >&2; bad=1; }
  done
  ! git ls-files --error-unmatch .husky/pre-push >/dev/null 2>&1 || { echo ".husky/pre-push is tracked by git: the team's own hook would replace the guard" >&2; bad=1; }
  git check-ignore -q --no-index .husky/pre-push || { echo ".husky/pre-push is not excluded from git" >&2; bad=1; }
}
