#!/bin/sh
# Tests for scripts/structure-check.sh. Run from anywhere: tests/scripts/structure-check.test.sh
# Exits 0 when every case passes; prints one line per failure.
. "$(dirname "$0")/lib.sh"
script="$kit/scripts/structure-check.sh"
[ -x "$script" ] || { echo "✗ $script missing or not executable"; exit 1; }

# sc <args…>: runs the check, leaves its output in $out and its exit status in $st
sc() { out="$("$script" "$@" 2>&1)"; st=$?; }
has() { printf '%s\n' "$out" | grep -q -e "$1"; }
flagged() { printf '%s\n' "$out" | grep '^Flagged:' | grep -q -e " $1\( \|$\)"; }
lines() { seq 1 "$2" | sed 's/^/const v = 1; \/\/ /' > "$1"; }

# A small project on main: limits from its project.md (warn 5, cap 10), one legacy file past the cap,
# one existing import cycle, a tokens file and an exempt generated folder
r="$tmp/r"; git init -q -b main "$r" || exit 1
cd "$r" || exit 1
mkdir -p .jacquard src/styles src/generated
echo ".jacquard" >> .git/info/exclude
cat > .jacquard/project.md <<'EOF'
## Stack
- **Elsewhere:** warn at 1 lines · cap at 2 (outside Code limits: ignored)

## Code limits
- **File size:** warn at 5 lines · cap at 10 · **Function size:** flag past core default lines
- **Areas:** `src/`
- **Where configuration, tokens and copy live:** `src/styles/tokens.css`, `src/config/`
- **Files exempt from the code limits:** `src/generated/*`, `*.min.js`
- **Names that repeat by convention:** `render`

## Environments
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
has "warn 5 · cap 10; settings: .*project.md; import aliases: none" || fail "S1b the limits come from the Code limits section only, and the aliases are named (got: $out)"
printf '%s\n' '## Stack' > "$tmp/nolimits.md"
sc --project "$tmp/nolimits.md"; has "warn 300 · cap 500; settings: core defaults (.*has no Code limits section)" || fail "S1c a project.md without Code limits says so (got: $out)"
cp "$script" "$tmp/alone.sh"; out="$("$tmp/alone.sh" 2>&1)"; st=$?
[ "$st" = 2 ] && has "nothing was checked" || fail "S1d without its awk parts it must exit 2, never pass (got $st: $out)"

start 2; echo "const w = 2;" >> src/big.ts
sc --base main; [ "$st" = 1 ] && has "✗ size.*src/big.ts" || fail "S2 a file past the cap that grew must fail (got $st: $out)"
flagged src/big.ts || fail "S3 the flagged line must name the file (got: $out)"

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
flagged src/a.ts && flagged src/b.ts || fail "S7b both files of a cycle are flagged (got: $out)"

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
printf '%s\n' "// import { i } from './i';" "const m = import('./i');" > src/h.ts
printf '%s\n' "import { h } from './h';" > src/i.ts
sc; [ "$st" = 0 ] && ! has "cycle" || fail "S11 type-only imports, dynamic import() and commented imports are not cycles (got $st: $out)"

start 11; mkdir -p tests
printf '%s\n' 'export function formatDate() {}' 'export const render = () => 1;' 'export async function GET() {}' > src/other.ts
printf '%s\n' 'function inner() {' '  function formatDate() {}' '}' > src/nested.ts
printf '%s\n' 'function formatDate() {}' > tests/other.test.ts
printf '%s\n' 'export function render() {}' 'export function GET() {}' 'export function formatDate(): string;' > src/more.ts
mv src/more.ts src/types.d.ts
printf '%s\n' 'export function render() {}' 'export function GET() {}' > src/route.ts
sc; [ "$st" = 0 ] && has "⚠ duplicate.*formatDate: src/other.ts, src/util.ts" || fail "S12 a top-level function name in two files warns (got $st: $out)"
has "nested.ts\|other.test.ts\|types.d.ts" && fail "S13 nested functions, test files and .d.ts files are left out (got: $out)"
has "duplicate.*render\|duplicate.*GET" && fail "S13b names that repeat by convention (seeded, or from project.md) are not duplicates (got: $out)"
flagged src/other.ts && ! flagged src/util.ts || fail "S13c a duplicate flags only this change's files (got: $out)"

start 12
printf '%s\n' "const c = '#1a2b3c';" 'const d = "rgb(1, 2, 3)";' 'const e = "&#123;";' 'const f = "rgb(var(--x))";' \
  "const g = '#12345';" "const h = '#1234567';" 'this.#add();' '// see #1234' > src/view.tsx
echo ':root { --ok: #00ff00; }' >> src/styles/tokens.css
sc; [ "$st" = 0 ] && has "⚠ colour.*src/view.tsx: 2 colour" || fail "S14 two loose colours in a view warn, with their count (got $st: $out)"
has "tokens.css" && fail "S15 colours in the tokens file are not loose (got: $out)"

start 13; lines src/generated/huge.ts 60
sc; [ "$st" = 0 ] && ! has "huge" || fail "S16 exempt files are skipped (got $st: $out)"

start 14; rm src/mid.ts
sc; [ "$st" = 0 ] || fail "S17 a deleted file must not break the check (got $st: $out)"

start 15
sc --all; [ "$st" = 1 ] && has "✗ cycle.*src/c1.ts.*log an RF" && has "⚠ size.*src/big.ts" || fail "S18 --all fails on any cycle and warns on files past the cap (got $st: $out)"
has "huge" && fail "S19 --all skips exempt files too (got: $out)"

start 16
printf '%s\n' '## Code limits' '- **File size:** warn at core default lines · cap at core default' > "$tmp/default.md"
lines src/new.ts 501; lines src/mid.ts 301
sc --project "$tmp/default.md"; [ "$st" = 1 ] && has "✗ size.*src/new.ts" && has "⚠ size.*src/mid.ts" ||
  fail "S20 'core default' uses 300 and 500 (got $st: $out)"

start 17; mkdir -p src/moved
git mv src/big.ts src/moved/big.ts; git mv src/c1.ts src/c1b.ts
printf '%s\n' "import { a } from './c1b';" 'export const b = 2;' > src/c2.ts
sc; [ "$st" = 0 ] && has "⚠ size.*src/moved/big.ts.*did not grow" && has "⚠ cycle.*src/c1b.ts" ||
  fail "S21 a moved legacy file and a moved file of an existing cycle only warn (got $st: $out)"

start 18
printf '%s\n' '{' '  "compilerOptions": {' '    "baseUrl": ".",' '    "paths": { "@/*": ["./src/*"] }' '  }' '}' > tsconfig.json
printf '%s\n' "import { b } from '@/lib/b';" > src/a.ts
mkdir -p src/lib; printf '%s\n' "import { a } from '@/a';" > src/lib/b.ts
printf '%s\n' "const x = require('./y');" > src/x.js
printf '%s\n' "const y = require('./x');" > src/y.js
printf '%s\n' "/* eslint-disable */ import { q } from './q2';" > src/q1.ts
printf '%s\n' "import { p } from './q1';" > src/q2.ts
sc; [ "$st" = 1 ] && has "✗ cycle.*src/a.ts, src/lib/b.ts" && has "✗ cycle.*src/x.js, src/y.js" && has "✗ cycle.*src/q1.ts, src/q2.ts" ||
  fail "S22 cycles through tsconfig paths aliases, require() and an import after a block comment must fail (got $st: $out)"
has "import aliases: @/ → src/" || fail "S22b the aliases followed are named (got: $out)"

start 18b; mkdir -p src/components/ui
printf '%s\n' '{' '  "compilerOptions": {' '    "paths": {' '      "@/*": [' '        "./src/*"' '      ],' \
  '      "@/ui/*": ["./src/components/ui/*"]' '    }' '  }' '}' > tsconfig.json
printf '%s\n' "import { b } from '@/ui/button';" > src/form.ts
printf '%s\n' "import { f } from '@/form';" > src/components/ui/button.ts
mkdir -p src/ui; printf '%s\n' 'export const decoy = 1;' > src/ui/button.ts
sc; [ "$st" = 1 ] && has "✗ cycle.*src/components/ui/button.ts, src/form.ts" ||
  fail "S22c a multi-line paths entry is read and the longest alias prefix wins (got $st: $out)"

start 19
printf '%s\n' 'def parse():' '    pass' > src/p1.py
printf '%s\n' 'def parse():' '    def inner():' '        pass' > src/p2.py
printf '%s\n' 'export function parse() {}' > src/parse.ts
printf '%s\n' 'usage() { :; }' 'function build {' '  :' '}' > src/a.sh
printf '%s\n' 'usage() { :; }' 'build() { :; }' > src/b.sh
sc; has "⚠ duplicate.*parse: src/p1.py, src/p2.py" && has "⚠ duplicate.*build: src/a.sh, src/b.sh" && ! has "parse.ts\|usage" ||
  fail "S23 duplicates are counted per language, with seeded names left out (got $st: $out)"

start 19b
printf '%s\n' 'export const make: (n: number) => number = (n) => n;' 'export function functionToString() {}' > src/m1.ts
printf '%s\n' 'export const make = (' '  n: number,' ') => n;' 'export function ToString() {}' 'export const total = (1 + 2) * 3;' > src/m2.ts
printf '%s\n' 'export const total = (4 + 5) * 6;' > src/m3.ts
sc; has "⚠ duplicate.*make: src/m1.ts, src/m2.ts" && ! has "ToString\|total" ||
  fail "S23b typed and multi-line arrows count, a name containing 'function' is read whole, expressions are not functions (got $st: $out)"
printf '%s\n' '* { color: #333; }' '/* #444 */' > src/reset.css
sc; has "⚠ colour.*src/reset.css: 1 colour" || fail "S23c a universal-selector line is not a comment (got: $out)"

cd "$r" || exit 1; start 20
sc --project .jacquard/project.md; [ "$st" = 0 ] && has "settings: .*project.md" || fail "S24 a relative --project path is read (got $st: $out)"
sc --project nope.md; [ "$st" = 2 ] || fail "S25 a missing --project file must exit 2 (got $st)"
sc --base nope; [ "$st" = 2 ] || fail "S26 an unknown base must exit 2 (got $st)"
sc --bogus; [ "$st" = 2 ] || fail "S27 an unknown option must exit 2 (got $st)"

# A clone where main exists only as origin/main
git clone -q -b main "$r" "$tmp/cl"; cd "$tmp/cl" || exit 1
git switch -q -c work; git branch -q -D main; lines src/mid.ts 301
sc; [ "$st" = 0 ] && has "changed against origin/main" && has "⚠ size.*src/mid.ts" || fail "S28 with no local main, origin/main is the base (got $st: $out)"

# A repo with neither main nor master, and no project.md
t="$tmp/trunk"; git init -q -b trunk "$t"; cd "$t" || exit 1
echo x > a.ts; git add -A; git commit -q -m one
sc; [ "$st" = 2 ] && has "pass --base" || fail "S29 with no main or master, it must exit 2 and say to pass --base (got $st: $out)"
sc --base trunk; [ "$st" = 0 ] && has "settings: core defaults" || fail "S30 without project.md, the core defaults are named (got $st: $out)"

mkdir -p "$tmp/notgit"; cd "$tmp/notgit" || exit 1
sc; [ "$st" = 2 ] || fail "S31 outside a git repo must exit 2 (got $st)"

finish "structure-check"
