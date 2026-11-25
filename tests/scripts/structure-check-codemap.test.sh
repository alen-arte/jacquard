#!/bin/sh
# Tests for the code map part of scripts/structure-check.sh (project.md › Code map; scripts/structure-check/codemap.awk).
# Run from anywhere: tests/scripts/structure-check-codemap.test.sh. Exits 0 when every case passes.
. "$(dirname "$0")/lib.sh"
script="$kit/scripts/structure-check.sh"
[ -x "$script" ] || { echo "✗ $script missing or not executable"; exit 1; }

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
sc; has "⚠ code-map  src/board/sort.ts" || fail "K1 a path the map names that is not in the repo is named (got: $out)"
! has "code-map.*filter" && ! has "code-map.*src/board/:" && ! has "code-map.*CLAUDE" ||
  fail "K1b existing files and folders, with or without ./, are not named (got: $out)"
! has "code-map.*make" && ! has "code-map.*npm" && ! has "code-map.*\*" && ! has "code-map.*elsewhere" ||
  fail "K1c the Check column, commands, patterns and other sections are not read as paths (got: $out)"
[ "$st" = 0 ] && has "^Flagged: none$" && ! has "awk:" || fail "K2 a stale map path warns, never blocks, and flags no file to read (got $st: $out)"
git mv src/board/filter.ts src/board/filters.ts; git commit -q -m moved
sc; has "⚠ code-map  src/board/filter.ts" || fail "K3 a file moved away from its map row is named (got: $out)"
printf '## Code map\n- `~/notes.md`, `$HOME/x.ts`, `src/{a,b}.ts`, `src/board/filters.ts:12`, `src/board/filters.ts#L5`\n' > .jacquard/project.md
sc; ! has "code-map" || fail "K5 references and patterns (~, \$, braces, :line, #anchor) are not read as paths (got: $out)"
# The template's own Code map text, with one real row: its note names files no repo needs to have
awk '/^## / { on = ($0 ~ /^## Code map/) } on' "$kit/templates/project/project.md" |
  sed 's/^{{CODE_MAP_ROWS.*$/| The board | `src\/board\/filters.ts` | `npm run test` |/' > .jacquard/project.md
grep -q '^| The board |' .jacquard/project.md || fail "K6 setup: the template has no CODE_MAP_ROWS line to fill"
sc; ! has "code-map" || fail "K6 the filled template's Code map warns about nothing (got: $out)"
printf '## Stack\n- `nothing/here.ts`\n' > .jacquard/project.md
sc; ! has "code-map" || fail "K4 without a Code map section, nothing is said (got: $out)"

finish "structure-check code map"
