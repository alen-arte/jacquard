#!/bin/sh
# Tests for the code map part of scripts/structure-check.sh (project.md › Code map; scripts/structure-check/codemap.awk).
# Run from anywhere: tests/scripts/structure-check-codemap.test.sh. Exits 0 when every case passes.
. "$(dirname "$0")/lib.sh"
script="$kit/scripts/structure-check.sh"
sc() { out="$("$script" "$@" 2>&1)"; st=$?; }
has() { printf '%s\n' "$out" | grep -q -e "$1"; }

# A path the map names that is gone is a warning; without the section, nothing
m="$tmp/map"; git init -q -b main "$m"; cd "$m" || exit 1
mkdir -p .jacquard src/board; echo ".jacquard" >> .git/info/exclude
echo x > src/board/filter.ts; echo x > CLAUDE.md
git add -A; git commit -q -m one
cat > .jacquard/project.md <<'EOF'
## Code map
| To change | Files | Check |
|---|---|---|
| The board filter | `src/board/filter.ts`, `./src/board/` | `npm run test` |
| Sorting | `src/board/sort.ts` | `make` |

See `CLAUDE.md` › Architecture for the rest; patterns like `src/*.ts` and commands like `npm run e2e` are not paths.

## Other
- `src/elsewhere.ts` is outside the map
EOF
sc; has "⚠ code-map  src/board/sort.ts" && ! has "code-map.*filter" && ! has "code-map.*src/board/:" && ! has "code-map.*CLAUDE" \
  && ! has "code-map.*make" && ! has "code-map.*npm" && ! has "code-map.*\*" && ! has "code-map.*elsewhere" ||
  fail "K1 only the map's missing path is named: not existing files or folders, commands, the Check column, patterns or other sections (got: $out)"
[ "$st" = 0 ] && has "^Flagged: none$" && ! has "awk:" || fail "K2 a stale map path warns, never blocks, and flags no file to read (got $st: $out)"
git mv src/board/filter.ts src/board/filters.ts; git commit -q -m moved
sc; has "⚠ code-map  src/board/filter.ts" || fail "K3 a file moved away from its map row is named (got: $out)"
printf '## Stack\n- `nothing/here.ts`\n' > .jacquard/project.md
sc; ! has "code-map" || fail "K4 without a Code map section, nothing is said (got: $out)"

finish "structure-check code map"
