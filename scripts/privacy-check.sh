#!/usr/bin/env bash
# Blocks personal data from reaching the public kit. Fails closed.
#
# Usage:
#   scripts/privacy-check.sh [repo_dir] [terms_file]
#       Files in the working tree: tracked plus untracked-not-ignored (content, paths, link targets).
#   scripts/privacy-check.sh --staged [repo_dir] [terms_file]
#       What the next commit would record: added lines, paths, author and committer identity.
#   scripts/privacy-check.sh --objects [repo_dir] [terms_file]   < object ids, one per line
#       What a push would publish: each commit's identity, message, added lines and paths;
#       each annotated tag's message. Used by scripts/hooks/pre-push.
#
# terms_file: $JACQUARD_PRIVACY_TERMS, else ~/repos/jacquard-personal/privacy-terms.txt.
#   One term per line; "# ..." comments. A line "!text" allows that exact text (e.g. your public
#   commit identity), removed before matching.
# Matching ignores case and accents (both sides are folded to ASCII).
# Not covered: encoded content (UTF-16, compressed, base64). LICENSE's copyright line is allowed.
# Exit: 0 clean · 1 something found · 2 nothing could be checked.
set -u
export LC_ALL=C.UTF-8

mode=files
case "${1:-}" in --staged) mode=staged; shift ;; --objects) mode=objects; shift ;; esac
repo="${1:-.}"
terms_file="${2:-${JACQUARD_PRIVACY_TERMS:-$HOME/repos/jacquard-personal/privacy-terms.txt}}"

ids=""
[ "$mode" = objects ] && ids=$(cat)
cd "$repo" 2>/dev/null || { echo "✗ Cannot enter $repo: nothing was checked."; exit 2; }
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT

fold() { if command -v iconv >/dev/null 2>&1; then iconv -f UTF-8 -t ASCII//TRANSLIT -c 2>/dev/null; else cat; fi; }

# Terms: strip BOM, CR, surrounding spaces, comments and blank lines; a last line without newline counts.
if [ ! -f "$terms_file" ] || [ ! -r "$terms_file" ]; then
  echo "✗ No readable terms file at $terms_file: nothing was checked."; exit 2
fi
sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -- "$terms_file" \
  | grep -v -e '^$' -e '^#' | fold > "$tmp/all"
grep -v '^!' "$tmp/all" | sort -u > "$tmp/terms"
grep '^!' "$tmp/all" | cut -c2- > "$tmp/allow"
nterms=$(wc -l < "$tmp/terms")
if [ "$nterms" -eq 0 ]; then echo "✗ The terms file has no terms: nothing was checked."; exit 2; fi

# One stream of "where: text" lines with everything that would be published.
out="$tmp/stream"; : > "$out"
emit_file() { # path as listed by git
  local f="$1"
  printf '%s: (path)\n' "$f" >> "$out"
  if [ -L "$f" ]; then printf '%s: (link to) %s\n' "$f" "$(readlink -- "$f")" >> "$out"; return; fi
  [ -f "$f" ] || return
  grep -a -n '' -- "$f" | tr -d '\000' | sed "s|^|$f:|" >> "$out"
}
emit_commit() { # commit id
  local c="$1"
  git log -1 --format="(identity) %an <%ae> | %cn <%ce>%n%B" "$c" | sed "s|^|commit $c: |" >> "$out"
  git diff-tree -r --root --no-commit-id --name-only -z "$c" | tr '\0' '\n' | sed "s|^|commit $c: (path) |" >> "$out"
  git show --format= --root --no-renames --text -p "$c" | grep -a '^+' | grep -a -v '^+++ ' \
    | tr -d '\000' | sed "s|^|commit $c: |" >> "$out"
}

case "$mode" in
  files)
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git ls-files -z --cached --others --exclude-standard > "$tmp/list"
    else
      find . -type f -not -path './.git/*' -printf '%P\0' > "$tmp/list"
    fi
    listed=$(tr -cd '\0' < "$tmp/list" | wc -c)
    while IFS= read -r -d '' f; do emit_file "$f"; done < "$tmp/list"
    scanned=$(grep -a -c ': (path)$' "$out")
    if [ "$scanned" -ne "$listed" ]; then echo "✗ Listed $listed files but scanned $scanned: check incomplete."; exit 2; fi
    what="$listed files"
    ;;
  staged)
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "✗ Not a git repository: nothing was checked."; exit 2; }
    { git var GIT_AUTHOR_IDENT; git var GIT_COMMITTER_IDENT; } | sed -E 's/ [0-9]+ [+-][0-9]{4}$//; s|^|staged: (identity) |' >> "$out"
    git diff --cached --name-only -z | tr '\0' '\n' | sed 's|^|staged: (path) |' >> "$out"
    git diff --cached --no-renames --text -p | grep -a '^+' | grep -a -v '^+++ ' | tr -d '\000' | sed 's|^|staged: |' >> "$out"
    what="staged changes"
    ;;
  objects)
    n=0
    for id in $ids; do
      case "$(git cat-file -t "$id" 2>/dev/null)" in
        commit) emit_commit "$id"; n=$((n+1)) ;;
        tag) git cat-file -p "$id" | sed "s|^|tag $id: |" >> "$out"; n=$((n+1)) ;;
        *) echo "✗ Unknown object $id: check incomplete."; exit 2 ;;
      esac
    done
    what="$n objects"
    ;;
esac

# Fold, drop LICENSE's copyright line, remove allowed texts (case-insensitive, exact).
grep -a -v -E '^LICENSE:[0-9]+:Copyright ' "$out" | fold \
  | awk -v allowfile="$tmp/allow" '
      BEGIN { while ((getline a < allowfile) > 0) if (a != "") allow[++n] = tolower(a) }
      { line = $0; low = tolower(line)
        for (i = 1; i <= n; i++) while ((p = index(low, allow[i])) > 0) {
          line = substr(line, 1, p-1) "[allowed]" substr(line, p + length(allow[i]))
          low = tolower(line) }
        print line }' > "$tmp/folded"

found=0
report() { echo "✗ $1"; printf '%s\n' "$2" | head -20 | sed 's/^/    /'; found=1; }

while IFS= read -r term; do
  hits=$(grep -a -i -F -- "$term" "$tmp/folded")
  [ -n "$hits" ] && report "term: $term" "$hits"
done < "$tmp/terms"

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
  echo "Privacy check failed: remove the items above before publishing."
  [ "$mode" = objects ] && echo "A later commit that deletes them is not enough: the earlier commit still publishes them."
fi
exit "$found"
