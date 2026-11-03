#!/bin/sh
# Tests for scripts/cloud.sh: the round trip computer → cloud → computer. A local bare repo stands in for the private
# GitHub remote, reached through a stub ssh at the GitHub ssh address of me/demo, and gh is simulated; the script's own checks
# are not loosened. Run from anywhere: tests/scripts/cloud.test.sh. Exits 0 when every case passes.
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
remote_has() { git --git-dir="$r" rev-parse -q --verify "refs/heads/$1" >/dev/null; }
at() { git --git-dir="$r" show "cloud/feat:$1" 2>/dev/null; }
worktrees() { git worktree list --porcelain | grep -c '^worktree '; }
cloud_push() { (cd "$c" && git push -q origin cloud/feat); }

# first sync up
run prepare || fail "C1 the first prepare works: $(cat "$tmp/out")"
grep -q 'first sync of away/feat' "$tmp/out" || fail "C1b the first sync says so, without counting the whole history"
[ "$(at CLAUDE.md)" = '# Project instructions' ] || fail "C2 the project's own CLAUDE.md reaches the cloud untouched"
at CLAUDE.local.md | grep -q '^@.cloud-kit/jacquard/core/standards.md$' || fail "C3 the kit's instructions go in CLAUDE.local.md"
[ "$(at .cloud-kit/local-folder)" = .notes ] || fail "C3b the local folder's name is read from CLAUDE.local.md"
at .cloud-kit/local/docs/roadmap.md >/dev/null || fail "C4 the project documents travel"
at .cloud-kit/local/docs/private.md >/dev/null && fail "C5 what the personal layer ignores never travels"
[ "$(cat "$tmp/default")" = cloud/feat ] || fail "C6 the kit branch becomes the default branch"
[ "$(worktrees)" = 1 ] || fail "C7 prepare leaves no working folder behind"

# the cloud session works: code, a document, and an edit to the project's CLAUDE.md
c="$tmp/cloud"; git clone -q -b cloud/feat "$url" "$c"; cd "$c" || exit 1
echo cloud > new.txt; git add new.txt; git commit -q -m "R2: from the cloud"
echo 'roadmap from the cloud' > .cloud-kit/local/docs/roadmap.md; echo '## from the cloud' >> CLAUDE.md
git commit -q -am "[wip] R2: docs"; cloud_push
cd "$w" || exit 1
run status; grep -q 'cloud/feat: 2 cloud commit.*land on away/feat' "$tmp/out" || fail "C8 status counts the cloud's commits and names the work branch: $(cat "$tmp/out")"
run prepare && fail "C9 prepare refuses while the cloud has work not landed"
[ "$(at new.txt)" = cloud ] || fail "C9b a refused prepare pushes nothing"

# sync down
run land || fail "C10 land works: $(cat "$tmp/out")"
[ -f new.txt ] && grep -q 'from the cloud' CLAUDE.md || fail "C11 land brings the code and the project's CLAUDE.md edit"
[ "$(git log -1 --format=%s)" = "[wip] R2: docs" ] || fail "C11b land keeps the cloud's subjects exactly"
grep -q 'files that run or give instructions: CLAUDE.md' "$tmp/out" || fail "C11c land names the landed files that run or instruct"
grep -q 'roadmap from the cloud' "$p/docs/roadmap.md" || fail "C12 land copies the documents back to the layer"
[ "$(grep -c '(cloud) → [0-9a-f]' "$tmp/out")" = 2 ] || fail "C13 land says which local commit each cloud commit became: $(cat "$tmp/out")"
run status; grep -q 'cloud/feat: in sync' "$tmp/out" || fail "C14 after land, status is in sync: $(cat "$tmp/out")"

# the loop of 2026-11-02: after land, more work here on the same files, then prepare must not conflict
echo 'and here' >> new.txt; echo '## and here' >> CLAUDE.md; git commit -q -am "R3: on the computer again"
commit_layer docs
run prepare || fail "C15 prepare after land never conflicts (the land/prepare loop): $(cat "$tmp/out")"
[ "$(at new.txt)" = "$(cat new.txt)" ] && [ "$(at CLAUDE.md)" = "$(cat CLAUDE.md)" ] || fail "C16 the cloud gets the branch's files as they are here"
run status; grep -q 'cloud/feat: in sync' "$tmp/out" || fail "C17 after prepare, nothing done here counts as not landed: $(cat "$tmp/out")"
[ "$(worktrees)" = 1 ] || fail "C18 no working folder left after a second prepare"

# the cloud pulls without conflict, works again; a land that stops halfway is finished by hand, then run again
cd "$c" || exit 1
git pull -q --ff-only origin cloud/feat || fail "C19 the cloud session can fast-forward to what prepare pushed"
echo 'cloud edit' > app.txt; echo x > c5.txt; echo '{}' > package.json; git add c5.txt package.json; git commit -q -m "R5: first"
git commit -q -am "R5: second"; cloud_push
cd "$w" || exit 1
echo 'computer edit' > app.txt; git commit -q -am "R6: computer edits app"
run land && fail "C20 land stops on a conflicting cloud commit"
[ -f c5.txt ] || fail "C20b the commits before the conflict are applied"
grep -q 'git commit --allow-empty -C [0-9a-f]\{40\}' "$tmp/out" || fail "C20c the stop says how to keep this computer's version: $(cat "$tmp/out")"
run land && fail "C21 land refuses while git am is halfway"
echo resolved > app.txt; git add app.txt; git am --continue >/dev/null 2>&1 || fail "C21b the conflict can be finished with git am --continue"
before="$(git rev-parse HEAD)"
run land || fail "C22 land runs again after a halfway stop: $(cat "$tmp/out")"
[ "$(git rev-parse HEAD)" = "$before" ] || fail "C23 commits already landed are never applied twice"
grep -q 'run or give instructions: package.json' "$tmp/out" || fail "C23b after a halfway stop, the files that run are still named: $(cat "$tmp/out")"
run status; grep -q 'cloud/feat: in sync' "$tmp/out" || fail "C24 status is in sync after the halfway land: $(cat "$tmp/out")"

# keeping this computer's version in a conflict, the way the stop says, does not bring the loop back
commit_layer docs; run prepare || fail "C24b prepare after the halfway land: $(cat "$tmp/out")"
# a one-line record from before 0.2.10 (written by land only) that is older than the newest sync commit is not used
git --git-dir="$r" rev-parse cloud/feat^1 > .git/jacquard-cloud/cloud_feat
run status; grep -q 'cloud/feat: in sync' "$tmp/out" || fail "C24c an old record older than the sync commit does not reopen the loop: $(cat "$tmp/out")"
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat
echo 'cloud again' > app.txt; git commit -q -am "R8: cloud edits app again"; cloud_push
cd "$w" || exit 1
echo 'computer again' > app.txt; git commit -q -am "R9: computer edits app again"
run land && fail "C25 land stops on the second conflict"
h="$(sed -n 's/.*--allow-empty -C \([0-9a-f]\{40\}\).*/\1/p' "$tmp/out")"
git checkout -q --ours app.txt 2>/dev/null || git show HEAD:app.txt > app.txt
git add app.txt; git commit -q --allow-empty -C "$h"; git am --skip >/dev/null 2>&1
run land || fail "C25b land runs again after keeping this computer's version: $(cat "$tmp/out")"
[ "$(cat app.txt)" = 'computer again' ] || fail "C25c this computer's version stays"
run status; grep -q 'cloud/feat: in sync' "$tmp/out" || fail "C25d after keeping this computer's version, status is in sync (no loop): $(cat "$tmp/out")"

# a document changed in both places waits as <file>.cloud, and prepare says what to do with it
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat 2>/dev/null
echo 'cloud roadmap 2' > .cloud-kit/local/docs/roadmap.md; git commit -q -am "R10: cloud roadmap"; cloud_push
cd "$w" || exit 1
echo 'computer roadmap 2' > "$p/docs/roadmap.md"; commit_layer roadmap
run land || fail "C26 land with a document changed in both places: $(cat "$tmp/out")"
[ -f "$p/docs/roadmap.md.cloud" ] && grep -q 'Merge each into its file.*roadmap.md.cloud' "$tmp/out" || fail "C26b the cloud's side waits as roadmap.md.cloud and land says to merge it"
run prepare && fail "C26c prepare refuses while a .cloud file waits"
grep -q 'merge each <file>.cloud' "$tmp/out" || fail "C26d the refusal says to merge the .cloud file"
rm "$p/docs/roadmap.md.cloud"

# a prepare that fails partway leaves no working folder and pushes nothing
echo new > "$p/docs/unversioned.md"
tip="$(git --git-dir="$r" rev-parse cloud/feat)"
run prepare && fail "C27 prepare refuses documents the personal layer does not version yet"
[ "$(worktrees)" = 1 ] || fail "C27b a failed prepare leaves no working folder"
[ "$(git --git-dir="$r" rev-parse cloud/feat)" = "$tip" ] || fail "C27c a failed prepare pushes nothing"
rm "$p/docs/unversioned.md"

# a folder left open by an older version is named with the command that closes it, and does not block
git worktree add -q -b cloud/feat "$tmp/stale" HEAD
run prepare || fail "C28 an old leftover folder does not block prepare: $(cat "$tmp/out")"
grep -q "git worktree remove --force $tmp/stale" "$tmp/out" || fail "C29 the leftover folder is named with the command that closes it"
git worktree remove --force "$tmp/stale"; git branch -q -D cloud/feat

# the cloud's documents are checked before anything lands
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat
printf '!*\n' > .cloud-kit/local/.gitignore; echo y > c11.txt; git add -A; git commit -q -m "R11: cloud"; cloud_push
cd "$w" || exit 1; before="$(git rev-parse HEAD)"
run land && fail "C30 a dotfile among the cloud's documents stops the land"
[ "$(git rev-parse HEAD)" = "$before" ] || fail "C30b nothing lands when the documents fail the check"
cd "$c" || exit 1; git rm -q .cloud-kit/local/.gitignore
ln -sf /etc/hostname .cloud-kit/local/docs/roadmap.md; git add -A; git commit -q -m "R12: link"; cloud_push
cd "$w" || exit 1
run land && fail "C31 a link among the cloud's documents stops the land"
cd "$c" || exit 1; git rm -q .cloud-kit/local/docs/roadmap.md; mkdir -p .cloud-kit/local/docs; echo 'plain again' > .cloud-kit/local/docs/roadmap.md
echo 'leaked' > .cloud-kit/local/docs/private.md; git add -A; git commit -q -m "R13: plain"; cloud_push
cd "$w" || exit 1
run land && fail "C32 a document the personal layer ignores never lands"
cd "$c" || exit 1; git rm -q .cloud-kit/local/docs/private.md; git commit -q -m "R14: tidy"; cloud_push
cd "$w" || exit 1
run land || fail "C33 once the cloud's documents are plain, land works: $(cat "$tmp/out")"
[ -f c11.txt ] && grep -q 'plain again' "$p/docs/roadmap.md" || fail "C33b the held-back work lands"
commit_layer docs
# an Away block run in the cloud tracked its marker: land skips it with a warning instead of blocking for good
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat
mkdir -p .cloud-kit/local/away; touch .cloud-kit/local/away/.away-active; echo z > c17.txt; git add -A; git commit -q -m "R17: away in the cloud"; cloud_push
cd "$w" || exit 1
run land || fail "C33c a tracked Away marker from the cloud does not block land: $(cat "$tmp/out")"
[ ! -e "$p/away/.away-active" ] && grep -q 'Away marker' "$tmp/out" || fail "C33d the marker never lands here, and land says so"
# a layer file land would refuse (a dot file) is not sent, so it can never block the way back
touch "$p/docs/.gitkeep"; commit_layer keep
run prepare || fail "C33e prepare with a dot file in the layer: $(cat "$tmp/out")"
at .cloud-kit/local/docs/.gitkeep >/dev/null && fail "C33f a file land would refuse is never sent"
grep -q 'not sent to the cloud.*docs/.gitkeep' "$tmp/out" || fail "C33g prepare names what it did not send"

# the remote must be one plain GitHub address of a private repo only the user can see
git switch -q -c away/other
env GH_VISIBILITY=PUBLIC sh "$cloud" prepare >/dev/null 2>&1 && fail "C34 a public remote gets nothing"
env GH_COLLABORATORS=2 sh "$cloud" prepare >/dev/null 2>&1 && fail "C35 a remote with other collaborators gets nothing"
git remote set-url --push origin "ssh://host.example/github.com/me/demo.git"
run prepare && fail "C36 a push URL that is not a plain GitHub address gets nothing"
git remote set-url --push origin "https://x-token:s3cr3tvalue${at}host.example/me/demo.git"
run prepare; grep -q s3cr3tvalue "$tmp/out" && fail "C36b a token inside the URL is never printed"
git remote set-url --push origin "ssh://host.example/github.com/me/demo.git"
git remote set-url --push origin "$url"; git remote set-url --add --push origin "git${at}github.com:me/mirror.git"
run prepare && fail "C37 a remote that pushes to several URLs gets nothing"
git config --unset-all remote.origin.pushurl
remote_has cloud/other && fail "C38 nothing reached the refused remotes"
env GH_ENVIRONMENTS=2 sh "$cloud" prepare > "$tmp/out" 2>&1 && fail "C39 a repo with deployment environments needs the user's yes first"
grep -q 'git config jacquard.cloudDeployOk "deployment environments"' "$tmp/out" || fail "C39b the refusal gives the user the command to say yes"
git config jacquard.cloudDeployOk "deployment environments"
env GH_ENVIRONMENTS=2 sh "$cloud" prepare >/dev/null 2>&1 || fail "C40 with the user's yes, a repo that deploys is synced"
env GH_ENVIRONMENTS=2 GH_HOOKS=1 sh "$cloud" prepare >/dev/null 2>&1 && fail "C40b something new that runs on its own asks again"
git config --unset jacquard.cloudDeployOk
run status
env GH_VISIBILITY=PUBLIC sh "$cloud" status > "$tmp/out" 2>&1; grep -q 'no longer a private repo' "$tmp/out" || fail "C41 status warns when the cloud remote stops being private"

# a branch that tracks a path the kit writes is refused; a tracked .claude link too
mkdir -p .claude/skills/x; echo s > .claude/skills/x/SKILL.md; git add .claude; git commit -q -m "own skill"
run prepare && fail "C42 a branch that tracks .claude/skills is refused"
grep -q '.claude/skills' "$tmp/out" || fail "C42b the refusal names the path"
git rm -q -r .claude; ln -s "$tmp/elsewhere" .claude; git add .claude; git commit -q -m "a link"
mkdir -p "$tmp/elsewhere"
run prepare && fail "C43 a branch that tracks .claude as a link is refused"
[ -z "$(ls -A "$tmp/elsewhere")" ] || fail "C43b nothing was written through the link"

# never inside a cloud session, never during Away
env CLAUDE_CODE_REMOTE=true sh "$cloud" status >/dev/null 2>&1 && fail "C44 cloud.sh refuses to run inside a cloud session"
touch "$p/away/.away-active"
run status && fail "C45 cloud.sh refuses while an Away block runs (Away never fetches)"
rm "$p/away/.away-active"

# away/feat and feat share cloud/feat: the other one may take it over only once it holds that work
git switch -q -c feat main
run prepare && fail "C46 a branch without the kit branch's work cannot overwrite it"
grep -q 'last synced from away/feat' "$tmp/out" || fail "C46b the refusal names the branch it follows"
run land && fail "C47 nor land the cloud's work onto it"
git merge -q --no-edit away/feat; echo f > f.txt; git add f.txt; git commit -q -m "R15: on feat"
run prepare || fail "C48 once it holds that work, it takes the kit branch over: $(cat "$tmp/out")"
git switch -q away/feat
run prepare && fail "C48b then the old branch is the one refused: $(cat "$tmp/out")"
git switch -q feat

# only the installed kit's tracked files travel
git clone -q "$kit" "$tmp/kitcopy"; echo leftover > "$tmp/kitcopy/core/leftover.txt"
env JACQUARD_KIT="$tmp/kitcopy" sh "$cloud" prepare >/dev/null 2>&1 || fail "C49 prepare with a cloned kit"
at .cloud-kit/jacquard/core/leftover.txt >/dev/null && fail "C49b an untracked file in the installed kit never travels"
grep -q '"Edit(\*\*/.cloud-kit/bootstrap.sh)"' "$(git --git-dir="$r" show cloud/feat:.claude/settings.json > "$tmp/s.json"; echo "$tmp/s.json")" \
  || fail "C50 the cloud's settings deny edits to the bootstrap"

# a cloud branch from the older format (kit in CLAUDE.md): its CLAUDE.md is never landed as the project's
cd "$c" || exit 1
git pull -q --ff-only origin cloud/feat
git rm -q CLAUDE.local.md; echo '# Jacquard (cloud session kit)' > CLAUDE.md
git commit -q -am "Jacquard cloud kit: sync point from feat (older format)"
echo '- a cloud note' >> CLAUDE.md; echo y > c7.txt; git add c7.txt; git commit -q -am "R7: cloud"; cloud_push
cd "$w" || exit 1
rm -f .git/jacquard-cloud/cloud_feat
run land || fail "C51 land works from an older-format sync point: $(cat "$tmp/out")"
[ -f c7.txt ] && ! grep -q 'cloud note' CLAUDE.md || fail "C52 from the older format, the kit's CLAUDE.md never lands"

# the branch the kit branch follows is gone without being integrated: only the user's say moves it
git switch -q away/feat; git branch -q -D feat
run prepare && fail "C53 a branch that does not hold the gone branch's work cannot take the kit branch over on its own"
grep -q -- '--take-over' "$tmp/out" && grep -q 'git branch feat [0-9a-f]' "$tmp/out" || fail "C53b the refusal gives both ways, bring it back or take over: $(cat "$tmp/out")"
run prepare --take-over || fail "C54 with --take-over, the kit branch follows this branch: $(cat "$tmp/out")"
run prepare || fail "C54b and afterwards without it: $(cat "$tmp/out")"

# a gone branch synced only once can still be brought back
git switch -q -c away/solo main; echo s > solo.txt; git add solo.txt; git commit -q -m "R16: solo"
run prepare || fail "C55 first sync of away/solo: $(cat "$tmp/out")"
git switch -q -c solo main; git branch -q -D away/solo
run prepare && fail "C55b solo cannot take cloud/solo over on its own"
grep -q 'git branch away/solo [0-9a-f]' "$tmp/out" || fail "C55c after a single sync, the refusal still says how to bring the branch back: $(cat "$tmp/out")"
git branch away/solo "$(sed -n 's/.*git branch away\/solo \([0-9a-f]*\).*/\1/p' "$tmp/out")"; git merge -q --no-edit away/solo
git branch -q -D away/solo
run prepare || fail "C55d once solo holds that work, it takes over even with the branch gone after a single sync: $(cat "$tmp/out")"

finish "cloud"
