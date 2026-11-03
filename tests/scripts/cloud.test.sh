#!/bin/sh
# Tests for scripts/cloud.sh: the round trip computer → cloud → computer, with a local bare repo standing in for the
# private GitHub remote and a stub gh. Run from anywhere: tests/scripts/cloud.test.sh. Exits 0 when every case passes.
. "$(dirname "$0")/lib.sh"
cloud="${CLOUD_SH:-$kit/scripts/cloud.sh}"
command -v python3 >/dev/null || { echo "✗ cloud: python3 is missing"; exit 1; }
export GIT_EDITOR=true

# gh answers from the environment and remembers the default branch it was asked to set
mkdir -p "$tmp/bin"
cat > "$tmp/bin/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *visibility*) echo "${GH_VISIBILITY:-PRIVATE}" ;;
  *collaborators*) echo "${GH_COLLABORATORS:-1}" ;;
  *defaultBranchRef*) cat "$GH_STATE/default" 2>/dev/null || echo main ;;
  "repo edit"*) for a; do last="$a"; done; echo "$last" > "$GH_STATE/default" ;;
esac
EOF
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH" GH_STATE="$tmp" JACQUARD_KIT="$kit" JACQUARD_PERSONAL="$tmp/layer"
unset CLAUDE_CODE_REMOTE

# the personal layer: its own repo; what it ignores (docs/private.md) must never travel
layer="$tmp/layer"; p="$layer/projects/demo"
mkdir -p "$p/docs" "$p/roles" "$p/away"
git init -q -b main "$layer"
printf 'private.md\n' > "$layer/.gitignore"
echo prefs > "$layer/preferences.md"
echo index > "$p/index.md"; echo project > "$p/project.md"; echo profile > "$p/away-profile.md"
echo roadmap > "$p/docs/roadmap.md"; echo role > "$p/roles/qa.md"; echo 'invented private notes' > "$p/docs/private.md"
commit_layer() { (cd "$layer" && git add -A && git commit -q -m "${1:-layer}"); }
commit_layer

# the project, with its own CLAUDE.md, and its private remote
w="$tmp/work"; r="$tmp/github.com/me/demo.git"
git init -q -b main "$w"; cd "$w" || exit 1
ln -s "$p" .notes
printf '# local\n\n@~/.claude/jacquard/core/standards.md\n@.notes/index.md\n' > CLAUDE.local.md
printf '/.notes\n/CLAUDE.local.md\n' >> .git/info/exclude
echo '# Project instructions' > CLAUDE.md; echo one > app.txt
git add -A; git commit -q -m init
mkdir -p "$(dirname "$r")"; git init -q --bare "$r"
git remote add origin "$r"; git push -q origin main
git switch -q -c away/feat
echo two >> app.txt; git commit -q -am "R1: on the computer"
run() { sh "$cloud" "$@" > "$tmp/out" 2>&1; }
remote_has() { git --git-dir="$r" rev-parse -q --verify "refs/heads/$1" >/dev/null; }
at() { git --git-dir="$r" show "cloud/feat:$1" 2>/dev/null; }
worktrees() { git worktree list --porcelain | grep -c '^worktree '; }

# first sync up
run prepare || fail "C1 the first prepare works: $(cat "$tmp/out")"
[ "$(at CLAUDE.md)" = '# Project instructions' ] || fail "C2 the project's own CLAUDE.md reaches the cloud untouched"
at CLAUDE.local.md | grep -q '^@.cloud-kit/jacquard/core/standards.md$' || fail "C3 the kit's instructions go in CLAUDE.local.md"
at .cloud-kit/local/docs/roadmap.md >/dev/null || fail "C4 the project documents travel"
at .cloud-kit/local/docs/private.md >/dev/null && fail "C5 what the personal layer ignores never travels"
[ "$(cat "$tmp/default")" = cloud/feat ] || fail "C6 the kit branch becomes the default branch"
[ "$(worktrees)" = 1 ] || fail "C7 prepare leaves no working folder behind"

# the cloud session works: code, a document, and an edit to the project's CLAUDE.md
c="$tmp/cloud"; git clone -q -b cloud/feat "$r" "$c"; cd "$c" || exit 1
echo cloud > new.txt; git add new.txt; git commit -q -m "R2: from the cloud"
echo 'roadmap from the cloud' > .cloud-kit/local/docs/roadmap.md; echo '## from the cloud' >> CLAUDE.md
git commit -q -am "R2: docs"; git push -q origin cloud/feat
cd "$w" || exit 1
run status; grep -q 'cloud/feat: 2 cloud commit' "$tmp/out" || fail "C8 status counts the cloud's commits: $(cat "$tmp/out")"
run prepare && fail "C9 prepare refuses while the cloud has work not landed"
remote_has cloud/feat && [ "$(at new.txt)" = cloud ] || fail "C9b a refused prepare pushes nothing"

# sync down
run land || fail "C10 land works: $(cat "$tmp/out")"
[ -f new.txt ] && grep -q 'from the cloud' CLAUDE.md || fail "C11 land brings the code and the project's CLAUDE.md edit"
grep -q 'roadmap from the cloud' "$p/docs/roadmap.md" || fail "C12 land copies the documents back to the layer"
grep -q '(cloud) → ' "$tmp/out" || fail "C13 land says which local commit each cloud commit became"
run status; grep -q 'cloud/feat: in sync' "$tmp/out" || fail "C14 after land, status is in sync: $(cat "$tmp/out")"

# the loop of 2026-11-02: after land, more work here on the same files, then prepare must not conflict
echo 'and here' >> new.txt; echo '## and here' >> CLAUDE.md; git commit -q -am "R3: on the computer again"
commit_layer docs
run prepare || fail "C15 prepare after land never conflicts (the land/prepare loop): $(cat "$tmp/out")"
[ "$(at new.txt)" = "$(cat new.txt)" ] && [ "$(at CLAUDE.md)" = "$(cat CLAUDE.md)" ] || fail "C16 the cloud gets the branch's files as they are here"
run status; grep -q 'cloud/feat: in sync' "$tmp/out" || fail "C17 after prepare, nothing done here counts as not landed: $(cat "$tmp/out")"
[ "$(worktrees)" = 1 ] || fail "C18 no working folder left after a second prepare"

# the cloud pulls without conflict, works again; land brings only the new commit
cd "$c" || exit 1
git pull -q --ff-only origin cloud/feat || fail "C19 the cloud session can fast-forward to what prepare pushed"
echo 'cloud edit' > app.txt; echo x > c5.txt; git add c5.txt; git commit -q -m "R5: first"
git commit -q -am "R5: second"; git push -q origin cloud/feat
cd "$w" || exit 1
echo 'computer edit' > app.txt; git commit -q -am "R6: computer edits app"

# a land that stops halfway (the second commit conflicts), resolved by hand, then run again
run land && fail "C20 land stops on a conflicting cloud commit"
[ -f c5.txt ] || fail "C20b the commits before the conflict are applied"
run land && fail "C21 land refuses while git am is halfway: $(cat "$tmp/out")"
echo resolved > app.txt; git add app.txt; git am --continue >/dev/null 2>&1 || fail "C21b the conflict can be finished with git am --continue"
before="$(git rev-parse HEAD)"
run land || fail "C22 land runs again after a halfway stop: $(cat "$tmp/out")"
[ "$(git rev-parse HEAD)" = "$before" ] || fail "C23 commits already landed are never applied twice"
run status; grep -q 'cloud/feat: in sync' "$tmp/out" || fail "C24 status is in sync after the halfway land: $(cat "$tmp/out")"

# a prepare that fails partway (an unversioned document) leaves no working folder and pushes nothing
echo new > "$p/docs/unversioned.md"
tip="$(git --git-dir="$r" rev-parse cloud/feat)"
run prepare && fail "C25 prepare refuses documents the personal layer does not version yet"
[ "$(worktrees)" = 1 ] || fail "C26 a failed prepare leaves no working folder"
[ "$(git --git-dir="$r" rev-parse cloud/feat)" = "$tip" ] || fail "C27 a failed prepare pushes nothing"
rm "$p/docs/unversioned.md"

# a folder left open by an older version is named with the command that closes it, and does not block
git worktree add -q -b cloud/feat "$tmp/stale" HEAD
run prepare || fail "C28 an old leftover folder does not block prepare: $(cat "$tmp/out")"
grep -q "git worktree remove --force $tmp/stale" "$tmp/out" || fail "C29 the leftover folder is named with the command that closes it"
git worktree remove --force "$tmp/stale"

# the remote must be private and only the user's
git switch -q -c away/other
env GH_VISIBILITY=PUBLIC sh "$cloud" prepare >/dev/null 2>&1 && fail "C30 a public remote gets nothing"
env GH_COLLABORATORS=2 sh "$cloud" prepare >/dev/null 2>&1 && fail "C31 a remote with other collaborators gets nothing"
remote_has cloud/other && fail "C32 nothing reached the refused remotes"

# a branch that tracks a path the kit writes is refused
mkdir -p .claude/skills/x; echo s > .claude/skills/x/SKILL.md; git add .claude; git commit -q -m "own skill"
run prepare && fail "C33 a branch that tracks .claude/skills is refused"
grep -q '.claude/skills' "$tmp/out" || fail "C34 the refusal names the path"

# never inside a cloud session
env CLAUDE_CODE_REMOTE=true sh "$cloud" status >/dev/null 2>&1 && fail "C35 cloud.sh refuses to run inside a cloud session"
git switch -q away/feat

# a cloud branch from the older format (kit in CLAUDE.md): its CLAUDE.md is never landed as the project's
cd "$c" || exit 1
git pull -q --ff-only origin cloud/feat
git rm -q CLAUDE.local.md; echo '# Jacquard (cloud session kit)' > CLAUDE.md
git commit -q -am "Jacquard cloud kit: sync point from away/feat (older format)"
echo '- a cloud note' >> CLAUDE.md; echo y > c7.txt; git add c7.txt; git commit -q -am "R7: cloud"; git push -q origin cloud/feat
cd "$w" || exit 1
run land || fail "C36 land works from an older-format sync point: $(cat "$tmp/out")"
[ -f c7.txt ] && ! grep -q 'cloud note' CLAUDE.md || fail "C37 from the older format, the kit's CLAUDE.md never lands"

finish "cloud"
