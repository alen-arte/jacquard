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
#   One term per line; "# ..." comments. A line "!text" allows that exact text (e.g. your public
#   commit identity); it must contain one of your terms and be longer than it.
# Matching ignores case and accents (both sides folded to ASCII with iconv; required).
# Not covered: encoded content (UTF-16, compressed, base64). LICENSE's copyright line is allowed.
# Findings name terms by number (their order in the terms file), never by text.
# Exit: 0 clean · 1 something found · 2 nothing could be checked.
set -u
set -o pipefail
export LC_ALL=C.UTF-8

fail() { echo "✗ $1: nothing was checked." >&2; exit 2; }
mode=files
case "${1:-}" in --staged) mode=staged; shift ;; --objects) mode=objects; shift ;; esac
repo="${1:-.}"
terms_file="${2:-${JACQUARD_PRIVACY_TERMS:-$HOME/repos/jacquard-personal/privacy-terms.txt}}"

for tool in iconv awk git grep sed; do command -v "$tool" >/dev/null 2>&1 || fail "$tool is missing"; done
ids=""
[ "$mode" = objects ] && ids=$(cat)
cd "$repo" 2>/dev/null || fail "cannot enter $repo"
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT

fold() { iconv -f UTF-8 -t ASCII//TRANSLIT -c 2>/dev/null; }
# Added lines of a patch: only inside hunks, so a line whose text starts with "++ " is kept.
added() { awk '/^diff --git /{h=0; next} /^@@/{h=1; next} h && /^\+/{print}'; }
# Prefix every line with a label, safely for any file name.
label() { L="$1" awk '{print ENVIRON["L"] $0}'; }

# Terms: strip BOM, CR, surrounding spaces, comments and blank lines; a last line without newline counts.
[ -f "$terms_file" ] && [ -r "$terms_file" ] || fail "no readable terms file at $terms_file"
sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -- "$terms_file" \
  | grep -v -e '^$' -e '^#' > "$tmp/raw" || fail "the terms file has no terms"
grep -v '^!' "$tmp/raw" > "$tmp/terms" || fail "the terms file has no terms"
fold < "$tmp/terms" > "$tmp/terms.f"
grep '^!' "$tmp/raw" | cut -c2- | fold > "$tmp/allow" || true
nterms=$(wc -l < "$tmp/terms")
# An allow line must contain one of the terms and be longer than it.
while IFS= read -r a; do
  ok=0; la=$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]')
  while IFS= read -r t; do
    lt=$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]')
    case "$la" in *"$lt"*) [ "${#la}" -gt "${#lt}" ] && ok=1 ;; esac
  done < "$tmp/terms.f"
  [ "$ok" -eq 1 ] || fail "an allow line (!...) must contain one of your terms and be longer than it"
done < "$tmp/allow"

# One stream of labelled lines with everything that would be published.
out="$tmp/stream"; : > "$out"
emit_file() { # path as listed by git
  local f="$1"
  printf '%s: (path)\n' "$f" | label "" >> "$out"
  if [ -L "$f" ]; then printf '(link to) %s\n' "$(readlink -- "$f")" | label "$f: " >> "$out"; return; fi
  [ -f "$f" ] || return 0
  tr -d '\000' < "$f" | label "$f: " >> "$out"
}
emit_commit() { # commit id
  local c="$1"
  git log -1 --format="(identity) %an <%ae> | %cn <%ce>%n%B" "$c" | label "commit $c: " >> "$out" || fail "cannot read commit $c"
  git diff-tree -m -r --root --no-commit-id --name-only -z "$c" | tr '\0' '\n' | label "commit $c: (path) " >> "$out" || fail "cannot list paths of $c"
  git show -m --format= --root --no-renames --text -p "$c" | added | tr -d '\000' | label "commit $c: " >> "$out" || fail "cannot read changes of $c"
}

case "$mode" in
  files)
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git ls-files -z --cached --others --exclude-standard > "$tmp/list" || fail "cannot list files"
    else
      find . -type f -not -path './.git/*' -printf '%P\0' > "$tmp/list" || fail "cannot list files"
    fi
    listed=$(tr -cd '\0' < "$tmp/list" | wc -c)
    while IFS= read -r -d '' f; do emit_file "$f"; done < "$tmp/list"
    scanned=$(grep -a -c ': (path)$' "$out")
    [ "$scanned" -ge "$listed" ] || fail "listed $listed files but scanned $scanned"
    what="$listed files"
    ;;
  staged)
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not a git repository"
    { git var GIT_AUTHOR_IDENT && git var GIT_COMMITTER_IDENT; } | sed -E 's/ [0-9]+ [+-][0-9]{4}$//' | label "staged: (identity) " >> "$out" || fail "cannot read identity"
    git diff --cached --name-only -z | tr '\0' '\n' | label "staged: (path) " >> "$out" || fail "cannot list staged paths"
    git diff --cached --no-renames --text -p | added | tr -d '\000' | label "staged: " >> "$out" || fail "cannot read staged changes"
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

# Drop LICENSE's copyright line; fold; replace allowed texts with a marker that holds no letters.
grep -a -v -E '^LICENSE: Copyright ' "$out" > "$tmp/kept" || true
fold < "$tmp/kept" > "$tmp/folded0"
[ "$(wc -l < "$tmp/kept")" -eq "$(wc -l < "$tmp/folded0")" ] || fail "folding lost lines"
awk -v allowfile="$tmp/allow" '
  BEGIN { while ((getline a < allowfile) > 0) if (a != "") allow[++n] = tolower(a) }
  { line = $0; low = tolower(line)
    for (i = 1; i <= n; i++) while ((p = index(low, allow[i])) > 0) {
      line = substr(line, 1, p-1) "<=>" substr(line, p + length(allow[i])); low = tolower(line) }
    print line }' "$tmp/folded0" > "$tmp/folded" || fail "cannot apply allow lines"

found=0
report() { echo "✗ $1"; printf '%s\n' "$2" | head -20 | sed 's/^/    /'; found=1; }

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
  lines=$(grep -a -n -o -i -E -- "$p" "$tmp/folded" \
    | grep -a -v -i -E ':[^:]*[@.]example\.(com|org)$|:noreply@anthropic\.com$' | cut -d: -f1 | sort -un)
  [ -z "$lines" ] && continue
  report "pattern: $p" "$(for l in $lines; do sed -n "${l}p" "$tmp/folded"; done)"
done

if [ "$found" -eq 0 ]; then
  echo "✓ Privacy check passed ($what, $nterms terms)"
else
  echo "Privacy check failed: remove the items above before publishing. Terms are numbered in the order of your terms file."
  [ "$mode" = objects ] && echo "A later commit that deletes them is not enough: the earlier commit still publishes them."
fi
exit "$found"
