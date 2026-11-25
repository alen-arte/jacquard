#!/bin/sh
# Tests for the push guard: scripts/push-guard.sh (install, check), the stub it writes, scripts/push-guard/hook.sh and
# scripts/protected-push.sh, against real repos and a bare remote. Run from anywhere: tests/scripts/push-guard.test.sh
. "$(dirname "$0")/lib.sh"
. "$here/push-guard-lib.sh"

# I1 · install writes a read-only stub with absolute paths, no $HOME, the kit's files pinned
new_project p1
sc install
[ "$st" = 0 ] || fail "I1 install must succeed (got $st: $out)"
stub="$r/.git/hooks/pre-push"
[ "$(ls -l "$stub" | cut -c1-10)" = "-r-xr-xr-x" ] || fail "I1 the stub must be read-only and executable (555)"
grep -q 'HOME' "$stub" && fail "I1 the stub must not name \$HOME (a faked HOME would run another kit)"
grep -qF "'$kc/scripts/push-guard/hook.sh'" "$stub" || fail "I1 the stub must call the kit's hook by its absolute path"
sc check
[ "$st" = 0 ] || fail "I2 check passes right after install (got: $out)"

# G1 · Your own push (no Claude marker) is not the guard's business
commit_on main
git push -q origin main 2>/dev/null || fail "G1 a push from your terminal goes through"

# G2 · Claude pushes free and work branches without asking; G3 · nothing else
for b in dev demo away/r1-x cloud/r1-x r12-tag-filter rf2-dispatcher; do
  commit_on "$b"; agent git push -q origin "$b" 2>/dev/null || fail "G2 Claude pushes $b"
done
git switch -q main
commit_on main
agent git push -q origin main 2>/dev/null && fail "G3 Claude's plain push of main must be refused"
for b in production2 Dev release/1 Main; do
  commit_on "$b"; agent git push -q origin "$b" 2>/dev/null && fail "G3 Claude's push of $b must be refused (not on the free list)"
done
git switch -q dev
agent git push -q origin dev:production 2>/dev/null && fail "G3 dev:production must be refused"
agent git push -q origin dev:refs/heads/main 2>/dev/null && fail "G3 dev:refs/heads/main must be refused"
git tag v1 >/dev/null 2>&1
agent git push -q origin v1 2>/dev/null && fail "G3 a tag must be refused"
agent git push -q origin :demo 2>/dev/null && fail "G3 deleting a remote branch must be refused"
for v in CLAUDE_CODE_ENTRYPOINT JACQUARD_AGENT; do
  env "$v=x" git push -q origin dev:production 2>/dev/null && fail "G3 $v alone also marks Claude"
done

# G4 · Free branches move fast-forward only
git switch -q dev; git reset -q --hard HEAD~1; echo other > other.txt; git add other.txt; git commit -qm diverge
agent git push -q origin +dev 2>/dev/null && fail "G4 a forced push of a free branch must be refused"

# P1 · protected-push.sh pushes the main branch, as a child of the real script
git switch -q main; commit_on main
agent "$kc/scripts/protected-push.sh" origin main >/dev/null 2>&1 || fail "P1 protected-push.sh pushes main"
[ "$(git rev-parse main)" = "$(git --git-dir="$tmp/p1.git" rev-parse main)" ] || fail "P1 the remote's main is the local main"
agent "$kc/scripts/protected-push.sh" origin refs/tags/v1 >/dev/null 2>&1 || fail "P1b protected-push.sh pushes a tag"
git tag v2 >/dev/null 2>&1; commit_on main
agent "$kc/scripts/protected-push.sh" origin main >/dev/null 2>&1
git --git-dir="$tmp/p1.git" rev-parse -q --verify refs/tags/v2 >/dev/null && fail "P3 one destination per push: tags never follow"

# P2 · Only the real script, as itself, authorizes: no shell around a push, no other spelling, no injected environment
commit_on main
agent bash -c 'git push -q origin main' 2>/dev/null && fail "P2 bash -c around a push must be refused"
agent bash -c 'exec -a /bin/sh /bin/sh -c "git push -q origin main"' 2>/dev/null && fail "P2 exec -a must be refused"
agent sh "$kc/scripts/protected-push.sh" origin main >/dev/null 2>&1 && fail "P2 sh <script> (not the exact command) must be refused"
agent env BASH_ENV=/dev/null "$kc/scripts/protected-push.sh" origin main >/dev/null 2>&1 && fail "P2 BASH_ENV in the script's environment must be refused"
agent env LD_PRELOAD= "$kc/scripts/protected-push.sh" origin main >/dev/null 2>&1 && fail "P2 LD_* in the script's environment must be refused"

# P4 · The script's own refusals: a URL, a refspec, refs/ other than tags, a missing local branch, a cloud session
for a in "$tmp/p1.git main" "origin main:refs/heads/x" "origin refs/heads/main" "origin +main" "origin nosuch" "origin -n"; do
  # shellcheck disable=SC2086
  agent "$kc/scripts/protected-push.sh" $a >/dev/null 2>&1 && fail "P4 protected-push.sh must refuse: $a"
done
agent env CLAUDE_CODE_REMOTE=true "$kc/scripts/protected-push.sh" origin main >/dev/null 2>&1 && fail "P4 protected-push.sh must refuse in a cloud session"

# A · Away: the script refuses, and the guard refuses every push by Claude
away_on
agent "$kc/scripts/protected-push.sh" origin main >/dev/null 2>&1 && fail "A1 protected-push.sh must refuse in Away"
git switch -q dev; git reset -q --hard origin/dev; commit_on dev
agent git push -q origin dev 2>/dev/null && fail "A2 the guard must refuse a free branch in Away"
away_off
sc install
away_on; sc install; [ "$st" != 0 ] || fail "A3 install must refuse in Away"; away_off

# T1 · A changed kit file stops Claude's pushes (the stub checks the pinned sums); your push still goes
printf '\n' >> "$kc/scripts/push-guard/hook.sh"
agent git push -q origin dev 2>/dev/null && fail "T1 a kit changed after install must stop Claude's push"
git push -q origin dev 2>/dev/null || fail "T1 your own push is not blocked by a stale stub"
sc check; [ "$st" != 0 ] || fail "T1 check must fail when the kit changed after install"
sc install; sc check; [ "$st" = 0 ] || fail "T1 install again pins the new sums"
mkdir -p "$HOME/.claude/jacquard/scripts/push-guard"; printf '#!/bin/sh\nexit 0\n' > "$HOME/.claude/jacquard/scripts/push-guard/hook.sh"
git switch -q main; commit_on main
agent env HOME="$HOME" git push -q origin main 2>/dev/null && fail "T1 a fake kit under HOME must not be used"

# I3 · check catches what turns the guard off or redirects pushes
for kv in "remote.origin.push refs/heads/x:refs/heads/main" "remote.origin.pushurl $tmp/else.git" "url.$tmp/else.git.pushInsteadOf $tmp/p1.git" "include.path /dev/null" "alias.p push" "core.hooksPath /tmp"; do
  # shellcheck disable=SC2086
  git config $kv; sc check; [ "$st" != 0 ] || fail "I3 check must fail with $kv"
  git config --unset "${kv%% *}"
done
sc check; [ "$st" = 0 ] || fail "I3 check passes again once the config is clean ($out)"
chmod u+w "$stub"; printf '# x\n' >> "$stub"; chmod 555 "$stub"
sc check; [ "$st" != 0 ] || fail "I3 check must fail on an edited stub"
sc install; chmod 755 "$stub"
sc check; [ "$st" != 0 ] || fail "I3 check must fail on a writable stub"
sc install
sed 's/`demo`/`demo`, `staging`/' .jacquard/project.md > "$tmp/pm" && cp "$tmp/pm" .jacquard/project.md
sc check; [ "$st" != 0 ] || fail "I3 check must fail when project.md's free list changed after install"
sc install; sc check; [ "$st" = 0 ] || fail "I3 install again follows project.md"

# I4 · The free list never holds the main branch, in any case
new_project p2 '`dev`, `MAIN`'
sc install; [ "$st" != 0 ] || fail "I4 install must refuse a free list with the main branch"
[ -e "$r/.git/hooks/pre-push" ] && fail "I4 a refused install writes nothing"

# I5 · A pre-push hook that is not Jacquard's is left alone (every push asks there)
new_project p3
printf '#!/bin/sh\necho lfs\n' > "$r/.git/hooks/pre-push"; chmod +x "$r/.git/hooks/pre-push"
sc install; [ "$st" != 0 ] || fail "I5 install must refuse over someone else's pre-push hook"
grep -q lfs "$r/.git/hooks/pre-push" || fail "I5 someone else's hook stays as it was"

# T9 · The kit's own repo: the privacy stub becomes the guard and then the privacy check
new_project p4
printf '#!/bin/sh\nexec "$HOME/.claude/jacquard/scripts/hooks/pre-push" "$@"\n' > "$r/.git/hooks/pre-push"; chmod +x "$r/.git/hooks/pre-push"
sc install; [ "$st" = 0 ] || fail "T9 install replaces the old privacy stub ($out)"
export JACQUARD_PRIVACY_TERMS="$tmp/terms.txt"; printf 'secretterm\n' > "$JACQUARD_PRIVACY_TERMS"
git switch -q -c dev; echo "secretterm here" > s.md; git add s.md; git commit -qm leak
git push -q origin dev >/dev/null 2>&1 && fail "T9 the privacy check still runs on your push"
agent git push -q origin dev >/dev/null 2>&1 && fail "T9 the privacy check still runs on Claude's push"
sc install; grep -q 'scripts/hooks/pre-push' "$r/.git/hooks/pre-push" || fail "T9 installing again keeps the privacy check"

# I6 · A worktree installs into the shared hooks folder
new_project p5
git worktree add -q "$tmp/p5-wt" -b r5-wt 2>/dev/null
(cd "$tmp/p5-wt" && cp -R "$r/.jacquard" . && cp "$r/CLAUDE.local.md" . && "$kc/scripts/push-guard.sh" install >/dev/null 2>&1) || fail "I6 install from a worktree"
[ -f "$r/.git/hooks/pre-push" ] || fail "I6 the stub goes to the repo's shared hooks folder"

# H · husky: the stub goes in .husky/pre-push (excluded, untracked) and check pins husky's own files
new_project p6
husky_init
sc install; [ "$st" = 0 ] || fail "H1 install in a husky repo ($out)"
[ -f "$r/.husky/pre-push" ] && [ ! -e "$r/.git/hooks/pre-push" ] || fail "H1 the stub goes in .husky/pre-push"
grep -qx '/.husky/pre-push' "$r/.git/info/exclude" || fail "H1 .husky/pre-push is excluded from git"
sc check; [ "$st" = 0 ] || fail "H2 check passes in a husky repo ($out)"
commit_on main; agent git push -q origin main 2>/dev/null && fail "H3 husky: Claude's push of main is refused"
agent "$kc/scripts/protected-push.sh" origin main >/dev/null 2>&1 || fail "H3 husky: protected-push.sh goes through husky's layers"
printf '# changed\n' >> "$r/.husky/_/h"; sc check; [ "$st" != 0 ] || fail "H4 check must fail when husky's runner changed"
husky_init; sc install
mkdir -p node_modules/.bin; printf '#!/bin/sh\n' > node_modules/.bin/sh
sc check; [ "$st" != 0 ] || fail "H4 check must fail with node_modules/.bin/sh"
rm -rf node_modules
mkdir -p "$HOME/.config/husky"; : > "$HOME/.config/husky/init.sh"
sc check; [ "$st" != 0 ] || fail "H4 check must fail with a husky init.sh"
rm -rf "$HOME/.config/husky"
git config core.hooksPath .husky; sc check; [ "$st" != 0 ] || fail "H4 check must fail with another hooksPath"

finish "push-guard"
