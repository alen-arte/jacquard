#!/bin/sh
# Tests for each project's own push rules in project.md › Git: free-branch patterns (`ux/*`) and own remotes
# (`personal`), through push-guard.sh install and check, the stub and hook.sh. Run from anywhere.
# O2, R1 and R2 go on in O1's repo, with the stub O1 left: keep them right after it, in that order.
. "$(dirname "$0")/lib.sh"
. "$here/push-guard-lib.sh"
own() { printf -- '- **Own remotes** (x): %s\n' "$1" >> .jacquard/project.md; }
publish() { printf -- '- **Branches that publish or deploy** (x): %s\n' "$1" >> .jacquard/project.md; }

# F1 · `<prefix>/*` frees every branch under the prefix, at any depth, and nothing else; never globbed
new_project f1 '`demo`, `ux/*`'
sc install; [ "$st" = 0 ] || fail "F1 install with a pattern ($out)"
grep -qF "JQ_FREE='demo ux/*'" "$r/.git/hooks/pre-push" || fail "F1 the stub pins the pattern as written"
mkdir -p ux; : > ux/zzz
for b in ux/menu ux/a/b; do commit_on "$b"; agent git push -q origin "$b" 2>/dev/null || fail "F1 Claude pushes $b"; done
for b in uxx/a UX/menu ux-a; do commit_on "$b"; agent git push -q origin "$b" 2>/dev/null && fail "F1 $b is not under ux/*"; done
git switch -q ux/menu; agent git push -q origin ux/menu:main 2>/dev/null && fail "F1 a free source does not free the destination"

# F2 · An entry that is not a name or `<prefix>/*` is refused, and nothing is installed
i=0
for p in '`*`' '`*/x`' '`ux*`' '`ux/**`' '`u*/x`' '`ux/*/a`' '`/*`' '`-x/*`' '`.x/*`' '`ux//*`' '`ux/?`' '`ux/[a]`'; do
  i=$((i + 1)); new_project "f2-$i" "$p"
  sc install; [ "$st" != 0 ] || fail "F2 install must refuse the free entry $p"
  [ -e "$r/.git/hooks/pre-push" ] && fail "F2 a refused install writes nothing ($p)"
done

# F3 · A pattern never covers the main branch or a branch that publishes, in any case
new_project f3 '`release/*`'
publish '`Release/prod`'
sc install; [ "$st" != 0 ] || fail "F3 a pattern over a branch that publishes must be refused"
new_project f4 '`deploy/*`'
pm_edit 's|\*\*Main branch:\*\* main|**Main branch:** deploy/live|'
sc install; [ "$st" != 0 ] || fail "F3 a pattern over the main branch must be refused"
i=0
for fp in '`release/v2`|`release/*`' '`release/v2/*`|`release/*`' '`prod`|`Prod`' '`ux/*`|`ux/*`' '`demo`|`re*`'; do
  i=$((i + 1)); new_project "f3-$i" "${fp%%|*}"
  publish "${fp#*|}"
  sc install; [ "$st" != 0 ] || fail "F3 free ${fp%%|*} with publish ${fp#*|} must be refused"
done

# F5 · A branch that publishes never has the form of the kit's work branches, which go without asking
i=0
for p in '`cloud/prod`' '`away/*`' '`Away/x/*`' '`r7-release`' '`cloud/a/*`'; do
  i=$((i + 1)); new_project "f5-$i" 'none'; publish "$p"
  sc install; [ "$st" != 0 ] || fail "F5 install must refuse $p, a branch that publishes in a work branch's form"
done
new_project f5-ok 'none'; publish '`release/*`, `rel7`, `awayx/*`'
sc install; [ "$st" = 0 ] || fail "F5 release/*, rel7 and awayx/* are not work branch forms ($out)"

# F4 · A new pattern lets more through: Claude's install asks (--widen); one fewer re-pins
cd "$tmp/f1" && r="$tmp/f1"; git switch -q main
pm_edit 's|`ux/\*`|`ux/*`, `mode/*`|'
agent "$script" install >/dev/null 2>&1 && fail "F4 Claude's install must refuse a new pattern"
agent "$script" install --widen >/dev/null 2>&1 || fail "F4 install --widen adds it"
pm_edit 's|, `mode/\*`||'
agent "$script" install >/dev/null 2>&1 || fail "F4 dropping a pattern is not widening"

# U1 · A stub from before own remotes (no JQ_URLS) let free branches go anywhere: pinning the URLs only narrows
new_project u1
sc install; stub="$r/.git/hooks/pre-push"
sed "s/ JQ_URLS='[^']*'//" "$stub" > "$tmp/old-stub"; rm -f "$stub"; cp "$tmp/old-stub" "$stub"; chmod 555 "$stub"
grep -q "JQ_URLS" "$stub" && fail "U1 setup: the old stub has no JQ_URLS"
agent "$script" install >/dev/null 2>&1 || fail "U1 Claude's install over a stub from before own remotes re-pins"
grep -q "JQ_URLS='origin=" "$stub" || fail "U1 the re-pinned stub pins origin's URL"

# U2 · A first install, no stub yet, with no free branch but an own or a cloud remote, lets more through
new_project u2 'none'
git init -q --bare "$tmp/u2-personal.git"; git remote add personal "$tmp/u2-personal.git"
own '`personal`'
agent "$script" install >/dev/null 2>&1 && fail "U2 Claude's first install with an own remote must ask (--widen)"
new_project u3 'none'
git init -q --bare "$tmp/u3-cloud.git"; git remote add cloud "$tmp/u3-cloud.git"; git config jacquard.cloudRemote cloud
agent "$script" install >/dev/null 2>&1 && fail "U2 Claude's first install with a cloud remote must ask (--widen)"
git config --unset jacquard.cloudRemote; printf '[jacquard]\n\tcloudRemote = cloud\n' > "$tmp/u3-global"
GIT_CONFIG_GLOBAL="$tmp/u3-global" agent "$script" install >/dev/null 2>&1 ||
  fail "U2 only the repo's own git config names the cloud remote, as cloud.sh reads it"

# O1 · An own remote is pinned in the stub and passes check <remote>; branches there follow the same rules
new_project o1
for x in personal spare; do git init -q --bare "$tmp/o1-$x.git"; git remote add "$x" "$tmp/o1-$x.git"; done
own '`personal`'
sc install; [ "$st" = 0 ] || fail "O1 install with an own remote ($out)"
grep -Eq "JQ_URLS='origin=[0-9a-f]{64} personal=[0-9a-f]{64} '" "$r/.git/hooks/pre-push" || fail "O1 the stub pins each own remote with its URL's sum, and no other"
sc check personal; [ "$st" = 0 ] || fail "O1 check passes for a listed own remote ($out)"
sc check origin; [ "$st" = 0 ] || fail "O1 origin always passes check ($out)"
sc check spare; [ "$st" = 5 ] || fail "O1 a remote not on the list exits 5 (got $st: $out)"
sc check -x; [ "$st" = 2 ] || fail "O1 an unusual remote name is a usage error (got $st)"
commit_on demo
agent git push -q personal demo 2>/dev/null || fail "O1 Claude pushes a free branch to an own remote"
agent git push -q personal demo:demo 2>/dev/null || fail "O1 <branch>:<branch> goes the same way"
git switch -q main; commit_on main
agent git push -q personal main 2>/dev/null && fail "O1 main stays protected on an own remote"

# O2 · Adding an own remote widens (--widen), even when its URL was already pinned; dropping one re-pins
pm_edit 's|`personal`|`personal`, `spare`|'
sc check; [ "$st" != 0 ] || fail "O2 check must fail when the own remotes changed after install"
agent "$script" install >/dev/null 2>&1 && fail "O2 Claude's install must refuse a new own remote"
agent "$script" install --widen >/dev/null 2>&1 || fail "O2 install --widen adds it"
pm_edit 's|, `spare`||'
agent "$script" install >/dev/null 2>&1 || fail "O2 dropping an own remote is not widening"

# R1 · A free branch goes without asking only to a listed remote, at the URL pinned for it
commit_on demo
agent git push -q "$tmp/o1-spare.git" demo 2>/dev/null && fail "R1 a free branch to a URL must be refused"
agent git push -q spare demo 2>/dev/null && fail "R1 a free branch to a remote off the list must be refused"
agent git -c "remote.personal.pushurl=$tmp/o1-spare.git" push -q personal demo 2>/dev/null && fail "R1 a listed name pushing to another URL must be refused"
agent git -c "url.$tmp/o1-spare.git.insteadOf=$tmp/o1-personal.git" push -q personal demo 2>/dev/null && fail "R1 an insteadOf added later must be refused"
agent git -c "url.$tmp/o1-spare.git.pushInsteadOf=$tmp/o1-personal.git" push -q personal demo 2>/dev/null && fail "R1 a pushInsteadOf added later must be refused"
git remote add person "$tmp/o1-spare.git"
agent git push -q person demo 2>/dev/null && fail "R1 person is not personal"
git remote remove person; sc install

# R2 · The cloud remote (git config jacquard.cloudRemote) is the project's too; a new one widens
git config jacquard.cloudRemote spare
sc check; [ "$st" != 0 ] || fail "R2 check must fail when the cloud remote changed after install"
agent "$script" install >/dev/null 2>&1 && fail "R2 Claude's install must refuse a new cloud remote"
sc install; commit_on cloud/r1-x
agent git push -q spare cloud/r1-x 2>/dev/null || fail "R2 the cloud remote takes the kit's branches"

# O3 · An own remote is a remote this repo has, named plainly, and never origin
i=0
for x in '`nosuch`' '`origin`' '`-p`' '`p/x`' '`p:x`'; do
  i=$((i + 1)); new_project "o3-$i"; own "$x"
  sc install; [ "$st" != 0 ] || fail "O3 install must refuse the own remote $x"
done

finish "push-guard-own"
