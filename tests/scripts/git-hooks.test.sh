#!/bin/sh
# Tests for scripts/hooks/pre-push and templates/project/pre-commit-guard.
# Run from anywhere: tests/scripts/git-hooks.test.sh. Exits 0 when every case passes.
. "$(dirname "$0")/lib.sh"
prepush="$kit/scripts/hooks/pre-push"
export JACQUARD_PRIVACY_TERMS="$tmp/terms.txt"
printf 'secretterm\n' > "$JACQUARD_PRIVACY_TERMS"
zero=0000000000000000000000000000000000000000

# pre-push: history that only a private remote had must be checked before it reaches a new URL
w="$tmp/w"; git init -q -b main "$w" || exit 1
cd "$w" || exit 1
echo "notes for secretterm" > a.md; git add -A; git commit -q -m one
echo "clean" > a.md; git add -A; git commit -q -m two
git clone -q --bare "$w" "$tmp/old.git"
git remote add origin "$tmp/old.git"; git fetch -q origin
echo "more" > b.md; git add -A; git commit -q -m three
head=$(git rev-parse HEAD)
push() { printf 'refs/heads/main %s refs/heads/main %s\n' "$head" "$zero" | "$prepush" origin "$1" >/dev/null 2>&1; echo $?; }

[ "$(push "$tmp/old.git")" = 0 ] || fail "P1 pushing to the remote that already has the old commits checks only the new one"
git init -q --bare "$tmp/new.git"
git remote set-url origin "$tmp/new.git"
[ "$(push "$tmp/new.git")" = 1 ] || fail "P2 after remote set-url, commits the new remote lacks must be checked (term in an old commit)"
[ "$(push "$tmp/missing.git")" = 1 ] || fail "P3 when the remote cannot be listed, every commit must be checked"
printf 'refs/heads/gone %s refs/heads/gone %s\n' "$zero" "$head" | "$prepush" origin "$tmp/new.git" >/dev/null 2>&1
[ $? = 0 ] || fail "P4 deleting a remote branch publishes nothing"

# pre-commit guard: no commits on main, and none on a detached HEAD outside a rebase
guard="$tmp/guard"
sed -e 's/{{MAIN}}/main/' -e 's/{{LOCAL_FOLDER_REGEX}}/\\.jacquard/' "$kit/templates/project/pre-commit-guard" > "$guard"
chmod +x "$guard"
g="$tmp/g"; git init -q -b main "$g"; cd "$g" || exit 1
echo x > a.md; git add -A
"$guard" >/dev/null 2>&1 || fail "G1 the first commit of a new repo is allowed"
git commit -q --no-verify -m first
echo y > a.md; git add -A
"$guard" >/dev/null 2>&1 && fail "G2 a commit on main must be refused"
git switch -q -c r1-work
"$guard" >/dev/null 2>&1 || fail "G3 a commit on a work branch is allowed"
git switch -q --detach main 2>/dev/null || git checkout -q --detach main
echo z > a.md; git add -A
"$guard" >/dev/null 2>&1 && fail "G4 a commit on a detached HEAD must be refused"
mkdir -p .git/rebase-merge
"$guard" >/dev/null 2>&1 || fail "G5 a commit during a rebase (detached HEAD) is allowed"
rmdir .git/rebase-merge
mkdir -p .git/rebase-apply
"$guard" >/dev/null 2>&1 || fail "G5b a commit during git am / rebase-apply is allowed"
rmdir .git/rebase-apply
git rev-parse HEAD > .git/CHERRY_PICK_HEAD
"$guard" >/dev/null 2>&1 || fail "G5c a commit during a cherry-pick is allowed"
rm -f .git/CHERRY_PICK_HEAD
mkdir -p .jacquard && echo n > .jacquard/n.md && git switch -q r1-work 2>/dev/null; git add -A .jacquard 2>/dev/null
"$guard" >/dev/null 2>&1 && fail "G6 staged local files must be refused"

finish "git hooks"
