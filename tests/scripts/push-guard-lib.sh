# Shared setup for the push guard tests (push-guard.test.sh, bash-guard.test.sh). Sourced after lib.sh.
# Gives: kc (a copy of the kit, so a test may change its files), r (the current project), new_project, commit_on,
# agent, away_on, away_off, husky_init, pm_edit; sc runs the copy's push-guard.sh.
unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT JACQUARD_AGENT CLAUDE_CODE_REMOTE CLAUDE_PROJECT_DIR CLAUDE_CODE_SESSION_ID
export HOME="$tmp/home"; mkdir -p "$HOME"
kc="$tmp/kit"; mkdir -p "$kc"; cp -R "$kit/scripts" "$kit/CHANGELOG.md" "$kc/"
script="$kc/scripts/push-guard.sh"
n=0

# new_project <name> [free branches as project.md writes them]: a repo with a local folder and a bare remote; cd there
new_project() {
  r="$tmp/$1"; git init -q -b main "$r" && cd "$r" || exit 1
  mkdir -p .jacquard; printf '@.jacquard/index.md\n' > CLAUDE.local.md; echo idx > .jacquard/index.md
  printf '## Git\n\n- **Main branch:** main · **origin:** own private\n- **Free branches** (Claude pushes them without asking): %s\n' \
    "${2:-\`dev\`, \`demo\`}" > .jacquard/project.md
  printf '/.jacquard\n/CLAUDE.local.md\n' >> .git/info/exclude
  echo a > a.txt; git add a.txt; git commit -qm one
  git init -q --bare "$tmp/$1.git"; git remote add origin "$tmp/$1.git"; git push -q origin main 2>/dev/null
}
# commit_on <branch>: a new commit on that branch (created from the current one when missing)
commit_on() {
  git switch -q "$1" 2>/dev/null || git switch -q -c "$1" || return 1
  n=$((n + 1)); echo "$1 $n" >> f.txt; git add f.txt; git commit -qm "c$n"
}
# pm_edit <sed script>: edit the current project's project.md in place
pm_edit() { sed "$1" .jacquard/project.md > "$tmp/pm" && cp "$tmp/pm" .jacquard/project.md; }
# agent <command…>: run it as Claude does (Claude Code sets CLAUDECODE in its commands)
agent() { CLAUDECODE=1 "$@"; }
away_on() { mkdir -p "$r/.jacquard/away"; printf 's1\n%s\n' $(( $(date +%s) + 3600 )) > "$r/.jacquard/away/.away-active"; }
away_off() { rm -f "$r/.jacquard/away/.away-active"; }
# husky_init: husky v9's layout in miniature: core.hooksPath .husky/_, whose hooks run .husky/<hook> with sh -e
husky_init() {
  mkdir -p .husky/_
  printf '#!/usr/bin/env sh\n. "$(dirname "$0")/h"\n' > .husky/_/pre-push
  printf '#!/usr/bin/env sh\nn=$(basename "$0")\ns=$(dirname "$(dirname "$0")")/$n\n[ ! -f "$s" ] && exit 0\nsh -e "$s" "$@"\n' > .husky/_/h
  chmod +x .husky/_/pre-push .husky/_/h
  git config core.hooksPath .husky/_
}
