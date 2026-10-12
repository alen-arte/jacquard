#!/bin/sh
# Tests for scripts/roadmap-index.sh. Run from anywhere: tests/scripts/roadmap-index.test.sh
# Exits 0 when every case passes; prints one line per failure.
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/../../scripts/roadmap-index.sh"
[ -x "$script" ] || { echo "✗ $script missing or not executable"; exit 1; }

tmp="$(mktemp -d)" || exit 1
trap 'rm -rf "$tmp"' EXIT
fails=0
fail() { echo "✗ $1"; fails=$((fails + 1)); }

# A well-formed roadmap: the block between whole-line markers is rewritten from the marks
f="$tmp/ok.md"
printf '%s\n' '# Roadmap' '<!-- status-index:start -->' 'stale' '<!-- status-index:end -->' '- ⬜ **R1 · a**' '- ✅ **R2 · b**' > "$f"
"$script" --write "$f" >/dev/null 2>&1 || fail "R1 --write on a well-formed roadmap must succeed"
sed -n 3p "$f" | grep -q '^✅ Done: R2 · .*⬜ Waiting: R1 · ' || fail "R1 the index line must list R2 as done and R1 as waiting"
"$script" --check "$f" >/dev/null 2>&1 || fail "R2 --check right after --write must pass"

# Markers that are not whole lines (inside a sentence or code) do not count: the file is left untouched
f="$tmp/inline.md"
printf '%s\n' '# The block sits between <!-- status-index:start --> and <!-- status-index:end -->.' 'keep this' 'and this' > "$f"
cp "$f" "$f.orig"
"$script" --write "$f" >/dev/null 2>&1; st=$?
[ "$st" = 2 ] && cmp -s "$f" "$f.orig" || fail "R3 markers inside a line must be refused (exit 2) and the file left untouched"

# End before start, or a start with no end after it: refused, untouched
f="$tmp/order.md"
printf '%s\n' '<!-- status-index:end -->' 'keep' '<!-- status-index:start -->' 'keep too' > "$f"
cp "$f" "$f.orig"
"$script" --write "$f" >/dev/null 2>&1; st=$?
[ "$st" = 2 ] && cmp -s "$f" "$f.orig" || fail "R4 an end marker before the start must be refused and the file left untouched"

[ "$fails" = 0 ] && echo "✓ roadmap-index: all cases pass" && exit 0
exit 1
