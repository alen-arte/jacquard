#!/usr/bin/env bash
# Blocks personal data from reaching the public kit.
# Usage: scripts/privacy-check.sh [repo_dir] [terms_file]
# Defaults: repo_dir = current directory; terms_file = $JACQUARD_PRIVACY_TERMS
#           or ~/.claude/jacquard-personal/privacy-terms.txt
# Exit code 1 if anything is found. Use it as a pre-push hook.
# grep -a: files that look binary (a NUL byte) are scanned too, not skipped silently.
set -u
repo="${1:-.}"
terms="${2:-${JACQUARD_PRIVACY_TERMS:-$HOME/.claude/jacquard-personal/privacy-terms.txt}}"
self="scripts/privacy-check.sh"
# LICENSE is skipped on purpose: the author's name belongs there.
cd "$repo" || exit 2

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  files=$(git ls-files --cached --others --exclude-standard | grep -v -x -e "$self" -e "LICENSE")
else
  files=$(find . -type f -not -path './.git/*' | sed 's|^\./||' | grep -v -x -e "$self" -e "LICENSE")
fi

found=0
report() { echo "✗ $1"; echo "$2" | sed 's/^/    /'; found=1; }

if [ -f "$terms" ]; then
  while IFS= read -r term; do
    case "$term" in ''|\#*) continue ;; esac
    hits=$(echo "$files" | xargs -d '\n' grep -a -n -i -F -- "$term" 2>/dev/null | tr -d '\000')
    [ -n "$hits" ] && report "term: $term" "$hits"
  done < "$terms"
else
  echo "! No terms file at $terms: only generic patterns are checked."
fi

patterns=(
  '/home/[a-z0-9_.-]+'
  '/Users/[A-Za-z0-9_.-]+'
  '[A-Za-z]:\\Users\\'
  'wsl\.localhost'
  'claude\.ai/artifact/[A-Za-z0-9]+'
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
)
for p in "${patterns[@]}"; do
  hits=$(echo "$files" | xargs -d '\n' grep -a -n -E -- "$p" 2>/dev/null | tr -d '\000' | grep -v -E 'example\.(com|org)')
  [ -n "$hits" ] && report "pattern: $p" "$hits"
done

if [ "$found" -eq 0 ]; then echo "✓ Privacy check passed"; else echo "Privacy check failed: remove the items above before publishing."; fi
exit "$found"
