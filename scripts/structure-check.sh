#!/bin/sh
# Jacquard: mechanical structure check for code (core standards › Scalability). Needs git and POSIX tools.
# It only reads, and only inside the repo: symlinks and paths that leave it (git can store ".." entries) are skipped;
# its own copies of base files live in a temporary folder removed on exit.
# Usage: structure-check.sh [--base <ref>] [--all] [--project <project.md>]
#   default  the files changed against the merge base with <ref> (default: main, master, origin/main, origin/master),
#            committed, uncommitted and untracked; a renamed file is compared with its old path when the rename is
#            staged or committed (git mv, or git add after mv)
#   --all    every file in the repo, once, to measure existing debt
# Settings come from project.md › Code limits (default <repo>/.jacquard/project.md): the numbers after "warn at" and
# "cap at", and the values in backticks on the lines for tokens, exempt files and names that repeat by convention;
# without it, the core defaults. The first line says which.
# ✗ (blocking): a code file past the cap that grew or is new; an import cycle between JS/TS files (relative or tsconfig
#   "paths" imports) that is new or grew, or with --all any cycle.
# ⚠ (warning): past the warning; past the cap without growing; an existing cycle that did not grow; the same top-level
#   function name in several files of one language; colour literals outside the token files.
# Exit 0: no ✗ · 1: at least one ✗ · 2: usage or git error. The last line is "✓ no findings" or "Flagged: <files>",
# the files a reviewer reads whole (for a duplicate, only this change's files); paths with spaces are not supported there.
set -f
export LC_ALL=C

warn=300; cap=500 # the core defaults; a project changes them in project.md, never here
code_ext='js jsx ts tsx mjs cjs mts cts vue svelte astro css scss sass less html py rb go rs java kt swift php c h cc cpp hpp cs sh bash zsh lua dart'
import_ext='js jsx ts tsx mjs cjs mts cts'
colour_ext='css scss sass less html js jsx ts tsx mjs cjs mts cts vue svelte astro'
exempt='*.min.* *.generated.* *generated/* *fixtures/* dist/ build/ vendor/'
tokens='*token* *theme*'
test_globs='*.test.* *.spec.* *__tests__/* tests/ test/ */tests/* */test/*'
repeat_names='main usage die GET POST PUT PATCH DELETE HEAD OPTIONS generateMetadata generateStaticParams generateViewport generateImageMetadata generateSitemaps Page Layout Template Loading Error GlobalError NotFound Default Image sitemap robots manifest load loader action meta links headers middleware'
colour_lines_shown=5
here="$(cd "$(dirname "$0")" && pwd)/structure-check"

usage() { echo "usage: ${0##*/} [--base <ref>] [--all] [--project <project.md>]" >&2; exit 2; }
die() { echo "✗ $1" >&2; exit 2; }
base=""; all=0; project=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) [ $# -ge 2 ] || usage; case "$2" in -*) die "a base cannot start with '-': $2" ;; esac; base="$2"; shift 2 ;;
    --all) all=1; shift ;;
    --project) [ $# -ge 2 ] || usage; case "$2" in /*) project="$2" ;; *) project="$PWD/$2" ;; esac
      [ -f "$project" ] || die "no project file at $2"; shift 2 ;;
    *) usage ;;
  esac
done
for p in edges cycles duplicates colours; do [ -f "$here/$p.awk" ] || die "nothing was checked: structure-check/$p.awk is missing"; done
root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repository"
cd "$root" || die "cannot enter $root"
[ -n "$project" ] || project="$root/.jacquard/project.md"
tmp="$(mktemp -d)" || die "cannot create a temporary folder"
trap 'rm -rf "$tmp"' EXIT
trap 'exit 2' HUP INT TERM

# Settings: only the Code limits section counts; the path is shown without the home folder
case "$project" in "$root"/*) shown="${project#"$root"/}" ;; "$HOME"/*) shown="~/${project#"$HOME"/}" ;; *) shown="$project" ;; esac
settings="core defaults (no project.md)"
if [ -f "$project" ]; then
  awk '/^## / { on = ($0 ~ /^## Code limits/); next } on' "$project" > "$tmp/limits"
  settings="core defaults ($shown has no Code limits section)"
fi
if [ -s "$tmp/limits" ]; then
  settings="$shown"
  ticks() { awk -v key="$1" 'index($0, key) { s = $0; while (match(s, /`[^`]+`/)) { printf "%s ", substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) } }' "$tmp/limits"; }
  n="$(awk 'match($0, /warn at [0-9]+/) { print substr($0, RSTART + 8, RLENGTH - 8); exit }' "$tmp/limits")"; [ -n "$n" ] && warn="$n"
  n="$(awk 'match($0, /cap at [0-9]+/) { print substr($0, RSTART + 7, RLENGTH - 7); exit }' "$tmp/limits")"; [ -n "$n" ] && cap="$n"
  exempt="$exempt $(ticks 'Files exempt')"
  tokens="$tokens $(ticks 'Where configuration, tokens and copy live')"
  repeat_names="$repeat_names $(ticks 'Names that repeat by convention')"
fi

# in_list <path> <globs…>: a glob ending in / means everything under that folder
in_list() { _p="$1"; shift; for _g; do case "$_g" in */) _g="$_g*" ;; esac; case "$_p" in $_g) return 0 ;; esac; done; return 1; }
has_ext() { _e="${1##*.}"; [ "$_e" != "$1" ] || return 1; case " $2 " in *" $_e "*) return 0 ;; esac; return 1; }
# filter <list> <extensions> [notests]: the listed files with one of the extensions that are not exempt
filter() {
  while IFS= read -r _f; do
    has_ext "$_f" "$2" || continue
    in_list "$_f" $exempt && continue
    [ "${3:-}" = notests ] && in_list "$_f" $test_globs && continue
    printf '%s\n' "$_f"
  done < "$1"
}
# inside <path>: a relative path that stays in the repo (paths come from git, which can store ".." entries)
inside() { case "$1" in "" | /* | .. | ../* | */../* | */..) return 1 ;; esac; return 0; }
# existing: the listed paths that are regular files in the repo, never through a symlink
existing() { while IFS= read -r _f; do inside "$_f" && [ -f "$_f" ] && [ ! -L "$_f" ] && printf '%s\n' "$_f"; done; }
# Wildcard aliases from tsconfig/jsconfig "paths" in the current folder, as "prefix<TAB>target" (first target only)
aliases() {
  for _c in tsconfig.json jsconfig.json; do
    [ -f "$_c" ] && awk '
      match($0, /"baseUrl"[ \t]*:[ \t]*"[^"]*"/) { s = substr($0, RSTART, RLENGTH); sub(/^"baseUrl"[ \t]*:[ \t]*"/, "", s); sub(/"$/, "", s); b = s }
      pend != "" && match($0, /"[^"]*\*"/) { key[++n] = pend; tgt[n] = substr($0, RSTART + 1, RLENGTH - 3); pend = ""; next }
      match($0, /"[^"]*\*"[ \t]*:[ \t]*\[[ \t]*"[^"]*\*"/) { s = substr($0, RSTART, RLENGTH); k = s; sub(/^"/, "", k); sub(/\*".*/, "", k)
        t = s; sub(/.*\[[ \t]*"/, "", t); sub(/\*"$/, "", t); key[++n] = k; tgt[n] = t; next }
      match($0, /"[^"]*\*"[ \t]*:[ \t]*\[[ \t]*$/) { k = substr($0, RSTART + 1); sub(/\*".*/, "", k); pend = k }
      END { for (i = 1; i <= n; i++) { p = (b == "" || b == "." ? "" : b "/") tgt[i]; while (sub(/^\.\//, "", p)) ; print key[i] "\t" p } }' "$_c"
  done
  return 0
}
edges() { awk -v list="$1" -v exts="$import_ext" -v aliases="$2" -f "$here/edges.awk"; }
failed() { die "nothing was checked: the $1 step failed"; }

git ls-files -z --cached --others --exclude-standard | tr '\0' '\n' | sort -u | existing > "$tmp/all"
: > "$tmp/renames"
if [ "$all" = 1 ]; then
  cp "$tmp/all" "$tmp/targets"; scope="every file"
else
  if [ -z "$base" ]; then
    for b in main master origin/main origin/master; do git rev-parse -q --verify "$b^{commit}" >/dev/null && { base="$b"; break; }; done
    [ -n "$base" ] || die "no main or master branch, local or on origin: pass --base <ref>"
  fi
  git rev-parse -q --verify "$base^{commit}" >/dev/null || die "unknown base: $base"
  mb="$(git merge-base "$base" HEAD)" || die "no common history with $base (a shallow clone?)"
  git diff -z -M --name-status --diff-filter=d "$mb" | tr '\0' '\n' |
    awk -v ren="$tmp/renames" '/^R/ { getline o; getline n; print n; print n "\t" o > ren; next } { getline p; print p }' > "$tmp/diff"
  { cat "$tmp/diff"; git ls-files -z --others --exclude-standard | tr '\0' '\n'; } | sort -u | existing > "$tmp/targets"
  scope="changed against $base"
fi
filter "$tmp/targets" "$code_ext" > "$tmp/code"
aliases > "$tmp/aliases" || failed aliases
followed="$(awk -F '\t' '{ printf "%s%s → %s", (NR > 1 ? ", " : ""), $1, $2 } END { if (NR == 0) printf "none" }' "$tmp/aliases")"
echo "structure-check: $(awk 'END { print NR }' "$tmp/code") code files $scope (warn $warn · cap $cap; settings: $settings; import aliases: $followed)"

block=0; warns=0; flagged=""
flag() { for _f; do case " $flagged " in *" $_f "*) ;; *) flagged="${flagged:+$flagged }$_f" ;; esac; done; }
report() { printf '%s %s  %s\n' "$1" "$2" "$3"; if [ "$1" = "✗" ]; then block=$((block + 1)); else warns=$((warns + 1)); fi; }
tab="$(printf '\t')"

# Sizes
awk -v list="$tmp/code" 'BEGIN { while ((getline f < list) > 0) { n = 0; while ((getline l < f) > 0) n++; close(f); print n "\t" f } }' > "$tmp/sizes"
while IFS="$tab" read -r n f; do
  [ "$n" -gt "$warn" ] || continue
  flag "$f"
  if [ "$n" -le "$cap" ]; then report "⚠" size "$f: $n lines, past the warning of $warn"; continue; fi
  if [ "$all" = 1 ]; then report "⚠" size "$f: $n lines, past the cap of $cap (log an RF)"; continue; fi
  was_path="$(awk -F "$tab" -v f="$f" '$1 == f { print $2; exit }' "$tmp/renames")"; [ -n "$was_path" ] || was_path="$f"
  if git cat-file -e "$mb:$was_path" 2>/dev/null; then
    was="$(git show "$mb:$was_path" | awk 'END { print NR }')"
    if [ "$n" -gt "$was" ]; then report "✗" size "$f: $n lines (was $was), past the cap of $cap and grew: split it first"
    else report "⚠" size "$f: $n lines (was $was), past the cap of $cap, did not grow (legacy: log an RF)"; fi
  else report "✗" size "$f: $n lines, new and past the cap of $cap: split it"
  fi
done < "$tmp/sizes"

# Import cycles
filter "$tmp/all" "$import_ext" > "$tmp/js"
edges "$tmp/js" "$tmp/aliases" > "$tmp/edges" || failed imports
awk -f "$here/cycles.awk" "$tmp/edges" > "$tmp/cycles" || failed cycles
if [ "$all" = 1 ]; then
  sed "s/^/all$tab/" "$tmp/cycles" > "$tmp/cycles.marked"
else
  # Only cycles through a changed file; each is new unless one cycle at the base held all its files (by their old paths)
  awk -v list="$tmp/code" 'BEGIN { while ((getline f < list) > 0) changed[f] = 1 }
    { n = split($0, m, ", "); for (i = 1; i <= n; i++) if (m[i] in changed) { print; next } }' "$tmp/cycles" > "$tmp/touched"
  : > "$tmp/before"
  if [ -s "$tmp/touched" ]; then
    mkdir "$tmp/base" || die "cannot create a temporary folder"
    git ls-tree -r -z --name-only "$mb" | tr '\0' '\n' > "$tmp/base.all"
    filter "$tmp/base.all" "$import_ext" | while IFS= read -r f; do inside "$f" && printf '%s\n' "$f"; done > "$tmp/base.js"
    for c in tsconfig.json jsconfig.json; do git cat-file -e "$mb:$c" 2>/dev/null && git show "$mb:$c" > "$tmp/base/$c"; done
    while IFS= read -r f; do
      case "$f" in */*) mkdir -p "$tmp/base/${f%/*}" ;; esac
      git show "$mb:$f" > "$tmp/base/$f" || die "cannot read $f at the base"
    done < "$tmp/base.js"
    (cd "$tmp/base" && aliases > "$tmp/base.aliases" && edges "$tmp/base.js" "$tmp/base.aliases" > "$tmp/base.edges") || failed "base imports"
    awk -f "$here/cycles.awk" "$tmp/base.edges" > "$tmp/before" || failed "base cycles"
  fi
  awk -v before="$tmp/before" -v renames="$tmp/renames" '
    BEGIN { while ((getline l < renames) > 0) { split(l, r, "\t"); old[r[1]] = r[2] }
      while ((getline l < before) > 0) { nb++; n = split(l, m, ", "); for (i = 1; i <= n; i++) in_b[nb, m[i]] = 1 } }
    { n = split($0, m, ", "); was = 0
      for (j = 1; j <= nb && !was; j++) { was = 1; for (i = 1; i <= n; i++) { p = (m[i] in old) ? old[m[i]] : m[i]; if (!((j, p) in in_b)) { was = 0; break } } }
      print (was ? "old" : "new") "\t" $0 }' "$tmp/touched" > "$tmp/cycles.marked"
fi
while IFS="$tab" read -r kind members; do
  flag $(printf '%s' "$members" | sed 's/, / /g')
  case "$kind" in
    new) report "✗" cycle "$members: import cycle, new or grown: break it (an import used only for types can be written 'import type')" ;;
    all) report "✗" cycle "$members: import cycle (log an RF; a change that grows it is blocked)" ;;
    *) report "⚠" cycle "$members: existing import cycle, not grown (log an RF)" ;;
  esac
done < "$tmp/cycles.marked"

# The same top-level function name in several files (tests left out)
filter "$tmp/all" "$code_ext" notests > "$tmp/dup.files"
awk -v list="$tmp/dup.files" -v changed="$tmp/code" -v all="$all" -v ignore=" $repeat_names " -f "$here/duplicates.awk" > "$tmp/dups.raw" || failed duplicates
sort "$tmp/dups.raw" > "$tmp/dups"
while IFS="$tab" read -r name files mine; do
  flag $mine
  report "⚠" duplicate "$name: $files (one definition, many uses: extract it, or rename if they differ)"
done < "$tmp/dups"

# Colour literals outside the token files (tests left out)
filter "$tmp/targets" "$colour_ext" notests | while IFS= read -r f; do in_list "$f" $tokens || printf '%s\n' "$f"; done > "$tmp/colour.files"
awk -v list="$tmp/colour.files" -v shown="$colour_lines_shown" -f "$here/colours.awk" > "$tmp/colours" || failed colours
while IFS="$tab" read -r f n at; do
  flag "$f"
  report "⚠" colour "$f: $n colour literals outside the tokens (lines $at)"
done < "$tmp/colours"

if [ $((block + warns)) = 0 ]; then echo "✓ no findings"; exit 0; fi
echo "$block blocking · $warns warnings"
echo "Flagged: $flagged"
[ "$block" = 0 ]
