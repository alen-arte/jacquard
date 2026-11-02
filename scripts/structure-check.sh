#!/bin/sh
# Jacquard: mechanical structure check for code (core standards › Scalability). Reads only; needs git and POSIX tools.
# Usage: structure-check.sh [--base <ref>] [--all] [--project <project.md>]
#   default  the files changed against the merge base with <ref> (main, else master): committed, uncommitted and untracked
#   --all    every file in the repo, once, to measure existing debt
# Limits, exemptions and token paths come from project.md › Code limits (default <repo>/.jacquard/project.md;
# globs in backticks on the "Files exempt" and "Where configuration, tokens and copy live" lines); without it, the core defaults.
# Blocking (exit 1): a code file past the cap that grew or is new; a relative import cycle in JS/TS that is new or grew
# (--all: any cycle). Warnings: past the warning; past the cap without growing; the same top-level function name in
# several files; colour literals outside the token files. Exit 2: usage or git error.
# The last line, "Flagged: …", lists every file with a finding: the files a reviewer reads whole.
set -f
export LC_ALL=C

warn=300; cap=500 # the core defaults; a project changes them in project.md, never here
code_ext='js jsx ts tsx mjs cjs mts cts vue svelte astro css scss sass less html py rb go rs java kt swift php c h cc cpp hpp cs sh bash zsh lua dart'
import_ext='js jsx ts tsx mjs cjs mts cts'
colour_ext='css scss sass less html js jsx ts tsx mjs cjs mts cts vue svelte astro'
exempt='*package-lock.json *yarn.lock *pnpm-lock.yaml *.min.* *.generated.* *generated/* *fixtures/* dist/ build/ vendor/'
tokens='*token* *theme*'
test_globs='*.test.* *.spec.* *__tests__/* tests/ test/ */tests/* */test/*'
dup_ignore='main'
colour_lines_shown=5

usage() { echo "usage: $0 [--base <ref>] [--all] [--project <project.md>]" >&2; exit 2; }
die() { echo "✗ $1" >&2; exit 2; }
base=""; all=0; project=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) [ $# -ge 2 ] || usage; base="$2"; shift 2 ;;
    --all) all=1; shift ;;
    --project) [ $# -ge 2 ] || usage; case "$2" in /*) project="$2" ;; *) project="$PWD/$2" ;; esac; shift 2 ;;
    *) usage ;;
  esac
done
root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repository"
cd "$root" || die "cannot enter $root"
[ -n "$project" ] || project="$root/.jacquard/project.md"

# Values in backticks on the project.md line that contains $1
ticks() { awk -v key="$1" 'index($0, key) { s = $0; while (match(s, /`[^`]+`/)) { printf "%s ", substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) } }' "$project"; }
if [ -f "$project" ]; then
  n="$(awk 'match($0, /warn at [0-9]+/) { print substr($0, RSTART + 8, RLENGTH - 8); exit }' "$project")"; [ -n "$n" ] && warn="$n"
  n="$(awk 'match($0, /cap at [0-9]+/) { print substr($0, RSTART + 7, RLENGTH - 7); exit }' "$project")"; [ -n "$n" ] && cap="$n"
  exempt="$exempt $(ticks 'Files exempt')"
  tokens="$tokens $(ticks 'Where configuration, tokens and copy live')"
fi

tmp="$(mktemp -d)" || die "cannot create a temporary folder"
trap 'rm -rf "$tmp"' EXIT

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
existing() { while IFS= read -r _f; do [ -f "$_f" ] && printf '%s\n' "$_f"; done; }

git ls-files -z --cached --others --exclude-standard | tr '\0' '\n' | sort -u | existing > "$tmp/all"
if [ "$all" = 1 ]; then
  cp "$tmp/all" "$tmp/targets"; scope="every file"
else
  if [ -z "$base" ]; then
    for b in main master; do git rev-parse -q --verify "$b^{commit}" >/dev/null && { base="$b"; break; }; done
    [ -n "$base" ] || die "no main or master branch: pass --base <ref>"
  fi
  git rev-parse -q --verify "$base^{commit}" >/dev/null || die "unknown base: $base"
  mb="$(git merge-base "$base" HEAD)" || die "no common history with $base"
  { git diff -z --name-only --diff-filter=d "$mb"; git ls-files -z --others --exclude-standard; } |
    tr '\0' '\n' | sort -u | existing > "$tmp/targets"
  scope="changed against $base"
fi
filter "$tmp/targets" "$code_ext" > "$tmp/code"
echo "structure-check: $(awk 'END { print NR }' "$tmp/code") code files $scope (warn $warn · cap $cap)"

block=0; warns=0; flagged=""
flag() { for _f; do case " $flagged " in *" $_f "*) ;; *) flagged="${flagged:+$flagged }$_f" ;; esac; done; }
report() { printf '%s %s  %s\n' "$1" "$2" "$3"; if [ "$1" = "✗" ]; then block=$((block + 1)); else warns=$((warns + 1)); fi; }

# Sizes
count_lines() { awk -v list="$1" 'BEGIN { while ((getline f < list) > 0) { n = 0; while ((getline l < f) > 0) n++; close(f); print n "\t" f } }'; }
count_lines "$tmp/code" > "$tmp/sizes"
while IFS="$(printf '\t')" read -r n f; do
  [ "$n" -gt "$warn" ] || continue
  flag "$f"
  if [ "$n" -le "$cap" ]; then report "⚠" size "$f: $n lines, past the warning of $warn"
  elif [ "$all" = 1 ]; then report "⚠" size "$f: $n lines, past the cap of $cap (log an RF)"
  elif git cat-file -e "$mb:$f" 2>/dev/null; then
    was="$(git show "$mb:$f" | awk 'END { print NR }')"
    if [ "$n" -gt "$was" ]; then report "✗" size "$f: $n lines (was $was), past the cap of $cap and grew: split it first"
    else report "⚠" size "$f: $n lines (was $was), past the cap of $cap, did not grow (legacy: log an RF)"; fi
  else report "✗" size "$f: $n lines, new and past the cap of $cap: split it"
  fi
done < "$tmp/sizes"

# Import cycles: relative imports between JS/TS files; type-only imports are erased at build time and do not count
edges() { awk -v list="$1" -v exts="$import_ext" '
function norm(p,   n, a, i, k, out) {
  n = split(p, a, "/"); k = 0
  for (i = 1; i <= n; i++) { if (a[i] == "" || a[i] == ".") continue; if (a[i] == "..") { if (k > 0) k--; continue } part[++k] = a[i] }
  out = ""; for (i = 1; i <= k; i++) out = out (i > 1 ? "/" : "") part[i]; return out
}
function resolve(from, spec,   dir, p, i, stem) {
  sub(/[?#].*/, "", spec); dir = from
  if (sub(/\/[^\/]*$/, "", dir) == 0) dir = ""
  p = norm((dir == "" ? "" : dir "/") spec)
  if (p in exists) return p
  for (i = 1; i <= ne; i++) if ((p "." ext[i]) in exists) return p "." ext[i]
  for (i = 1; i <= ne; i++) if ((p "/index." ext[i]) in exists) return p "/index." ext[i]
  stem = p
  if (sub(/\.(js|jsx|mjs|cjs)$/, "", stem)) for (i = 1; i <= ne; i++) if ((stem "." ext[i]) in exists) return stem "." ext[i]
  return ""
}
BEGIN {
  ne = split(exts, ext, " ")
  while ((getline f < list) > 0) { exists[f] = 1; files[++nf] = f }
  for (j = 1; j <= nf; j++) {
    f = files[j]; typ = 0
    while ((getline line < f) > 0) {
      if (line ~ /^[ \t]*(import|export)[ \t]+type[ \t{]/) typ = 1
      else if (line ~ /^[ \t]*(import|export)[ \t]/) typ = 0
      while (match(line, /(from|import|require\()[ \t]*["\047]\.\.?\/[^"\047]*["\047]/)) {
        m = substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH)
        kw = m; sub(/[ \t]*["\047].*/, "", kw)
        spec = m; sub(/^[^"\047]*["\047]/, "", spec); sub(/["\047]$/, "", spec)
        if (typ && kw == "from") { typ = 0; continue }
        t = resolve(f, spec); if (t != "" && t != f) print f "\t" t
      }
    }
    close(f)
  }
}'; }
# Strongly connected components of more than one file, members sorted, one per line
cycles() { awk -F '\t' '
function visit(v,   i, w, k, c, a, b, s) {
  idx[v] = low[v] = ++count; stack[++sp] = v; on[v] = 1
  for (i = 1; i <= deg[v]; i++) {
    w = to[v, i]
    if (!(w in idx)) { visit(w); if (low[w] < low[v]) low[v] = low[w] }
    else if (on[w] && idx[w] < low[v]) low[v] = idx[w]
  }
  if (low[v] != idx[v]) return
  k = 0
  do { w = stack[sp--]; on[w] = 0; c[++k] = w } while (w != v)
  if (k < 2) return
  for (a = 2; a <= k; a++) { s = c[a]; for (b = a - 1; b >= 1 && c[b] > s; b--) c[b + 1] = c[b]; c[b + 1] = s }
  s = c[1]; for (a = 2; a <= k; a++) s = s ", " c[a]; print s
}
{ if (!($1 in seen)) { seen[$1] = 1; node[++n] = $1 } if (!($2 in seen)) { seen[$2] = 1; node[++n] = $2 } to[$1, ++deg[$1]] = $2 }
END { for (i = 1; i <= n; i++) if (!(node[i] in idx)) visit(node[i]) }'; }
filter "$tmp/all" "$import_ext" > "$tmp/js"
edges "$tmp/js" | cycles > "$tmp/cycles"
if [ "$all" = 1 ]; then
  sed 's/^/new	/' "$tmp/cycles" > "$tmp/cycles.marked"
else
  # Only cycles through a changed file; each is new unless one cycle at the base already held all its files
  awk -v list="$tmp/code" 'BEGIN { while ((getline f < list) > 0) changed[f] = 1 }
    { n = split($0, m, ", "); for (i = 1; i <= n; i++) if (m[i] in changed) { print; next } }' "$tmp/cycles" > "$tmp/touched"
  : > "$tmp/before"
  if [ -s "$tmp/touched" ]; then
    mkdir "$tmp/base" && git archive "$mb" | tar -x -C "$tmp/base"
    git ls-tree -r -z --name-only "$mb" | tr '\0' '\n' > "$tmp/base.all"
    filter "$tmp/base.all" "$import_ext" > "$tmp/base.js"
    (cd "$tmp/base" && edges "$tmp/base.js") | cycles > "$tmp/before"
  fi
  awk -v before="$tmp/before" '
    BEGIN { while ((getline l < before) > 0) { nb++; n = split(l, m, ", "); for (i = 1; i <= n; i++) in_b[nb, m[i]] = 1 } }
    { n = split($0, m, ", "); old = 0
      for (j = 1; j <= nb && !old; j++) { old = 1; for (i = 1; i <= n; i++) if (!((j, m[i]) in in_b)) { old = 0; break } }
      print (old ? "old" : "new") "\t" $0 }' "$tmp/touched" > "$tmp/cycles.marked"
fi
while IFS="$(printf '\t')" read -r kind members; do
  # shellcheck disable=SC2086
  flag $(printf '%s' "$members" | sed 's/, / /g')
  if [ "$kind" = new ]; then report "✗" cycle "$members: import cycle, new or grown: break it"
  else report "⚠" cycle "$members: existing import cycle, not grown (log an RF)"; fi
done < "$tmp/cycles.marked"

# The same top-level function name in more than one file (tests left out)
filter "$tmp/all" "$code_ext" notests > "$tmp/dup.files"
awk -v list="$tmp/dup.files" -v changed="$tmp/code" -v all="$all" -v ignore=" $dup_ignore " '
function add(name, f) { if (index(ignore, " " name " ")) return; if (!((name, f) in got)) { got[name, f] = 1; where[name] = where[name] (where[name] == "" ? "" : ", ") f; nfiles[name]++ } if (f in mine) hit[name] = 1 }
BEGIN {
  while ((getline f < changed) > 0) mine[f] = 1
  while ((getline f < list) > 0) {
    js = f ~ /\.(js|jsx|ts|tsx|mjs|cjs|mts|cts|vue|svelte|astro)$/; py = f ~ /\.py$/; sh = f ~ /\.(sh|bash|zsh)$/
    while ((getline line < f) > 0) {
      if (js && match(line, /^(export[ \t]+)?(default[ \t]+)?(async[ \t]+)?function\*?[ \t]+[A-Za-z_$][A-Za-z0-9_$]*/)) {
        s = substr(line, RSTART, RLENGTH); sub(/.*function\*?[ \t]+/, "", s); add(s, f)
      } else if (js && match(line, /^(export[ \t]+)?(const|let|var)[ \t]+[A-Za-z_$][A-Za-z0-9_$]*/)) {
        s = substr(line, RSTART, RLENGTH); rest = substr(line, RSTART + RLENGTH); sub(/.*[ \t]/, "", s)
        if (rest ~ /^[ \t]*(:[^=]*)?=[ \t]*(async[ \t]+)?(function|\(|[A-Za-z_$][A-Za-z0-9_$]*[ \t]*=>)/) add(s, f)
      } else if (py && match(line, /^(async[ \t]+)?def[ \t]+[A-Za-z_][A-Za-z0-9_]*/)) {
        s = substr(line, RSTART, RLENGTH); sub(/.*[ \t]/, "", s); add(s, f)
      } else if (sh && match(line, /^(function[ \t]+)?[A-Za-z_][A-Za-z0-9_]*[ \t]*\(\)/)) {
        s = substr(line, RSTART, RLENGTH); sub(/[ \t]*\(\)$/, "", s); sub(/.*[ \t]/, "", s); add(s, f)
      }
    }
    close(f)
  }
  for (name in where) if (nfiles[name] > 1 && (all || hit[name])) print name "\t" where[name]
}' | sort > "$tmp/dups"
while IFS="$(printf '\t')" read -r name files; do
  # shellcheck disable=SC2086
  flag $(printf '%s' "$files" | sed 's/, / /g')
  report "⚠" duplicate "$name: $files (one definition, many uses: extract it, or rename if they differ)"
done < "$tmp/dups"

# Colour literals outside the token files (tests left out)
filter "$tmp/targets" "$colour_ext" notests | while IFS= read -r f; do in_list "$f" $tokens || printf '%s\n' "$f"; done > "$tmp/colour.files"
awk -v list="$tmp/colour.files" -v shown="$colour_lines_shown" '
BEGIN {
  while ((getline f < list) > 0) {
    n = 0; nl = 0; at = ""; ln = 0
    while ((getline line < f) > 0) {
      ln++; k = 0; s = line
      while (match(s, /#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]*/)) {
        pre = RSTART > 1 ? substr(s, RSTART - 1, 1) : ""; len = RLENGTH - 1; post = substr(s, RSTART + RLENGTH, 1)
        s = substr(s, RSTART + RLENGTH)
        if (pre ~ /[A-Za-z0-9_&]/ || post ~ /[A-Za-z0-9_-]/) continue
        if (len == 3 || len == 4 || len == 6 || len == 8) k++
      }
      s = line
      while (match(s, /(rgba?|hsla?|hwb|lab|lch|oklab|oklch)\(/)) {
        pre = RSTART > 1 ? substr(s, RSTART - 1, 1) : ""; s = substr(s, RSTART + RLENGTH)
        if (pre !~ /[A-Za-z0-9_-]/ && s !~ /^[ \t]*var\(/) k++
      }
      if (k) { n += k; nl++; if (nl <= shown) at = at (at == "" ? "" : ", ") ln }
    }
    close(f)
    if (n) print f "\t" n "\t" at (nl > shown ? ", …" : "")
  }
}' > "$tmp/colours"
while IFS="$(printf '\t')" read -r f n at; do
  flag "$f"
  report "⚠" colour "$f: $n colour literals outside the tokens (lines $at)"
done < "$tmp/colours"

if [ $((block + warns)) = 0 ]; then echo "✓ no findings"; exit 0; fi
echo "$block blocking · $warns warnings"
echo "Flagged: $flagged"
[ "$block" = 0 ]
