#!/usr/bin/env bash
# Tests for scripts/privacy-check.sh. Run from anywhere: tests/scripts/privacy-check.test.sh
# Exits 0 when every case passes; prints one line per failure.
here="$(cd "$(dirname "$0")" && pwd)"
check="$here/../../scripts/privacy-check.sh"
[ -x "$check" ] || { echo "✗ $check missing or not executable"; exit 1; }

tmp="$(mktemp -d)" || exit 1
trap 'rm -rf "$tmp"' EXIT
export JACQUARD_PRIVACY_TERMS="$tmp/terms.txt"
printf 'Muñoz\nsecretterm\n' > "$JACQUARD_PRIVACY_TERMS"
export GIT_AUTHOR_NAME=Tester GIT_AUTHOR_EMAIL=tester@example.com GIT_COMMITTER_NAME=Tester GIT_COMMITTER_EMAIL=tester@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
fails=0
fail() { echo "✗ $1"; fails=$((fails + 1)); }

n=0
g() { (cd "$r" && git "$@"); }
newrepo() { n=$((n + 1)); r="$tmp/r$n"; mkdir -p "$r" && git init -q "$r" && echo "clean text" > "$r/README.md"; }
files() { "$check" "$r" >/dev/null 2>&1; echo $?; }
staged() { g add -A && "$check" --staged "$r" >/dev/null 2>&1; echo $?; }
b64() { printf '%s' "$1" | base64 | tr -d '\n'; }
utf16le() { printf '%s' "$1" | iconv -f UTF-8 -t UTF-16LE; }

# Plain text: baseline
newrepo
[ "$(files)" = 0 ] || fail "R6-0 a clean repo must pass"
echo "by secretterm" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R6-0b a plain term must be found"

# UTF-16, with and without BOM, with an accented term
newrepo; { printf '\377\376'; utf16le "written by Muñoz"; } > "$r/u.txt"
[ "$(files)" = 1 ] || fail "R6-1 a term in UTF-16LE with BOM must be found"
newrepo; utf16le "written by Muñoz" > "$r/u.txt"
[ "$(files)" = 1 ] || fail "R6-2 a term in UTF-16LE without BOM must be found"
newrepo; utf16le "nothing personal here" > "$r/u.txt"
[ "$(files)" = 0 ] || fail "R6-3 clean UTF-16 text must pass"

# Compressed or binary content cannot be read: it is refused
newrepo; echo "nothing personal" | gzip > "$r/c.gz"
[ "$(files)" = 1 ] || fail "R6-4 compressed content must be refused (it cannot be checked)"
newrepo; printf 'BZh91AY&SY' > "$r/c.bz2"
[ "$(files)" = 1 ] || fail "R6-5 a bzip2 header without NUL bytes must be refused"

# Base64, standard and URL-safe, including patterns
newrepo; echo "token: $(b64 'contact secretterm now')" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R6-6 a term in base64 must be found"
newrepo; h=home; echo "token=$(b64 "path /$h/someone/x" | tr '+/' '-_' | tr -d '=')" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R6-7 a pattern in URL-safe base64 without padding must be found"
newrepo; echo "name: $(b64 'by Muñoz')" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R6-7b an accented term in base64 must be found"
newrepo; echo "See ThisIsAVeryLongIdentifierNameForTesting and $(b64 'harmless words here')" > "$r/a.md"
[ "$(files)" = 0 ] || fail "R6-8 harmless base64 and long identifiers must pass"

# Staged mode sees the same content
newrepo; utf16le "by Muñoz" > "$r/u.txt"
[ "$(staged)" = 1 ] || fail "R6-9 staged UTF-16 with a term must be found"
newrepo; echo "x" | gzip > "$r/c.gz"
[ "$(staged)" = 1 ] || fail "R6-10 a staged compressed file must be refused"
newrepo; echo "k: $(b64 'secretterm')" > "$r/a.md"
[ "$(staged)" = 1 ] || fail "R6-11 a staged base64 term must be found"
newrepo; utf16le "fine words" > "$r/u.txt"
[ "$(staged)" = 0 ] || fail "R6-12 staged clean UTF-16 must pass"

# Objects mode (what a push publishes)
newrepo; g add -A && g commit -q -m one
echo "k: $(b64 'secretterm')" > "$r/a.md"; utf16le "fine" > "$r/u.txt"
g add -A && g commit -q -m two
g rev-parse HEAD | "$check" --objects "$r" >/dev/null 2>&1; [ $? = 1 ] || fail "R6-13 a pushed base64 term must be found"
newrepo; utf16le "by Muñoz" > "$r/u.txt"; g add -A && g commit -q -m one
g rev-parse HEAD | "$check" --objects "$r" >/dev/null 2>&1; [ $? = 1 ] || fail "R6-14 a pushed UTF-16 term must be found"

# Base64 glued to a prefix, embedded binary, compressed data in base64
newrepo; echo "url: https://cdn.test/files/$(b64 'contact secretterm now')" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R6-15 base64 after a path prefix must be found"
newrepo; echo "token_$(b64 'contact secretterm now')" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R6-16 base64 glued with _ must be found"
newrepo; echo "img: $(head -c 3000 /dev/urandom | base64 | tr -d '\n')" > "$r/a.md"
o="$("$check" "$r" 2>&1)"; st=$?
[ "$st" = 1 ] || fail "R6-17 a long base64 run of binary data must be refused"
[ "${#o}" -lt 4000 ] || fail "R6-17b the report must stay short (${#o} characters)"
newrepo; echo "z: $(echo hello | gzip | base64 | tr -d '\n')" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R6-18 compressed data in base64 must be refused"

# Commit checks read every changed blob, not only the ones git calls binary
newrepo; { head -c 9000 /dev/zero | tr '\0' 'a'; echo; echo x | gzip; } > "$r/mixed.txt"
[ "$(files)" = 1 ] || fail "R6-19 text followed by compressed data must be refused"
[ "$(staged)" = 1 ] || fail "R6-19b the same, staged"

# 8-bit text that is not UTF-8 (Windows-1252) is read as such
newrepo; printf 'by Mu\361oz\n' > "$r/l.txt"
[ "$(files)" = 1 ] || fail "R6-20 a term in Windows-1252 text must be found"
[ "$(staged)" = 1 ] || fail "R6-20b the same, staged"

# A long line does not make the check hang
newrepo; yes 'x=SomethingLong1;' | head -c 1000000 | tr -d '\n' > "$r/min.js"
start=$(date +%s); "$check" "$r" >/dev/null 2>&1; st=$?; secs=$(( $(date +%s) - start ))
[ "$st" = 0 ] || fail "R6-21 a clean minified line must pass"
[ "$secs" -le 20 ] || fail "R6-21b a 1 MB line took ${secs}s"

# R7: the LICENSE exception covers only LICENSE's own copyright line
newrepo; echo "Copyright 2026 secretterm" > "$r/LICENSE"
[ "$(files)" = 0 ] || fail "R7-1 LICENSE's copyright line must be allowed"
newrepo; printf 'secretterm\n' > "$r/LICENSE: Copyright x"
[ "$(files)" = 1 ] || fail "R7-2 a file named like the LICENSE exception must still be checked"
newrepo; mkdir "$r/sub" && echo "Copyright 2026 secretterm" > "$r/sub/LICENSE"
[ "$(files)" = 1 ] || fail "R7-3 a LICENSE in a subfolder gets no exception"
newrepo; echo "Copyright 2026 secretterm" > "$r/LICENSE"; echo "secretterm" >> "$r/LICENSE"
[ "$(files)" = 1 ] || fail "R7-4 only LICENSE's copyright line is allowed, not the rest of it"
newrepo; dom=real-domain.net; echo "Copyright 2026 Someone <someone@$dom>" > "$r/LICENSE"
[ "$(files)" = 1 ] || fail "R7-4b the copyright line is exempt from terms only, not from patterns (an email)"

# R7: outside a git repository (no find -printf)
d="$tmp/plain"; mkdir -p "$d/sub" && echo "clean" > "$d/sub/a.md"
"$check" "$d" >/dev/null 2>&1; [ $? = 0 ] || fail "R7-5 a clean folder outside git must pass"
echo "secretterm" > "$d/sub/b.md"
"$check" "$d" >/dev/null 2>&1; [ $? = 1 ] || fail "R7-6 a term in a folder outside git must be found"

[ "$fails" = 0 ] && echo "✓ privacy-check: all cases pass" && exit 0
echo "✗ privacy-check: $fails failing"; exit 1
