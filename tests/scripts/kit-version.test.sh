#!/bin/sh
# Tests for scripts/kit-version.sh. Run from anywhere: tests/scripts/kit-version.test.sh
# Exits 0 when every case passes; prints one line per failure.
. "$(dirname "$0")/lib.sh"
script="$kit/scripts/kit-version.sh"
[ -x "$script" ] || { echo "✗ $script missing or not executable"; exit 1; }
kv() { out="$("$script" "$@" 2>&1)"; st=$?; }
has() { printf '%s\n' "$out" | grep -q -e "$1"; }
installed="$(awk '/^## [0-9]+\.[0-9]+\.[0-9]+/ { print $2; exit }' "$kit/CHANGELOG.md")"

l="$tmp/layer"; mkdir -p "$l/projects/old" "$l/projects/same" "$l/projects/none" "$l/projects/newer"
printf '%s\n' '- **Starting point:** B · **Kit version:** 0.1.9 (note)' > "$l/projects/old/index.md"
printf '%s\n' "- **Kit version:** $installed" > "$l/projects/same/index.md"
printf '%s\n' '- **Starting point:** B' > "$l/projects/none/index.md"
printf '%s\n' '- **Kit version:** 0.10.0' > "$l/projects/newer/index.md"

kv project "$l/projects/old/index.md"
[ "$st" = 0 ] && has "on kit 0.1.9; the installed kit is $installed" || fail "K1 a project behind gets the reminder (got $st: $out)"
kv project "$l/projects/same/index.md"; [ "$st" = 0 ] && [ -z "$out" ] || fail "K2 up to date prints nothing (got $st: $out)"
kv project "$l/projects/none/index.md"; [ "$st" = 0 ] && [ -z "$out" ] || fail "K3 no version prints nothing (got $st: $out)"
kv project "$tmp/missing.md"; [ "$st" = 0 ] && [ -z "$out" ] || fail "K4 a missing index prints nothing (got $st: $out)"
kv project "$l/projects/newer/index.md"; [ -z "$out" ] || fail "K5 versions compare by number, 0.10.0 is not behind (got: $out)"

kv all "$l"
[ "$st" = 0 ] && has "^installed kit: $installed" && has "^old: 0.1.9 → $installed (run /jacquard-update there)" &&
  has "^same: $installed (up to date)" && has "^none: no kit version" && has "^newer: 0.10.0 (up to date)" ||
  fail "K6 all lists every project with its state (got $st: $out)"
kv all "$tmp/nolayer"; [ "$st" = 2 ] || fail "K7 a layer with no projects folder is a usage error (got $st)"
kv; [ "$st" = 2 ] || fail "K8 no subcommand is a usage error (got $st)"

finish "kit-version"
