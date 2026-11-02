#!/bin/sh
# Tests for scripts/structure-check.sh. Run from anywhere: tests/scripts/structure-check.test.sh
# Exits 0 when every case passes; prints one line per failure.
. "$(dirname "$0")/lib.sh"
script="$kit/scripts/structure-check.sh"
[ -x "$script" ] || { echo "✗ $script missing or not executable"; exit 1; }

# sc <args…>: runs the check, leaves its output in $out and its exit status in $st
sc() { out="$("$script" "$@" 2>&1)"; st=$?; }
has() { printf '%s\n' "$out" | grep -q -e "$1"; }
lines() { seq 1 "$2" | sed 's/^/const v = 1; \/\/ /' > "$1"; }

# A small project on main: limits from its project.md (warn 5, cap 10), one legacy file past the cap,
# one existing import cycle, a tokens file and an exempt generated folder
r="$tmp/r"; git init -q -b main "$r" || exit 1
cd "$r" || exit 1
mkdir -p .jacquard src/styles src/generated
echo ".jacquard" >> .git/info/exclude
cat > .jacquard/project.md <<'EOF'
## Code limits
- **File size:** warn at 5 lines · cap at 10 · **Function size:** flag past core default lines
- **Areas:** `src/`
- **Where configuration, tokens and copy live:** `src/styles/tokens.css`, `src/config/`
- **Files exempt from the code limits:** `src/generated/*`, `*.min.js`
EOF
lines src/big.ts 12
lines src/mid.ts 3
printf '%s\n' "import { b } from './c2';" 'export const a = 1;' > src/c1.ts
printf '%s\n' "import { a } from './c1';" 'export const b = 2;' > src/c2.ts
printf '%s\n' 'export function formatDate() {}' > src/util.ts
printf '%s\n' ':root { --brand: #ff0000; }' > src/styles/tokens.css
lines src/generated/huge.ts 50
echo "# readme" > README.md
git add -A; git commit -q -m base
start() { git reset -q --hard; git clean -qfd; git switch -q -C "w$1" main; }

start 1; echo "more" >> README.md
sc; [ "$st" = 0 ] && has "no findings" || fail "S1 a change with no code must pass with 'no findings' (got $st: $out)"

start 2; echo "const w = 2;" >> src/big.ts
sc; [ "$st" = 1 ] && has "✗ size.*src/big.ts" || fail "S2 a file past the cap that grew must fail (got $st: $out)"
has "^Flagged: src/big.ts" || fail "S3 the flagged line must name the file (got: $out)"

start 3; sed -i.bak '1d' src/big.ts; rm -f src/big.ts.bak
sc; [ "$st" = 0 ] && has "⚠ size.*src/big.ts.*did not grow" || fail "S4 a file past the cap that shrank only warns (got $st: $out)"

start 4; lines src/mid.ts 7
sc; [ "$st" = 0 ] && has "⚠ size.*src/mid.ts" || fail "S5 a file past the warning only warns (got $st: $out)"

start 5; lines src/new.ts 11
sc; [ "$st" = 1 ] && has "✗ size.*src/new.ts" || fail "S6 a new untracked file past the cap must fail (got $st: $out)"

start 6
printf '%s\n' "import { x } from './b.js';" 'export const y = 1;' > src/a.ts
printf '%s\n' 'import {' '  y,' "} from './a';" 'export const x = 1;' > src/b.ts
sc; [ "$st" = 1 ] && has "✗ cycle.*src/a.ts" || fail "S7 a new cycle (a .js specifier, a multi-line import) must fail (got $st: $out)"

start 7; mkdir -p src/e
printf '%s\n' "import './e';" > src/d.ts
printf '%s\n' "export * from '../d';" > src/e/index.ts
sc; [ "$st" = 1 ] && has "✗ cycle.*src/e/index.ts" || fail "S8 a cycle through a folder's index must fail (got $st: $out)"

start 8; echo "export const c = 3;" >> src/c1.ts
sc; [ "$st" = 0 ] && has "⚠ cycle.*src/c1.ts" || fail "S9 touching a file in an existing cycle only warns (got $st: $out)"

start 9
printf '%s\n' "import { a } from './c1';" 'export const c = 3;' > src/c3.ts
printf '%s\n' "import { a } from './c3';" 'export const b = 2;' > src/c2.ts
sc; [ "$st" = 1 ] && has "✗ cycle.*src/c3.ts" || fail "S10 an existing cycle that grew must fail (got $st: $out)"

start 10
printf '%s\n' 'import type {' '  G,' "} from './g';" 'export const f = 1;' > src/f.ts
printf '%s\n' "import { f } from './f';" 'export type G = number;' > src/g.ts
sc; [ "$st" = 0 ] && ! has "cycle" || fail "S11 a type-only import is not a cycle (got $st: $out)"

start 11; mkdir -p tests
printf '%s\n' 'export function formatDate() {}' 'function inner() {' '  function formatDate() {}' '}' > src/other.ts
printf '%s\n' 'function formatDate() {}' > tests/other.test.ts
sc; [ "$st" = 0 ] && has "⚠ duplicate.*formatDate.*src/other.ts.*src/util.ts" || fail "S12 a top-level function name in two files warns (got $st: $out)"
has "tests/other.test.ts" && fail "S13 test files are left out of the duplicate check (got: $out)"

start 12
printf '%s\n' "const c = '#1a2b3c';" 'const d = "rgb(1, 2, 3)";' 'const e = "&#123;";' > src/view.tsx
echo ':root { --ok: #00ff00; }' >> src/styles/tokens.css
sc; [ "$st" = 0 ] && has "⚠ colour.*src/view.tsx.*2" || fail "S14 two loose colours in a view warn, with their count (got $st: $out)"
has "tokens.css" && fail "S15 colours in the tokens file are not loose (got: $out)"

start 13; lines src/generated/huge.ts 60
sc; [ "$st" = 0 ] && ! has "huge" || fail "S16 exempt files are skipped (got $st: $out)"

start 14; rm src/mid.ts
sc; [ "$st" = 0 ] || fail "S17 a deleted file must not break the check (got $st: $out)"

start 15
sc --all; [ "$st" = 1 ] && has "✗ cycle.*src/c1.ts" && has "⚠ size.*src/big.ts" || fail "S18 --all fails on any cycle and warns on files past the cap (got $st: $out)"
has "huge" && fail "S19 --all skips exempt files too (got: $out)"

start 16
printf '%s\n' '- **File size:** warn at core default lines · cap at core default' > "$tmp/default.md"
lines src/new.ts 501; lines src/mid.ts 301
sc --project "$tmp/default.md"; [ "$st" = 1 ] && has "✗ size.*src/new.ts" && has "⚠ size.*src/mid.ts" ||
  fail "S20 'core default' uses 300 and 500 (got $st: $out)"

sc --base nope; [ "$st" = 2 ] || fail "S21 an unknown base must exit 2 (got $st)"
sc --bogus; [ "$st" = 2 ] || fail "S22 an unknown option must exit 2 (got $st)"
mkdir -p "$tmp/notgit"; cd "$tmp/notgit" || exit 1
sc; [ "$st" = 2 ] || fail "S23 outside a git repo must exit 2 (got $st)"

finish "structure-check"
