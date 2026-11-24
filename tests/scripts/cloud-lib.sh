# Shared setup for the cloud.sh tests (cloud*.test.sh), sourced first. A local bare repo stands in for the private
# GitHub remote, reached through a stub ssh at the GitHub ssh address of me/demo, and gh is simulated; the script's own
# checks are not loosened. Leaves the shell in the project ($w) on away/feat, one commit ahead of main, nothing synced.
# Gives: cloud (the script), layer, p (the project's local folder in the layer), commit_layer, w, r, url, run, esc, nl,
# c1, bidi, raw_controls, remote_has, at, worktrees, cloud_push (once c, the cloud clone, is set).
. "$(dirname "$0")/lib.sh"
cloud="${CLOUD_SH:-$kit/scripts/cloud.sh}"
command -v python3 >/dev/null || { echo "✗ cloud: python3 is missing"; exit 1; }
export GIT_EDITOR=true

# gh answers from the environment and remembers the default branch it was asked to set
mkdir -p "$tmp/bin" "$tmp/remotes/me"
cat > "$tmp/bin/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *visibility*) echo "${GH_VISIBILITY:-PRIVATE}" ;;
  *collaborators*) echo "${GH_COLLABORATORS:-1}" ;;
  *environments*) echo "${GH_ENVIRONMENTS:-0}" ;;
  *hooks*) echo "${GH_HOOKS:-0}" ;;
  *defaultBranchRef*) cat "$GH_STATE/default" 2>/dev/null || echo main ;;
  "repo edit"*) for a; do last="$a"; done; echo "$last" > "$GH_STATE/default" ;;
esac
EOF
# ssh to github.com runs the git command on the local bare repo with the same path
cat > "$tmp/bin/ssh" <<'EOF'
#!/bin/sh
for a; do c="$a"; done
eval "set -- $c"
exec git "${1#git-}" "$GH_STATE/remotes/$2"
EOF
chmod +x "$tmp/bin/gh" "$tmp/bin/ssh"
export PATH="$tmp/bin:$PATH" GH_STATE="$tmp" GIT_SSH_COMMAND="$tmp/bin/ssh" JACQUARD_KIT="$kit" JACQUARD_PERSONAL="$tmp/layer"
unset CLAUDE_CODE_REMOTE

# the personal layer: its own repo; what it ignores (docs/private.md) must never travel
layer="$tmp/layer"; p="$layer/projects/demo"
mkdir -p "$p/docs" "$p/roles" "$p/away"
git init -q -b main "$layer"
printf 'private.md\n' > "$layer/.gitignore"
echo prefs > "$layer/preferences.md"
echo index > "$p/index.md"; echo project > "$p/project.md"; echo profile > "$p/away-profile.md"
echo roadmap > "$p/docs/roadmap.md"; echo role > "$p/roles/qa.md"; echo 'invented private notes' > "$p/docs/private.md"
commit_layer() { (cd "$layer" && git add -A && { git diff --cached --quiet || git commit -q -m "${1:-layer}"; }); }
commit_layer

# the project, with its own CLAUDE.md, a CLAUDE.local.md with Windows line ends, and its private remote
at=@  # kept apart so the address does not read as an email to the privacy check
w="$tmp/work"; r="$tmp/remotes/me/demo.git"; url="git${at}github.com:me/demo.git"
git init -q -b main "$w"; cd "$w" || exit 1
ln -s "$p" .notes
printf '# local\r\n\r\n@~/.claude/jacquard/core/standards.md\r\n@.notes/index.md\r\n' > CLAUDE.local.md
printf '/.notes\n/CLAUDE.local.md\n' >> .git/info/exclude
echo '# Project instructions' > CLAUDE.md; echo one > app.txt
git add -A; git commit -q -m init
git init -q --bare "$r"
git remote add origin "$url"; git push -q origin main
git switch -q -c away/feat
echo two >> app.txt; git commit -q -am "R1: on the computer"
run() { sh "$cloud" "$@" > "$tmp/out" 2>&1; }
esc="$(printf '\033')"; nl='
'
c1="$(printf '\302\233')"; bidi="$(printf '\342\200\256')"   # CSI as a C1 control, and a right-to-left override
raw_controls() { grep -q "$esc" "$tmp/out" || grep -q "$(printf '\007')" "$tmp/out" || LC_ALL=C grep -q -e "$c1" -e "$bidi" "$tmp/out"; }
remote_has() { git --git-dir="$r" rev-parse -q --verify "refs/heads/$1" >/dev/null; }
at() { git --git-dir="$r" show "cloud/feat:$1" 2>/dev/null; }
worktrees() { git worktree list --porcelain | grep -c '^worktree '; }
cloud_push() { (cd "$c" && git push -q origin cloud/feat); }
