#!/usr/bin/env bash
# Blocks personal data from reaching the public kit. Fails closed.
#
# Usage:
#   scripts/privacy-check.sh [repo_dir] [terms_file]
#       Files in the working tree: tracked plus untracked-not-ignored (content, paths, link targets).
#   scripts/privacy-check.sh --staged [repo_dir] [terms_file]
#       What the next commit would record: added lines, paths, author and committer identity.
#   scripts/privacy-check.sh --objects [repo_dir] [terms_file]   < object ids, one per line
#       What a push would publish: each commit's identity, message, added lines and paths (merges
#       against each parent); each tag's message. Used by scripts/hooks/pre-push.
#
# terms_file: $JACQUARD_PRIVACY_TERMS, else ~/repos/jacquard-personal/privacy-terms.txt.
#   One term per line; "# ..." comments. A line "!Name <email>" allows that exact commit identity
#   (e.g. your public no-reply identity); it must be a full identity and contain one of your terms.
#   A line "=<id> <path>" allows one binary you reviewed by hand (an image without metadata) at that
#   path with that exact content; <id> is `git hash-object --no-filters <path>`. Any change refuses it again.
# Matching ignores case and accents (both sides folded to ASCII with iconv; required).
# Encoded content: UTF-16 and 8-bit text that is not UTF-8 (read as Windows-1252) are converted and
# checked; base64 runs (standard or URL-safe, 8+ characters) are decoded at every alignment and their
# text is checked; binary or compressed content, also inside base64, cannot be read, so it is refused.
# The copyright lines of the top-level LICENSE are exempt from terms, not from patterns (files mode).
# Findings name terms by number (their order in the terms file), never by text.
# Exit: 0 clean · 1 something found · 2 nothing could be checked.
set -u
set -o pipefail
# A UTF-8 locale where there is one (C.UTF-8 on Linux, en_US.UTF-8 on macOS); iconv names its encodings anyway.
if locale -a 2>/dev/null | grep -qix 'c\.utf-\{0,1\}8'; then export LC_ALL=C.UTF-8
elif locale -a 2>/dev/null | grep -qx 'en_US\.UTF-8'; then export LC_ALL=en_US.UTF-8
else export LC_ALL=C; fi

fail() { echo "✗ $1: nothing was checked." >&2; exit 2; }
mode=files
case "${1:-}" in --staged) mode=staged; shift ;; --objects) mode=objects; shift ;; esac
repo="${1:-.}"
terms_file="${2:-${JACQUARD_PRIVACY_TERMS:-$HOME/repos/jacquard-personal/privacy-terms.txt}}"

for tool in iconv awk git grep sed od; do command -v "$tool" >/dev/null 2>&1 || fail "$tool is missing"; done
ids=""
[ "$mode" = objects ] && ids=$(cat)
cd "$repo" 2>/dev/null || fail "cannot enter $repo"
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT

fold() { iconv -f UTF-8 -t ASCII//TRANSLIT -c 2>/dev/null; }
# Some iconv builds (macOS) write é as 'e: then drop those marks after folding, on both sides alike.
case "$(printf 'P\303\251rez\n' | fold)" in
  Perez) ;;
  *[\'\`^\"~]*) fold() { iconv -f UTF-8 -t ASCII//TRANSLIT -c 2>/dev/null | tr -d "'\`^\"~"; } ;;
  *) fail "accents cannot be folded here (no UTF-8 locale for iconv)" ;;
esac
# Added lines of a patch, labelled: only inside hunks, so a line whose text starts with "++ " is kept.
# The top-level LICENSE's added copyright lines go to the copyright stream (exempt from terms only).
# A copyright line is exempt only when it is just years and a holder name (no address, number or email).
holder_re='^Copyright ([(][cC][)] )?[0-9][0-9, -]* [^0-9,@+<>/:]+$'
added() { LC_ALL=C L="$1" awk -v cr="$tmp/copyright" -v re="$holder_re" '
  /^diff --git /{ h = 0; lic = ($0 == "diff --git a/LICENSE b/LICENSE"); next }
  /^@@/{ h = 1; next }
  h && /^\+/{ gsub(/\000/, ""); t = substr($0, 2)
               if (lic && t ~ re && length(t) <= 100) print ENVIRON["L"] "(copyright) " t >> cr; else print ENVIRON["L"] t }'; }
# Prefix every line with a label, safely for any file name. Byte-wise tools run with LC_ALL=C (BSD tr and
# awk stop at invalid UTF-8 under a UTF-8 locale).
label() { LC_ALL=C L="$1" awk '{print ENVIRON["L"] $0}'; }

# Terms: strip BOM, CR, surrounding spaces, comments and blank lines; a last line without newline counts.
[ -f "$terms_file" ] && [ -r "$terms_file" ] || fail "no readable terms file at $terms_file"
sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -- "$terms_file" \
  | grep -v -e '^$' -e '^#' > "$tmp/raw" || fail "the terms file has no terms"
grep -v '^[!=]' "$tmp/raw" | awk '!seen[tolower($0)]++' > "$tmp/terms" || fail "the terms file has no terms"
fold < "$tmp/terms" > "$tmp/terms.f"
grep '^!' "$tmp/raw" | cut -c2- | fold > "$tmp/allow" || true
# Reviewed binaries: "=<id> <path>", a git blob id (SHA-1 or SHA-256) and a path relative to the repo.
grep '^=' "$tmp/raw" | cut -c2- > "$tmp/binok" || true
grep -v -E '^([0-9a-f]{40}|[0-9a-f]{64}) [^ ].*$' "$tmp/binok" | grep -q . && fail "an exception line (=...) must be =<id> <path>, with the id from git hash-object --no-filters"
nterms=$(( $(wc -l < "$tmp/terms") ))
# An allow line must be a full identity, "Name <user@host>", and contain one of the terms.
while IFS= read -r a; do
  printf '%s\n' "$a" | grep -q -E '^[^ <>][^<>]* <[^<>@ ]+@[^<>@ ]+\.[^<>@ ]+>$' || fail "an allow line (!...) must be a full identity: !Name <user@host>"
  ok=0; la=$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]')
  while IFS= read -r t; do
    lt=$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]')
    case "$la" in *"$lt"*) [ "${#la}" -gt "${#lt}" ] && ok=1 ;; esac
  done < "$tmp/terms.f"
  [ "$ok" -eq 1 ] || fail "an allow line (!...) must contain one of your terms"
done < "$tmp/allow"

# One stream of labelled lines with everything that would be published.
out="$tmp/stream"; : > "$out"
: > "$tmp/unreadable"; : > "$tmp/copyright"
# Content of a file or blob as text: UTF-8 as is, 8-bit text read as Windows-1252, UTF-16 converted;
# anything else is listed as unreadable, unless that path with that exact content is a reviewed binary.
# With "blob", UTF-8 text is skipped: the patch already holds it.
inspect() { # source file, label, blob or "", [path in the repo]
  local src="$1" lbl="$2" kind="${3:-}" path="${4:-}" magic from=""
  magic=$(od -An -tx1 -N6 "$src" | tr -d ' \n') || fail "cannot read $lbl"
  case "$magic" in 1f8b*|504b0304*|504b0506*|504b0708*|425a68*|fd377a585a00*|28b52ffd*|377abcaf271c*)
    unreadable; return ;; esac
  nuls=$(( $(LC_ALL=C tr -cd '\000' < "$src" | wc -c) ))
  if [ "$nuls" -eq 0 ]; then
    if iconv -f UTF-8 -t UTF-8 < "$src" > /dev/null 2>&1; then
      [ "$kind" = blob ] || label "$lbl: " < "$src" >> "$out" || fail "cannot read $lbl"
    elif iconv -c -f CP1252 -t UTF-8 < "$src" > "$tmp/conv" 2>/dev/null; then
      # Mostly UTF-8 with a stray byte, or 8-bit text: read it both ways.
      [ "$kind" = blob ] || iconv -c -f UTF-8 -t UTF-8 < "$src" 2>/dev/null | label "$lbl: " >> "$out"
      label "$lbl: " < "$tmp/conv" >> "$out"
    else
      unreadable
    fi
    return
  fi
  case "$magic" in # a BOM, else the NUL of the first character tells the byte order; without a BOM,
    fffe*|feff*) from=UTF-16 ;; # UTF-16 text has NULs in at least a third of its bytes
    00*) [ "${magic:2:2}" != 00 ] && from=UTF-16BE ;;
    ??00*) from=UTF-16LE ;;
  esac
  case "$from" in UTF-16BE|UTF-16LE) [ $(( nuls * 3 )) -ge "$(( $(wc -c < "$src") ))" ] || from="" ;; esac
  if [ -n "$from" ] && iconv -f "$from" -t UTF-8 < "$src" > "$tmp/conv" 2>/dev/null \
     && [ "$(LC_ALL=C tr -d '\t\n\r' < "$tmp/conv" | LC_ALL=C tr -cd '\000-\037' | head -c 1 | wc -c)" -eq 0 ]; then
    label "$lbl: " < "$tmp/conv" >> "$out"
  else
    unreadable
  fi
}
unreadable() { # uses inspect's src, lbl and path
  [ -n "$path" ] && [ -s "$tmp/binok" ] &&
    grep -qxF -- "$(git hash-object --no-filters -- "$src") $path" "$tmp/binok" && return
  printf '%s\n' "$lbl" >> "$tmp/unreadable"
}
emit_file() { # path as listed by git
  local f="$1"
  printf '%s: (path)\n' "$f" | label "" >> "$out"
  if [ -L "$f" ]; then printf '(link to) %s\n' "$(readlink -- "$f")" | label "$f: " >> "$out"; return; fi
  [ -f "$f" ] || return 0
  [ -r "$f" ] || fail "cannot read $f"
  if [ "$f" = LICENSE ]; then # its copyright lines are exempt from terms (kept for patterns); the rest is checked
    LC_ALL=C awk -v re="$holder_re" '$0 ~ re && length($0) <= 100' "$f" | label "LICENSE: (copyright) " >> "$tmp/copyright"
    LC_ALL=C awk -v re="$holder_re" '!($0 ~ re && length($0) <= 100)' "$f" > "$tmp/license"; inspect "$tmp/license" "$f"
  else
    inspect "$f" "$f" "" "$f"
  fi
}
emit_blobs() { # label, then numstat -z records on stdin; every added or changed blob is inspected; rev in $blob_rev
  local lbl="$1" rec p
  while IFS= read -r -d '' rec; do
    p="${rec#*	}"; p="${p#*	}"
    git cat-file blob "$blob_rev:$p" > "$tmp/blob" || fail "cannot read $p"
    inspect "$tmp/blob" "$lbl$p" blob "$p"
  done
}
emit_commit() { # commit id
  local c="$1"
  git log -1 --format="(identity) %an <%ae> | %cn <%ce>%n%B" "$c" | label "commit $c: " >> "$out" || fail "cannot read commit $c"
  git diff-tree -m -r --root --no-commit-id --name-only -z "$c" | tr '\0' '\n' | label "commit $c: (path) " >> "$out" || fail "cannot list paths of $c"
  git show -m --format= --root --no-renames --text --no-textconv --no-ext-diff --src-prefix=a/ --dst-prefix=b/ -p "$c" | added "commit $c: " >> "$out" || fail "cannot read changes of $c"
  blob_rev="$c"
  git diff-tree -m -r --root --no-commit-id --no-renames --diff-filter=d --numstat -z "$c" > "$tmp/numstat" || fail "cannot list changes of $c"
  emit_blobs "commit $c: " < "$tmp/numstat"
}

case "$mode" in
  files)
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git ls-files -z --cached --others --exclude-standard > "$tmp/list" || fail "cannot list files"
    else
      find . -type f -not -path './.git/*' -print0 > "$tmp/list" || fail "cannot list files"
    fi
    listed=$(( $(tr -cd '\0' < "$tmp/list" | wc -c) ))
    while IFS= read -r -d '' f; do emit_file "${f#./}"; done < "$tmp/list"
    scanned=$(grep -a -c ': (path)$' "$out")
    [ "$scanned" -ge "$listed" ] || fail "listed $listed files but scanned $scanned"
    what="$listed files"
    ;;
  staged)
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not a git repository"
    { git var GIT_AUTHOR_IDENT && git var GIT_COMMITTER_IDENT; } | sed -E 's/ [0-9]+ [+-][0-9]{4}$//' | label "staged: (identity) " >> "$out" || fail "cannot read identity"
    git diff --cached --name-only -z | tr '\0' '\n' | label "staged: (path) " >> "$out" || fail "cannot list staged paths"
    git diff --cached --no-renames --text --no-textconv --no-ext-diff --src-prefix=a/ --dst-prefix=b/ -p | added "staged: " >> "$out" || fail "cannot read staged changes"
    blob_rev=":0"
    git diff --cached --no-renames --diff-filter=d --numstat -z > "$tmp/numstat" || fail "cannot list staged changes"
    emit_blobs "staged: " < "$tmp/numstat"
    what="staged changes"
    ;;
  objects)
    n=0
    for id in $ids; do
      case "$(git cat-file -t "$id" 2>/dev/null)" in
        commit) emit_commit "$id" ;;
        tag) git cat-file -p "$id" | label "tag $id: " >> "$out" || fail "cannot read tag $id"
             [ "$(git cat-file -t "$id^{}" 2>/dev/null)" = commit ] || fail "tag $id does not point to a commit" ;;
        *) fail "object $id is not a commit or a tag" ;;
      esac
      n=$((n+1))
    done
    what="$n objects"
    ;;
esac

# Decode base64 runs (8+ characters with padding, not all lowercase letters) into extra lines. Short runs are decoded at
# all four alignments (a prefix may be glued to them) and only text fragments of 4+ bytes are kept; a long
# run that decodes to binary, or any run that starts like compressed data, is unreadable. Byte-wise: LC_ALL=C.
LC_ALL=C awk -v unread="$tmp/unreadable" '
  BEGIN { a = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
          for (i = 1; i <= 64; i++) v[substr(a, i, 1)] = i - 1; v["-"] = 62; v["_"] = 63
          for (i = 0; i < 256; i++) chr[i] = sprintf("%c", i); for (i = 0; i <= 16; i++) pw[i] = 2 ^ i }
  function score(s, k,   n, i, bits, nb, b, good, tot) { # share of printable ASCII bytes, from a sample
    n = length(s); if (n > k + 4000) n = k + 4000; bits = 0; nb = 0; good = 0; tot = 0
    for (i = k + 1; i <= n; i++) {
      bits = bits * 64 + v[substr(s, i, 1)]; nb += 6
      if (nb >= 8) { nb -= 8; b = int(bits / pw[nb]); bits -= b * pw[nb]; if (b == 0) continue; tot++; if ((b >= 32 && b < 127) || b == 9 || b == 10 || b == 13) good++ }
    }
    return tot ? good / tot : 0
  }
  function add(c) { if (fl < 4) { frag = frag c; if (++fl == 4) printf "%s(base64) %s", lbl, frag } else printf "%s", c }
  function cut() { if (fl >= 4) printf "\n"; frag = ""; fl = 0; need = 0 }
  # One line per text fragment of 4+ characters: printable ASCII, or a complete UTF-8 sequence.
  function emit(s, k,   n, i, bits, nb, b, pend) {
    n = length(s); bits = 0; nb = 0; frag = ""; fl = 0; need = 0
    for (i = k + 1; i <= n; i++) {
      bits = bits * 64 + v[substr(s, i, 1)]; nb += 6
      if (nb < 8) continue
      nb -= 8; b = int(bits / pw[nb]); bits -= b * pw[nb]
      if (b == 0) continue
      if (need) {
        if (b >= 128 && b < 192) { pend = pend chr[b]; if (--need == 0) add(pend); continue }
        cut()
      }
      if ((b >= 32 && b < 127) || b == 9) add(chr[b])
      else if (b >= 194 && b <= 244) { need = (b >= 240 ? 3 : (b >= 224 ? 2 : 1)); pend = chr[b] }
      else cut()
    }
    cut()
  }
  { p = index($0, ": "); lbl = (p ? substr($0, 1, p + 1) : ""); where = (p ? substr($0, 1, p - 1) : "line " NR)
    body = (p ? substr($0, p + 2) : $0)   # the label (a path) is not decoded
    gsub(/=+/, "& ", body)   # padding ends a run, and counts toward its length
    n = split(body, parts, /[^A-Za-z0-9+\/_=-]+/)
    for (j = 1; j <= n; j++) {
      run = parts[j]; len = length(run); sub(/=+$/, "", run)
      if (len < 8 || run ~ /^[a-z]+$/) continue
      if (len >= 24 && run ~ /^(H4sIA|UEsDB|QlpoO|\/Td6WFo|KLUv\/|eJ[w-z]|eN[o-r]|eAE)/) { print where " (compressed data in base64)" >> unread; continue }
      if (len < 256) { for (k = 0; k < 4; k++) emit(run, k); continue }
      best = -1; for (k = 0; k < 4; k++) { sc = score(run, k); if (sc > best) { best = sc; bk = k } }
      if (best < 0.85) print where " (binary data in base64)" >> unread
      else emit(run, bk)
    } }' "$out" > "$tmp/decoded" || fail "cannot decode base64"
cat "$out" "$tmp/decoded" > "$tmp/kept"
nkept=$(( $(wc -l < "$tmp/kept") ))
# Fold (LICENSE's copyright lines at the end, for patterns only); replace allowed texts with a marker without letters.
cat "$tmp/kept" "$tmp/copyright" | fold > "$tmp/folded0"
[ "$(( $(wc -l < "$tmp/kept") + $(wc -l < "$tmp/copyright") ))" -eq "$(( $(wc -l < "$tmp/folded0") ))" ] || fail "folding lost lines"
awk -v allowfile="$tmp/allow" '
  BEGIN { while ((getline a < allowfile) > 0) if (a != "") allow[++n] = tolower(a) }
  { line = $0; low = tolower(line)
    for (i = 1; i <= n; i++) while ((p = index(low, allow[i])) > 0) {
      line = substr(line, 1, p-1) "<=>" substr(line, p + length(allow[i])); low = tolower(line) }
    print line }' "$tmp/folded0" > "$tmp/scan" || fail "cannot apply allow lines"
head -n "$nkept" "$tmp/scan" > "$tmp/folded"

found=0
report() { echo "✗ $1"; printf '%s\n' "$2" | head -20 | cut -c1-300 | sed 's/^/    /'; found=1; }
[ -s "$tmp/unreadable" ] && report "cannot be checked (binary, compressed or unknown encoding): remove it or publish it another way.
  An image can carry personal data in its metadata (EXIF: author, camera, place, date), invisible when you look at it.
  To publish one: strip its metadata, review it, then allow that exact file with a line =<id> <path> in your
  terms file (<id>: git hash-object --no-filters <path>). Any later change to the file refuses it again." "$(cat "$tmp/unreadable")"

i=0
while IFS= read -r term; do
  i=$((i+1))
  orig=$(sed -n "${i}p" "$tmp/terms")
  hits=$(grep -a -i -F -- "$term" "$tmp/folded")
  # Terms that do not fold cleanly (non-Latin scripts) are also matched as written.
  case "$term" in *'?'*) hits="$hits$(grep -a -i -F -- "$orig" "$tmp/kept")" ;; esac
  [ -n "$hits" ] && report "term #$i" "$hits"
done < "$tmp/terms.f"

patterns=(
  '/home/[A-Za-z0-9_.-]+'
  '/Users/[A-Za-z0-9_.-]+'
  '[A-Za-z]:\\+Users\\+'
  'wsl(\.localhost|\$)'
  'claude\.ai/(code/)?artifact/[A-Za-z0-9-]+'
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
)
for p in "${patterns[@]}"; do
  # Each match is judged on its own, so an allowed example next to a real value does not hide it.
  lines=$(grep -a -n -o -i -E -- "$p" "$tmp/scan" \
    | grep -a -v -i -E ':[^:]*[@.]example\.(com|org)$|:noreply@anthropic\.com$' | cut -d: -f1 | sort -un)
  [ -z "$lines" ] && continue
  report "pattern: $p" "$(for l in $lines; do sed -n "${l}p" "$tmp/scan"; done)"
done

if [ "$found" -eq 0 ]; then
  echo "✓ Privacy check passed ($what, $nterms terms)"
else
  echo "Privacy check failed: remove the items above before publishing. Terms are numbered in the order of your terms file."
  [ "$mode" = objects ] && echo "A later commit that deletes them is not enough: the earlier commit still publishes them."
fi
exit "$found"
