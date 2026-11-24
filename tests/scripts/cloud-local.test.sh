#!/bin/sh
# Tests for scripts/cloud.sh: everything in the project's local folder travels, both ways, deletions included, except
# what the personal layer ignores, dot names and unusual names; status says what did not travel. Setup in cloud-lib.sh.
# Run from anywhere: tests/scripts/cloud-local.test.sh. Exits 0 when every case passes.
. "$(dirname "$0")/cloud-lib.sh"
png() { printf '\211PNG\r\n\032\n\000\001\002%s' "$1"; }   # a small binary, NULs included

# up: every folder travels, the binary byte for byte; what the layer ignores and dot names do not
mkdir -p "$p/plans" "$p/design" "$p/away/archive" "$p/inventada/sub"
echo plan > "$p/plans/R6.md"; png 1 > "$p/design/logo.png"; echo old > "$p/away/archive/away-journal-old.md"
echo nueva > "$p/inventada/sub/notas.md"; echo notes > "$p/kit-notes.md"; echo patch > "$p/away/R1.patch"
echo 'invented secret' > "$p/inventada/private.md"; echo h > "$p/docs/.hidden.md"
commit_layer up
touch "$p/design/.DS_Store"   # not versioned, but a dot name never travels, so it does not stop prepare
run prepare || fail "L1 prepare with the whole folder: $(cat "$tmp/out")"
for f in plans/R6.md away/archive/away-journal-old.md inventada/sub/notas.md kit-notes.md away/R1.patch docs/roadmap.md; do
  at ".cloud-kit/local/$f" >/dev/null || fail "L2 $f travels"
done
at .cloud-kit/local/design/logo.png | cmp -s - "$p/design/logo.png" || fail "L3 a binary travels byte for byte"
at .cloud-kit/local/inventada/private.md >/dev/null && fail "L4 what the layer ignores never travels, in any folder"
at .cloud-kit/local/docs/.hidden.md >/dev/null && fail "L5 a dot name never travels"
at .cloud-kit/local/design/.DS_Store >/dev/null && fail "L5b an unversioned dot file neither travels nor stops prepare"
grep -q 'private.md' "$tmp/out" && fail "L5c prepare never names what the layer ignores"

# a file the layer does not version yet, in a folder that did not exist, stops prepare and pushes nothing
mkdir -p "$p/nueva"; echo n > "$p/nueva/x.md"
tip="$(git --git-dir="$r" rev-parse cloud/feat)"
run prepare && fail "L6 a new unversioned file anywhere in the folder stops prepare"
grep -q 'nueva/x.md' "$tmp/out" || fail "L6b the refusal names it: $(cat "$tmp/out")"
[ "$(git --git-dir="$r" rev-parse cloud/feat)" = "$tip" ] || fail "L6c a refused prepare pushes nothing"
commit_layer nueva
run prepare || fail "L6d once versioned, prepare works: $(cat "$tmp/out")"
at .cloud-kit/local/nueva/x.md >/dev/null || fail "L6e and it travels"
run status; grep -q 'did not travel' "$tmp/out" && fail "L7 right after prepare, status has nothing that did not travel: $(cat "$tmp/out")"

# down: a new file in a new folder, a new binary, a changed binary; deletions come back too
c="$tmp/cloud"; git clone -q -b cloud/feat "$url" "$c"; cd "$c" || exit 1
mkdir -p .cloud-kit/local/desde-nube; echo cloud > .cloud-kit/local/desde-nube/n.md
png 2 > .cloud-kit/local/design/foto.png; png 3 > .cloud-kit/local/design/logo.png
git rm -q .cloud-kit/local/plans/R6.md .cloud-kit/local/kit-notes.md .cloud-kit/local/nueva/x.md
git add -A; git commit -q -m "R2: cloud docs"; cloud_push
cd "$w" || exit 1
echo 'changed here' > "$p/kit-notes.md"; commit_layer notes   # deleted in the cloud, changed here
rm "$p/nueva/x.md"; commit_layer gone                           # deleted in both places
run land || fail "L8 land with new folders, binaries and deletions: $(cat "$tmp/out")"
[ "$(cat "$p/desde-nube/n.md" 2>/dev/null)" = cloud ] || fail "L9 a new file in a new folder lands"
png 2 | cmp -s - "$p/design/foto.png" || fail "L10 a new binary lands byte for byte"
png 3 | cmp -s - "$p/design/logo.png" || fail "L10b a binary changed only in the cloud lands"
[ ! -e "$p/plans/R6.md" ] || fail "L11 a file deleted in the cloud is deleted here"
grep -q 'plans/R6.md' "$tmp/out" || fail "L11b land names each deletion: $(cat "$tmp/out")"
[ "$(cat "$p/kit-notes.md")" = 'changed here' ] || fail "L12 a file deleted in the cloud but changed here stays"
grep -A3 'deleted in the cloud, but kept here' "$tmp/out" | grep -q 'kit-notes.md' || fail "L12b and land says so: $(cat "$tmp/out")"
commit_layer landed

# a deletion never touches what the layer now ignores, nor goes through a folder that became a link
run prepare || fail "L13 prepare after land: $(cat "$tmp/out")"
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat
git rm -q .cloud-kit/local/inventada/sub/notas.md .cloud-kit/local/away/R1.patch; git commit -q -m "R3: cloud deletes"; cloud_push
cd "$w" || exit 1
printf 'private.md\nR1.patch\n' > "$layer/.gitignore"; commit_layer ignore   # the layer now ignores it, though tracked
mv "$p/inventada" "$tmp/outside"; ln -s "$tmp/outside" "$p/inventada"
run land || fail "L14 land with an ignored file and a linked folder: $(cat "$tmp/out")"
[ -f "$p/away/R1.patch" ] || fail "L15 a deletion never removes what the layer ignores"
[ -f "$tmp/outside/sub/notas.md" ] || fail "L16 a deletion never goes through a link out of the local folder"
rm "$p/inventada"; mv "$tmp/outside" "$p/inventada"; printf 'private.md\n' > "$layer/.gitignore"; commit_layer back

# status: what changed here after the last prepare did not travel; what never travels by rule is counted, not named
run prepare || fail "L17 prepare before status: $(cat "$tmp/out")"
echo 'roadmap 2' > "$p/docs/roadmap.md"; echo extra > "$p/plans/R7.md"; commit_layer later
rm "$p/kit-notes.md"; commit_layer rm
run status || fail "L18 status: $(cat "$tmp/out")"
grep -A5 'did not travel' "$tmp/out" | grep -q 'docs/roadmap.md' || fail "L18b status names a changed file that did not travel: $(cat "$tmp/out")"
grep -A5 'did not travel' "$tmp/out" | grep -q 'plans/R7.md' || fail "L18c and a new one"
grep -A5 'did not travel' "$tmp/out" | grep -q 'kit-notes.md' || fail "L18d and one deleted here"
grep -q 'ignores' "$tmp/out" || fail "L19 status counts what the layer ignores: $(cat "$tmp/out")"
grep -q 'private.md' "$tmp/out" && fail "L19b but never names it"
echo q > "$p/docs/q\"uote.md"; commit_layer odd
run status; grep -q 'unusual file name' "$tmp/out" || fail "L19c status names files with an unusual name: $(cat "$tmp/out")"
rm "$p/docs/q\"uote.md"; commit_layer tidy

# size: one line when the folder passes the limit (25 MB unless the environment sets another)
run status; grep -q ' MB' "$tmp/out" && fail "L20 no size line under the limit: $(cat "$tmp/out")"
env JACQUARD_CLOUD_MAX_MB=0 sh "$cloud" status > "$tmp/out" 2>&1
grep -q 'over 0 MB' "$tmp/out" || fail "L20b status says when the folder passes the limit: $(cat "$tmp/out")"

# names that look like settings or keys never travel (backups of settings.local.json among them)
mkdir -p "$p/migration-backup/x"; echo '{}' > "$p/migration-backup/x/settings.local.json"; echo k > "$p/docs/deploy.pem"; commit_layer backup
run prepare || fail "L21 prepare with a settings backup: $(cat "$tmp/out")"
at .cloud-kit/local/migration-backup/x/settings.local.json >/dev/null && fail "L21b a settings file never travels"
at .cloud-kit/local/docs/deploy.pem >/dev/null && fail "L21c a key file never travels"
grep -q 'looks like settings or keys' "$tmp/out" || fail "L21d prepare names them: $(cat "$tmp/out")"

# a folder that became a link out of the local folder stops prepare: nothing outside is read
mkdir -p "$tmp/client"; echo outside > "$tmp/client/R7.md"   # the same name as the tracked plans/R7.md
mv "$p/plans" "$tmp/plans-real"; ln -s "$tmp/client" "$p/plans"
tip="$(git --git-dir="$r" rev-parse cloud/feat)"
run prepare && fail "L22 a tracked folder turned into a link out of the folder stops prepare"
grep -q -e 'beyond a symbolic link' -e 'links out of it (plans/R7.md)' "$tmp/out" || fail "L22c and says why: $(cat "$tmp/out")"
[ "$(git --git-dir="$r" rev-parse cloud/feat)" = "$tip" ] || fail "L22b and nothing is pushed"
rm "$p/plans"; mv "$tmp/plans-real" "$p/plans"

# the project's own attributes and filters never touch what travels (an LFS-like clean filter here)
git config filter.up.clean 'tr a-z A-Z'; printf '*.md filter=up\n' > .gitattributes; git add .gitattributes; git commit -q -m "attrs"
run prepare || fail "L23 prepare with a clean filter in the project: $(cat "$tmp/out")"
[ "$(at .cloud-kit/local/docs/roadmap.md)" = "$(cat "$p/docs/roadmap.md")" ] || fail "L23b documents travel byte for byte, past the project's filters"
run status; grep -q 'did not travel' "$tmp/out" && fail "L23c right after prepare, a filter does not make files look changed: $(cat "$tmp/out")"
git rm -q .gitattributes; git commit -q -m "no attrs"; git config --unset filter.up.clean

# land names local files that instruct or run: an instruction file, a new @ import, a script
run prepare || fail "L24 prepare before the instruction case: $(cat "$tmp/out")"
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat
echo 'role, weaker' > .cloud-kit/local/roles/qa.md; printf 'plan\n@../x.md\n' > .cloud-kit/local/plans/R7.md
echo 'echo hi' > .cloud-kit/local/design/capture.sh; git add -A; git commit -q -m "R4: instructions"; cloud_push
cd "$w" || exit 1
run land || fail "L24b land with instruction files: $(cat "$tmp/out")"
for f in roles/qa.md plans/R7.md design/capture.sh; do
  grep 'run or give instructions' "$tmp/out" | grep -q ".notes/$f" || fail "L24c land names .notes/$f among what runs or instructs: $(cat "$tmp/out")"
done
commit_layer instr

# a cloud-made copy waiting to be merged never lands
run prepare || fail "L25 prepare: $(cat "$tmp/out")"
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat
echo w > .cloud-kit/local/docs/roadmap.md.cloud; git add -A; git commit -q -m "R5: a .cloud"; cloud_push
cd "$w" || exit 1
run land && fail "L25b a .cloud file from the cloud stops land"
cd "$c" || exit 1; git rm -q .cloud-kit/local/docs/roadmap.md.cloud; git commit -q -m "R6: tidy"; cloud_push
cd "$w" || exit 1; run land || fail "L25c once removed, land works: $(cat "$tmp/out")"

# deletions: never an instruction file, never more than half the folder at once, never from a sync point this
# computer did not write
run prepare || fail "L26 prepare: $(cat "$tmp/out")"
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat
git rm -q .cloud-kit/local/project.md; git commit -q -m "R7: drop project.md"; cloud_push
cd "$w" || exit 1
run land || fail "L26b land: $(cat "$tmp/out")"
[ -f "$p/project.md" ] || fail "L26c an instruction file is never deleted by land"
grep -A3 'kept here' "$tmp/out" | grep -q 'project.md' || fail "L26d and land names it: $(cat "$tmp/out")"
run prepare || fail "L27 prepare: $(cat "$tmp/out")"
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat
git rm -q -r .cloud-kit/local/docs .cloud-kit/local/design .cloud-kit/local/plans .cloud-kit/local/away .cloud-kit/local/inventada .cloud-kit/local/desde-nube
git commit -q -m "R8: mass delete"; cloud_push
cd "$w" || exit 1
run land || fail "L27b land with a mass deletion: $(cat "$tmp/out")"
[ -f "$p/docs/roadmap.md" ] && [ -f "$p/design/foto.png" ] || fail "L27c a mass deletion is named, not applied"
grep -q 'more than half the folder' "$tmp/out" || fail "L27d and land says why: $(cat "$tmp/out")"
run prepare || fail "L28 prepare: $(cat "$tmp/out")"
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat
git rm -q .cloud-kit/local/docs/roadmap.md; git commit -q -m "R9: one delete"; cloud_push
cd "$w" || exit 1
sed -n 1p .git/jacquard-cloud/cloud_feat > "$tmp/rec"; cp "$tmp/rec" .git/jacquard-cloud/cloud_feat   # a record from another computer
run land || fail "L28b land from a sync point without this computer's record: $(cat "$tmp/out")"
[ -f "$p/docs/roadmap.md" ] || fail "L28c deletions wait when this computer did not write the sync point"
grep -q 'did not write the last sync point' "$tmp/out" || fail "L28d and land says why: $(cat "$tmp/out")"

# more deletions than the limit at once are named, not applied, even when they are less than half the folder
mkdir -p "$p/lote"; i=0; while [ $i -lt 45 ]; do echo "$i" > "$p/lote/f$i.md"; i=$((i + 1)); done; commit_layer lote
run prepare || fail "L29 prepare with many files: $(cat "$tmp/out")"
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat
i=0; while [ $i -lt 21 ]; do git rm -q ".cloud-kit/local/lote/f$i.md"; i=$((i + 1)); done; git commit -q -m "R10: 21 deletes"; cloud_push
cd "$w" || exit 1
run land || fail "L29b land: $(cat "$tmp/out")"
[ -f "$p/lote/f0.md" ] && grep -q 'more than the 20' "$tmp/out" || fail "L29c past the limit, deletions are named, not applied: $(cat "$tmp/out")"
i=0; while [ $i -lt 21 ]; do rm "$p/lote/f$i.md"; i=$((i + 1)); done; commit_layer by-hand   # the user deletes them by hand

# what the cloud sends that this computer does not take back is skipped and counted, and the rest lands; a plan about
# credentials is an ordinary document; a file landed but not backed up yet is never deleted; inline @ imports and
# executables are named
echo 'plan' > "$p/plans/credential-rotation.md"; commit_layer cred
run prepare || fail "L30 prepare: $(cat "$tmp/out")"
at .cloud-kit/local/plans/credential-rotation.md >/dev/null || fail "L30b a markdown plan about credentials travels"
grep -q 'first time in the cloud' "$tmp/out" && grep -q 'plans/credential-rotation.md' "$tmp/out" || fail "L30c prepare names what reaches the cloud for the first time: $(cat "$tmp/out")"
cd "$c" || exit 1; git pull -q --ff-only origin cloud/feat
echo '{}' > .cloud-kit/local/docs/Client_Secret.json; mkdir -p .cloud-kit/local/nueva2; echo leak > .cloud-kit/local/nueva2/private.md
echo 'see @../y.md' > .cloud-kit/local/plans/inline.md; mkdir -p .cloud-kit/local/tools; echo 'echo' > .cloud-kit/local/tools/run; chmod +x .cloud-kit/local/tools/run
echo z > .cloud-kit/local/plans/z.md; echo 'plan 2' > .cloud-kit/local/plans/credential-rotation.md
git add -A; git commit -q -m "R11: mixed"; cloud_push
cd "$w" || exit 1
run land || fail "L31 land with files this computer does not take back: $(cat "$tmp/out")"
[ ! -e "$p/docs/Client_Secret.json" ] && [ ! -e "$p/nueva2/private.md" ] || fail "L31b settings-shaped (any case) and ignored files are never written"
grep -q '2 file(s) in the cloud this computer does not take back' "$tmp/out" || fail "L31c land counts them: $(cat "$tmp/out")"
[ "$(cat "$p/plans/credential-rotation.md")" = 'plan 2' ] && [ -f "$p/plans/z.md" ] || fail "L31d the rest lands"
grep 'run or give instructions' "$tmp/out" | grep -q '.notes/plans/inline.md' || fail "L31e an inline @ import is named: $(cat "$tmp/out")"
grep 'run or give instructions' "$tmp/out" | grep -q '.notes/tools/run' || fail "L31f an executable is named"
cd "$c" || exit 1; git rm -q .cloud-kit/local/plans/z.md .cloud-kit/local/docs/Client_Secret.json .cloud-kit/local/nueva2/private.md
git commit -q -m "R12: drop z"; cloud_push
cd "$w" || exit 1
run land || fail "L32 land: $(cat "$tmp/out")"
[ -f "$p/plans/z.md" ] && grep -A3 'kept here' "$tmp/out" | grep -q 'plans/z.md' || fail "L32b a file landed but not backed up yet is never deleted: $(cat "$tmp/out")"
commit_layer mixed

# a link inside the folder is named and left out, and does not block; status sorts what did not travel
ln -s roadmap.md "$p/docs/alias.md"; commit_layer alias
run prepare || fail "L33 a link inside the folder does not block prepare: $(cat "$tmp/out")"
at .cloud-kit/local/docs/alias.md >/dev/null && fail "L33b a link never travels"
grep -q 'a link): docs/alias.md' "$tmp/out" || fail "L33c prepare names it: $(cat "$tmp/out")"
printf 'private.md\nR7.md\n' > "$layer/.gitignore"; commit_layer ignore-r7
git -C "$layer" rm -q --cached "projects/demo/plans/R7.md"; commit_layer untrack
echo fresh > "$p/plans/fresh.md"   # new, not backed up yet
run status || fail "L34 status: $(cat "$tmp/out")"
grep -A3 'not backed up yet' "$tmp/out" | grep -q 'plans/fresh.md' || fail "L34b a new file not backed up is sorted apart: $(cat "$tmp/out")"
grep -q '1 file(s) are still in the cloud though this computer no longer sends them' "$tmp/out" || fail "L34c a file ignored since is counted as left in the cloud's history: $(cat "$tmp/out")"
grep -q 'R7.md' "$tmp/out" && fail "L34d and never named"

finish "cloud-local"
