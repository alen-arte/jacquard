#!/bin/sh
# Tests for each project's own push rules in project.md › Git: free-branch patterns (`ux/*`) and own remotes
# (`personal`), through push-guard.sh install and check, the stub and hook.sh. Run from anywhere.
. "$(dirname "$0")/lib.sh"
. "$here/push-guard-lib.sh"
own() { printf -- '- **Own remotes** (x): %s\n' "$1" >> .jacquard/project.md; }

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
printf -- '- **Branches that publish or deploy** (x): `Release/prod`\n' >> .jacquard/project.md
sc install; [ "$st" != 0 ] || fail "F3 a pattern over a branch that publishes must be refused"
new_project f4 '`deploy/*`'
sed 's|\*\*Main branch:\*\* main|**Main branch:** deploy/live|' .jacquard/project.md > "$tmp/pm" && cp "$tmp/pm" .jacquard/project.md
sc install; [ "$st" != 0 ] || fail "F3 a pattern over the main branch must be refused"

# F4 · A new pattern lets more through: Claude's install asks (--widen); one fewer re-pins
cd "$tmp/f1" && r="$tmp/f1"; git switch -q main
sed 's|`ux/\*`|`ux/*`, `mode/*`|' .jacquard/project.md > "$tmp/pm" && cp "$tmp/pm" .jacquard/project.md
agent "$script" install >/dev/null 2>&1 && fail "F4 Claude's install must refuse a new pattern"
agent "$script" install --widen >/dev/null 2>&1 || fail "F4 install --widen adds it"
sed 's|, `mode/\*`||' .jacquard/project.md > "$tmp/pm" && cp "$tmp/pm" .jacquard/project.md
agent "$script" install >/dev/null 2>&1 || fail "F4 dropping a pattern is not widening"

# O1 · An own remote is pinned in the stub and passes check <remote>; branches there follow the same rules
new_project o1
for x in personal spare; do git init -q --bare "$tmp/o1-$x.git"; git remote add "$x" "$tmp/o1-$x.git"; done
own '`personal`'
sc install; [ "$st" = 0 ] || fail "O1 install with an own remote ($out)"
grep -qx '# own-remotes: personal' "$r/.git/hooks/pre-push" || fail "O1 the stub pins the own remotes"
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
sed 's|`personal`|`personal`, `spare`|' .jacquard/project.md > "$tmp/pm" && cp "$tmp/pm" .jacquard/project.md
sc check; [ "$st" != 0 ] || fail "O2 check must fail when the own remotes changed after install"
agent "$script" install >/dev/null 2>&1 && fail "O2 Claude's install must refuse a new own remote"
agent "$script" install --widen >/dev/null 2>&1 || fail "O2 install --widen adds it"
sed 's|, `spare`||' .jacquard/project.md > "$tmp/pm" && cp "$tmp/pm" .jacquard/project.md
agent "$script" install >/dev/null 2>&1 || fail "O2 dropping an own remote is not widening"

# O3 · An own remote is a remote this repo has, named plainly, and never origin
i=0
for x in '`nosuch`' '`origin`' '`-p`' '`p/x`' '`p:x`' '`p x`'; do
  i=$((i + 1)); new_project "o3-$i"; own "$x"
  sc install; [ "$st" != 0 ] || fail "O3 install must refuse the own remote $x"
done

finish "push-guard-own"
