#!/usr/bin/env bash
# Tests for scripts/privacy-check.sh. Run from anywhere: tests/scripts/privacy-check.test.sh
# Exits 0 when every case passes; prints one line per failure.
. "$(dirname "$0")/lib.sh"
check="$kit/scripts/privacy-check.sh"
[ -x "$check" ] || { echo "✗ $check missing or not executable"; exit 1; }

export JACQUARD_PRIVACY_TERMS="$tmp/terms.txt"
printf 'Muñoz\nsecretterm\n' > "$JACQUARD_PRIVACY_TERMS"

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

# LICENSE's copyright line is exempt in commit and push checks too (terms only)
newrepo; echo "Copyright 2026 secretterm" > "$r/LICENSE"
[ "$(staged)" = 0 ] || fail "R7-8 a staged LICENSE copyright line must be allowed"
g commit -q -m lic
g rev-parse HEAD | "$check" --objects "$r" >/dev/null 2>&1; [ $? = 0 ] || fail "R7-9 a pushed LICENSE copyright line must be allowed"
newrepo; mkdir "$r/x" && echo "Copyright 2026 secretterm" > "$r/x/LICENSE"
[ "$(staged)" = 1 ] || fail "R7-10 a staged LICENSE elsewhere gets no exception"

newrepo; echo "Copyright (c) 2026 secretterm" > "$r/LICENSE"
[ "$(files)" = 0 ] || fail "R7-1b a (c) copyright line must be allowed"
[ "$(staged)" = 0 ] || fail "R7-8c the same, staged"
newrepo; echo "Copyright 2026 secretterm, 12 Some Street, +1 555 0100" > "$r/LICENSE"
[ "$(staged)" = 1 ] || fail "R7-11 a copyright line with more than a holder name gets no exception"
[ "$(files)" = 1 ] || fail "R7-11b the same in files mode"

# A mostly-UTF-8 file with one stray byte keeps its accents
newrepo; printf 'by Mu\303\261oz \240\n' > "$r/m.txt"
[ "$(files)" = 1 ] || fail "R6-28 UTF-8 text with one stray byte must still match accented terms"

# A long plain line is not taken for binary base64 in commit checks
newrepo; head -c 9000 /dev/zero | tr '\0' 'a' > "$r/long.txt"; echo >> "$r/long.txt"
[ "$(staged)" = 0 ] || fail "R6-29 a long all-lowercase line must pass staged, as in files mode"

# Many short random hashes (a lockfile) are not decoded into false findings; real words are not "compressed"
# (fixed pseudo-random hashes, so the case gives the same answer on every run)
newrepo; LC_ALL=C awk 'BEGIN { srand(7); a = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  for (i = 0; i < 3000; i++) { h = ""; for (j = 0; j < 86; j++) h = h substr(a, int(rand() * 64) + 1, 1); printf "\"integrity\": \"sha512-%s==\"\n", h } }' > "$r/lock.json"
[ "$(files)" = 0 ] || fail "R6-30 random integrity hashes must pass"
newrepo; echo "const eJsonParser = 1; see KLUvFooBar and H4sIcons" > "$r/a.js"
[ "$(files)" = 0 ] || fail "R6-31 identifiers that look like compressed prefixes must pass"
newrepo; echo "k: $(printf 'from Muñoz' | base64)" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R6-32 an accented term in base64 must still be found"

# More encodings and binaries
newrepo; utf16be() { printf '%s' "$1" | iconv -f UTF-8 -t UTF-16BE; }; utf16be "written by Muñoz" > "$r/u.txt"
[ "$(files)" = 1 ] || fail "R6-22 a term in UTF-16BE without BOM must be found"
newrepo; printf '\211PNG\r\n\032\n\000\000\000\rIHDR' > "$r/i.png"
[ "$(files)" = 1 ] || fail "R6-23 a PNG must be refused"
newrepo; printf 'a\000\nby secretterm here\n' > "$r/odd.bin"
[ "$(files)" = 1 ] || fail "R6-24 a file with a stray NUL is not UTF-16: refused or its term found"
newrepo; echo "by Munoz" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R6-25 an unaccented spelling must match an accented term"
newrepo; echo "k: $(printf Alice | base64)" > "$r/a.md"; printf 'Alice\n' >> "$JACQUARD_PRIVACY_TERMS"
[ "$(files)" = 1 ] || fail "R6-26 a 5-letter term in padded base64 must be found"
newrepo; echo "k: $(printf Juan | base64)" > "$r/a.md"; printf 'Juan\n' >> "$JACQUARD_PRIVACY_TERMS"
[ "$(files)" = 1 ] || fail "R6-26b a 4-letter term in base64 with == must be found"
sed -i.bak -e '/^Alice$/d' -e '/^Juan$/d' "$JACQUARD_PRIVACY_TERMS"
newrepo; echo "Copyright 2026 secretterm" > "$r/LICENSE"; g config diff.noprefix true
[ "$(staged)" = 0 ] || fail "R7-8b the LICENSE exception must not depend on diff.noprefix"
newrepo; echo "k: $(printf 'by secretterm' | iconv -t UTF-16LE | base64)" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R6-27 UTF-16 text inside base64 must be found"

# R26: a binary reviewed by hand is allowed by path and content id ("=<id> <path>" in the terms file)
png() { printf '\211PNG\r\n\032\n\000\000\000\rIHDR%s' "$1"; }
# allow <path>: the terms file becomes the base terms plus one exception for that file of the current repo
allow() { cp "$tmp/terms.bak" "$JACQUARD_PRIVACY_TERMS"; printf '=%s %s\n' "$(cd "$r" && git hash-object -- "$1")" "$1" >> "$JACQUARD_PRIVACY_TERMS"; }
newrepo; mkdir -p "$r/img dir"; png one > "$r/img dir/i.png"
id=$(git hash-object --no-filters "$r/img dir/i.png")
out=$("$check" "$r" 2>&1); st=$?
[ "$st" = 1 ] || fail "R26-1 an unlisted binary must still be refused"
case "$out" in *EXIF*'='*) ;; *) fail "R26-2 the refusal must explain image metadata (EXIF) and how to allow a reviewed file";; esac
cp "$JACQUARD_PRIVACY_TERMS" "$tmp/terms.bak"; allow "img dir/i.png"
[ "$(files)" = 0 ] || fail "R26-3 a binary listed with its path and id must pass (path with a space)"
[ "$(staged)" = 0 ] || fail "R26-4 the same, staged"
g commit -qm img; g rev-parse HEAD | "$check" --objects "$r" >/dev/null 2>&1; [ $? = 0 ] || fail "R26-5 the same, pushed"
png two > "$r/img dir/i.png"
[ "$(files)" = 1 ] || fail "R26-6 a listed binary whose content changed must be refused again"
[ "$(staged)" = 1 ] || fail "R26-6b the same, staged"
png one > "$r/img dir/i.png"; cp "$r/img dir/i.png" "$r/other.png"
[ "$(files)" = 1 ] || fail "R26-7 the same content at another path must be refused"
rm "$r/other.png"; echo "by secretterm" > "$r/note.txt"
allow note.txt
[ "$(files)" = 1 ] || fail "R26-8 an exception never exempts text: its terms are still found"
rm "$r/note.txt"
newrepo; echo "by secretterm" > "$r/a.md"
printf '=%s a.md\n' "$id" >> "$JACQUARD_PRIVACY_TERMS"
[ "$(files)" = 1 ] || fail "R26-9 exception lines must not be read as terms or hide other findings"
newrepo; { png x; printf '\000\000Artist\000by Secretterm\000'; } > "$r/i.png"
allow i.png
[ "$(files)" = 1 ] || fail "R26-11 a term in a reviewed binary's readable text (EXIF author) must still be found"
[ "$(staged)" = 1 ] || fail "R26-11b the same, staged"
cp "$tmp/terms.bak" "$JACQUARD_PRIVACY_TERMS"; printf '=nothex i.png\n' >> "$JACQUARD_PRIVACY_TERMS"
newrepo; "$check" "$r" >/dev/null 2>&1; [ $? = 2 ] || fail "R26-10 a malformed exception line must stop the check (exit 2)"
cp "$tmp/terms.bak" "$JACQUARD_PRIVACY_TERMS"; printf '=\n' >> "$JACQUARD_PRIVACY_TERMS"
newrepo; "$check" "$r" >/dev/null 2>&1; [ $? = 2 ] || fail "R26-10b a bare = line must stop the check (exit 2)"
# A path with a newline never matches an exception line, not even its second line
newrepo; png one > "$r/ok.png"; allow ok.png; nl="x
$(cd "$r" && git hash-object -- ok.png) ok.png"; png one > "$r/$nl"
[ "$(files)" = 1 ] || fail "R26-12 a path with a newline must not match an exception"
[ "$(staged)" = 1 ] || fail "R26-12b the same, staged"
# Compressed files (zip, docx, gzip…) can never be allowed: nothing can read inside them
newrepo; echo "by secretterm" | gzip > "$r/doc.gz"; allow doc.gz
[ "$(files)" = 1 ] || fail "R26-13 compressed content must stay refused even when listed"
# A real-sized binary (1 MB of fixed pseudo-random bytes) passes in all three modes, without noise findings
newrepo; { png x; LC_ALL=C awk 'BEGIN { srand(3); for (i = 0; i < 1048576; i++) printf "%c", int(rand() * 256) }'; } > "$r/big.png"; allow big.png
[ "$(files)" = 0 ] || fail "R26-14 a listed 1 MB binary must pass"
[ "$(staged)" = 0 ] || fail "R26-14b the same, staged"
g commit -qm big; g rev-parse HEAD | "$check" --objects "$r" >/dev/null 2>&1; [ $? = 0 ] || fail "R26-14c the same, pushed"
# Accented names inside a listed binary: UTF-8 (XMP) and UTF-16LE (Windows XP tags)
newrepo; { png x; printf '\000\001<dc:creator>Mu\303\261oz</dc:creator>\000'; } > "$r/i.png"; allow i.png
[ "$(files)" = 1 ] || fail "R26-15 an accented UTF-8 name inside a listed binary must be found"
[ "$(staged)" = 1 ] || fail "R26-15b the same, staged"
newrepo; { png x; printf '\000\001'; utf16le "by Muñoz"; printf '\000\000\001'; } > "$r/i.png"; allow i.png
[ "$(files)" = 1 ] || fail "R26-16 a UTF-16LE name inside a listed binary must be found"
[ "$(staged)" = 1 ] || fail "R26-16b the same, staged"
# Inside a listed binary only terms count: email- and path-shaped noise is common in compressed image data
newrepo; at=@; h=home; { png x; printf '\000\001zq%skv.net\000/%s/qx\000' "$at" "$h"; } > "$r/i.png"; allow i.png
[ "$(files)" = 0 ] || fail "R26-17 pattern-shaped noise inside a listed binary must not be a finding"
[ "$(staged)" = 0 ] || fail "R26-17b the same, staged"
newrepo; { png x; printf '\000\001secretterm%smail.net\000' "$at"; } > "$r/i.png"; allow i.png
[ "$(files)" = 1 ] || fail "R26-17c a term inside a listed binary must still be found"
# Real-sized listed binaries: several fixed seeds at 2 MB, with short terms in the list, never fail on noise
printf 'Ana\nJuan\n' >> "$tmp/terms.bak"
for seed in 11 12 13; do
  newrepo; { png x; LC_ALL=C awk -v s="$seed" 'BEGIN { srand(s); for (i = 0; i < 2097152; i++) printf "%c", int(rand() * 256) }'; } > "$r/big.png"; allow big.png
  [ "$(files)" = 0 ] || fail "R26-19 a listed 2 MB binary (seed $seed) must pass"
done
[ "$(staged)" = 0 ] || fail "R26-19b the same, staged"
sed -i.bak -e '/^Ana$/d' -e '/^Juan$/d' "$tmp/terms.bak"
# Long runs (24+ characters, as in XMP) inside a listed binary are still checked for patterns
newrepo; u=Users; { png x; printf '\000\001<stRef:filePath>file:///%s/qz/Desktop/mockup.psd</stRef:filePath>\000' "$u"; } > "$r/i.png"; allow i.png
[ "$(files)" = 1 ] || fail "R26-20 a home path in a long run inside a listed binary must be found"
[ "$(staged)" = 1 ] || fail "R26-20b the same, staged"
newrepo; { png x; printf '\000\001<CiEmailWork>qz.gomez%sestudio.com.ar</CiEmailWork>\000' "$at"; } > "$r/i.png"; allow i.png
[ "$(files)" = 1 ] || fail "R26-21 an email in a long run inside a listed binary must be found"
# An uncompressed-looking binary (many short pieces on one long line) is read in linear time
newrepo; { png x; LC_ALL=C awk 'BEGIN { for (i = 0; i < 524288; i++) printf "\200A" }'; } > "$r/raw.png"; allow raw.png
start=$(date +%s); st=$(files); secs=$(( $(date +%s) - start ))
[ "$st" = 0 ] || fail "R26-22 a listed 1 MB binary of alternating bytes must pass"
[ "$secs" -le 15 ] || fail "R26-22b it took ${secs}s (quadratic text extraction?)"
# A lone accented name of 6 bytes (UTF-8 or UTF-16LE) is found; a 3-letter term in a long run is found
newrepo; { png x; printf '\000\001Mu\303\261oz\000\001'; } > "$r/i.png"; allow i.png
[ "$(files)" = 1 ] || fail "R26-23 a lone 6-byte UTF-8 name inside a listed binary must be found"
newrepo; { png x; printf '\000\000'; utf16le "Muñoz"; printf '\000\000\001'; } > "$r/i.png"; allow i.png
[ "$(files)" = 1 ] || fail "R26-23b the same in UTF-16LE, at an odd offset"
printf 'Ana\n' >> "$tmp/terms.bak"
newrepo; { png x; printf '\000\001<dc:description>Mockup made by Ana for the client</dc:description>\000'; } > "$r/i.png"; allow i.png
[ "$(files)" = 1 ] || fail "R26-24 a 3-letter term in a long run inside a listed binary must be found"
# The other side of the thresholds: a 3-letter term in a 6-23-byte run, and any term in a run under 6 bytes, are not reported
newrepo; { png x; printf '\000\001by Ana\000\001Juan\000\001'; } > "$r/i.png"; printf 'Juan\n' >> "$tmp/terms.bak"; allow i.png
[ "$(files)" = 0 ] || fail "R26-25 a 3-letter term in a short run, or a 4-letter one in a run under 6 bytes, must not be reported"
newrepo; { png x; printf '\000'; printf 'by Juan Perez' | iconv -f UTF-8 -t UTF-16BE; printf '\000\000\001'; } > "$r/i.png"; allow i.png
[ "$(files)" = 1 ] || fail "R26-25b a UTF-16BE name at an odd offset must be found"
sed -i.bak -e '/^Ana$/d' -e '/^Juan$/d' "$tmp/terms.bak"
newrepo; h=home; echo "/$h/someone/x" > "$r/a: (text in binary) b.txt"
[ "$(files)" = 1 ] || fail "R26-18 a file name that imitates the binary-text label must not hide patterns"
cp "$tmp/terms.bak" "$JACQUARD_PRIVACY_TERMS"

# R31: terms of 5 letters or fewer match only as a whole word; longer ones anywhere
cp "$tmp/terms.bak" "$JACQUARD_PRIVACY_TERMS"; printf 'Ana\nJuan\nPereyra\n' >> "$JACQUARD_PRIVACY_TERMS"
newrepo; echo "a banana and a sha: 9f2cJuanq81e" > "$r/a.md"
[ "$(files)" = 0 ] || fail "R31-1 short terms inside longer words or hashes must not match"
newrepo; echo "written by Ana." > "$r/a.md"
[ "$(files)" = 1 ] || fail "R31-2 a short term as a whole word must be found"
newrepo; echo "contact: juan@example.org" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R31-3 a short term before @ is a whole word and must be found"
newrepo; echo "id xPereyrax" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R31-4 a term of 6+ letters must still match inside a word"
newrepo; echo "by ANA" > "$r/a.md"
[ "$(staged)" = 1 ] || fail "R31-5 a whole-word short term must be found staged, ignoring case"
newrepo; echo "bananas, then Ana" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R31-6 a whole-word occurrence after an in-word one on the same line must be found"
printf '@bo\n' >> "$JACQUARD_PRIVACY_TERMS"; newrepo; echo "mail x@bo" > "$r/a.md"
[ "$(files)" = 1 ] || fail "R31-7 a short term that starts with punctuation matches after any character"
cp "$tmp/terms.bak" "$JACQUARD_PRIVACY_TERMS"

# R7: outside a git repository (no find -printf)
d="$tmp/plain"; mkdir -p "$d/sub" && echo "clean" > "$d/sub/a.md"
"$check" "$d" >/dev/null 2>&1; [ $? = 0 ] || fail "R7-5 a clean folder outside git must pass"
echo "secretterm" > "$d/sub/b.md"
"$check" "$d" >/dev/null 2>&1; [ $? = 1 ] || fail "R7-6 a term in a folder outside git must be found"

finish "privacy-check"
