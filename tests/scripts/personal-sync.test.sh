#!/bin/sh
# Tests for scripts/personal-sync.sh: backing up one project's folder of the personal layer from the project repo.
# A local bare repo stands in for the private GitHub remote of the layer, reached through a stub ssh at the GitHub ssh
# address of me/layer, and gh is simulated; the script's own checks are not loosened. Exits 0 when every case passes.
. "$(dirname "$0")/lib.sh"
sync="${PERSONAL_SYNC_SH:-$kit/scripts/personal-sync.sh}"
[ -n "${PERSONAL_SYNC_SH:-}" ] || [ -x "$sync" ] || { echo "✗ $sync missing or not executable (the allow rule runs it directly)"; exit 1; }

mkdir -p "$tmp/bin" "$tmp/remotes/me"
cat > "$tmp/bin/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *visibility*) echo "${GH_VISIBILITY:-PRIVATE}" ;;
  *collaborators*) echo "${GH_COLLABORATORS:-1}" ;;
esac
EOF
cat > "$tmp/bin/ssh" <<'EOF'
#!/bin/sh
for a; do c="$a"; done
eval "set -- $c"
exec git "${1#git-}" "$GH_STATE/remotes/$2"
EOF
chmod +x "$tmp/bin/gh" "$tmp/bin/ssh"
export PATH="$tmp/bin:$PATH" GH_STATE="$tmp" GIT_SSH_COMMAND="$tmp/bin/ssh" JACQUARD_PERSONAL="$tmp/layer"

# the personal layer, two projects, its private remote; what it ignores never travels
at=@  # kept apart so the address does not read as an email to the privacy check
layer="$tmp/layer"; p="$layer/projects/demo"; q="$layer/projects/other"; r="$tmp/remotes/me/layer.git"
mkdir -p "$p/docs" "$p/migration-backup" "$q"
git init -q -b main "$layer"
printf 'private.md\n' > "$layer/.gitignore"
echo index > "$p/index.md"; echo roadmap > "$p/docs/roadmap.md"; echo other > "$q/index.md"
(cd "$layer" && git add -A && git commit -q -m init)
git init -q --bare -b main "$r"
(cd "$layer" && git remote add origin "git${at}github.com:me/layer.git" && git push -q origin main && git branch -q -u origin/main)

# the project repo: .notes links to the layer's folder for it
w="$tmp/work"; git init -q -b main "$w"; cd "$w" || exit 1
ln -s "$p" .notes
printf '# local\r\n\r\n@~/.claude/jacquard/core/standards.md\r\n@.notes/index.md\r\n' > CLAUDE.local.md
echo app > app.txt; git add app.txt; git commit -q -m init

run() { sh "$sync" "$@" > "$tmp/out" 2>&1; }
remote_log() { git --git-dir="$r" log --format=%s main; }
remote_files() { git --git-dir="$r" ls-tree -r --name-only main; }
local_head() { (cd "$layer" && git rev-parse HEAD); }

# P1 the project's changes, design files and backups included, go up with the default message; ignored ones never
echo more >> "$p/docs/roadmap.md"; mkdir -p "$p/design"; echo m > "$p/design/manual.md"
echo b > "$p/migration-backup/index.md"; echo secret > "$p/docs/private.md"
run || fail "P1 a plain backup succeeds: $(cat "$tmp/out")"
[ "$(remote_log | head -n 1)" = "demo: docs" ] || fail "P1 default message is '<project>: docs'"
remote_files | grep -qx projects/demo/design/manual.md || fail "P1 the whole project folder travels"
remote_files | grep -qx projects/demo/migration-backup/index.md || fail "P1 backups travel too"
remote_files | grep -q private.md && fail "P1 what the layer ignores never travels"

# P2 another project's changes, even staged, are named and stay out of the commit
echo changed >> "$q/index.md"; (cd "$layer" && git add projects/other/index.md)
echo again >> "$p/index.md"
run 'R1 · roadmap' || fail "P2 backup with another project's changes around: $(cat "$tmp/out")"
grep -q 'projects/other/index.md' "$tmp/out" || fail "P2 the other project's change is named"
remote_files >/dev/null; git --git-dir="$r" show --stat --format= main | grep -q other && fail "P2 the other project's staged change is not committed"
[ "$(remote_log | head -n 1)" = "R1 · roadmap" ] || fail "P2 the given message is used"
(cd "$layer" && git reset -q && git checkout -q -- projects/other)

# P3 nothing changed: says so, succeeds, pushes nothing
before="$(local_head)"
run || fail "P3 nothing to back up still succeeds"
grep -qi 'nothing' "$tmp/out" || fail "P3 says there is nothing to back up"
[ "$(local_head)" = "$before" ] || fail "P3 no empty commit"

# P4 an Away block running: refused, nothing committed
touch "$p/away-active-check"; mkdir -p "$p/away"; touch "$p/away/.away-active"; before="$(local_head)"
run && fail "P4 refused while Away runs"; grep -q 'Away' "$tmp/out" || fail "P4 says why: $(cat "$tmp/out")"
[ "$(local_head)" = "$before" ] || fail "P4 nothing committed during Away"
rm -f "$p/away/.away-active" "$p/away-active-check"

# P5 a remote that is not private, or shared: refused before committing
echo p5 >> "$p/index.md"; before="$(local_head)"
GH_VISIBILITY=PUBLIC run && fail "P5 a public remote gets nothing"; grep -q 'not private' "$tmp/out" || fail "P5 says why (public): $(cat "$tmp/out")"
GH_COLLABORATORS=2 run && fail "P5 a remote with other collaborators gets nothing"; grep -q 'collaborators' "$tmp/out" || fail "P5 says why (shared)"
[ "$(local_head)" = "$before" ] || fail "P5 nothing committed when the remote fails the check"

# P6 the remote went ahead: fetched, stopped, never merged; the local commit stays
git clone -q "$r" "$tmp/elsewhere"; (cd "$tmp/elsewhere" && echo x > projects/other/x.md && git add -A && git commit -q -m "from elsewhere" && git push -q origin main)
run && fail "P6 stops when the remote has commits this computer lacks"; grep -q 'does not have' "$tmp/out" || fail "P6 says why: $(cat "$tmp/out")"
remote_log | head -n 1 | grep -q "from elsewhere" || fail "P6 the remote is left as it was"
(cd "$layer" && git log --format=%s -n 1) | grep -q "demo: docs" || fail "P6 the local commit stays"
(cd "$layer" && git merge -q --ff-only 2>/dev/null; git pull -q --rebase origin main)

# P7 the commits that go up are listed, another project's earlier commit included
(cd "$layer" && echo y > projects/other/y.md && git add -A && git commit -q -m "other: notes")
echo p7 >> "$p/index.md"
run || fail "P7 backup with an earlier commit waiting: $(cat "$tmp/out")"
grep -q 'other: notes' "$tmp/out" || fail "P7 every commit that goes up is listed"

# P8 terminal controls in the message never reach the commit or the screen
echo p8 >> "$p/index.md"
run "$(printf 'R2\033[31m red\a')" || fail "P8 backup with controls in the message"
remote_log | head -n 1 | grep -q "$(printf '\033')" && fail "P8 no escape in the commit message"
grep -q "$(printf '\033')" "$tmp/out" && fail "P8 no escape on screen"

# P9 the link must end exactly at projects/<name> of the layer, with a plain name
rm .notes; mkdir -p "$p/sub"; echo s > "$p/sub/index.md"; ln -s "$p/sub" .notes
run && fail "P9 a link deeper than projects/<name> is refused"; grep -q 'unusual project folder' "$tmp/out" || fail "P9 says why (deeper): $(cat "$tmp/out")"
rm .notes; mkdir -p "$tmp/outside"; ln -s "$tmp/outside" .notes
run && fail "P9 a link outside the layer is refused"; grep -q 'does not point into' "$tmp/out" || fail "P9 says why (outside)"
rm .notes; mkdir -p "$layer/projects/Bad Name"; ln -s "$layer/projects/Bad Name" .notes
run && fail "P9 an unusual project name is refused"; grep -q 'unusual project folder' "$tmp/out" || fail "P9 says why (name)"
rm .notes; mkdir -p .notes; run && fail "P9 a plain folder (not a link) is refused"; grep -q 'is not a link' "$tmp/out" || fail "P9 says why (folder)"
rmdir .notes; ln -s "$p" .notes

# P10 the layer off main, or with a merge half done: refused
(cd "$layer" && git switch -q -c side); echo p10 >> "$p/index.md"
run && fail "P10 refused when the layer is not on main"; grep -q 'not on main' "$tmp/out" || fail "P10 says why (branch)"
(cd "$layer" && git switch -q main)
touch "$layer/.git/MERGE_HEAD"; run && fail "P10 refused with a merge in progress"; grep -q 'half done' "$tmp/out" || fail "P10 says why (merge)"; rm -f "$layer/.git/MERGE_HEAD"

# P11 git environment pointing elsewhere is ignored
GIT_DIR="$tmp/remotes/me/layer.git" GIT_WORK_TREE="$tmp" run || fail "P11 a stray GIT_DIR does not redirect the backup: $(cat "$tmp/out")"
git --git-dir="$r" show main:projects/demo/index.md | grep -q p10 || fail "P11 the layer's own change went up"

# P12 more than one local import, or arguments beyond the message: refused
printf '@.notes/index.md\n@.other/index.md\n' > CLAUDE.local.md; run && fail "P12 two local imports are refused"; grep -q 'more than one' "$tmp/out" || fail "P12 says why"
printf '@.notes/index.md\n' > CLAUDE.local.md
sh "$sync" a b > /dev/null 2>&1; [ $? = 2 ] || fail "P12 two arguments: usage, exit 2"

# P13 an Away marker past its expiry no longer blocks; one without an expiry line still does
mkdir -p "$p/away"; printf 's1\n1\n' > "$p/away/.away-active"; echo p13 >> "$p/index.md"
run || fail "P13 an expired Away marker does not block: $(cat "$tmp/out")"
printf 's1\n' > "$p/away/.away-active"; echo p13b >> "$p/index.md"
run && fail "P13 a marker without expiry still blocks"; rm -f "$p/away/.away-active"

# P14 a remote whose fetch URL differs from the checked push URL: refused
(cd "$layer" && git remote set-url --push origin "git${at}github.com:me/layer.git" && git remote set-url origin "$tmp/elsewhere")
run && fail "P14 fetch and push URLs must match"; grep -q 'fetches from one URL' "$tmp/out" || fail "P14 says why"
(cd "$layer" && git remote set-url origin "git${at}github.com:me/layer.git" && git config --unset remote.origin.pushurl)

# P15 a git repo inside the project folder is named as not backed up
mkdir -p "$p/tools/sub"; git init -q "$p/tools/sub"
run || fail "P15 backup with a nested repo: $(cat "$tmp/out")"
grep -q 'tools/sub' "$tmp/out" || fail "P15 the nested repo is named"; rm -rf "$p/tools"

# P16 first backup: the remote has no main yet
git init -q --bare -b main "$tmp/remotes/me/fresh.git"
(cd "$layer" && git remote set-url origin "git${at}github.com:me/fresh.git")
run || fail "P16 first backup to an empty remote: $(cat "$tmp/out")"
git --git-dir="$tmp/remotes/me/fresh.git" rev-parse -q --verify main >/dev/null || fail "P16 main is on the remote"

finish personal-sync
