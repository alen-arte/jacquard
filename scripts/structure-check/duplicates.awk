# Duplicate names for structure-check.sh: top-level (unindented) function definitions whose name appears in more than
# one file of the same language family (JS/TS, Python, shell). Declaration files (.d.ts) are skipped.
# Prints "name<TAB>every file, comma-separated<TAB>the files to flag, space-separated", for names this change touches.
# Variables: list (files to read), changed (this change's files), all (1: every name counts), ignore (" name name ").
function add(fam, name, f,   k) {
  if (index(ignore, " " name " ")) return
  k = fam SUBSEP name; label[k] = name
  if (!((k, f) in got)) { got[k, f] = 1; where[k] = where[k] (where[k] == "" ? "" : ", ") f; nfiles[k]++ }
  if ((all || (f in mine)) && !((k, f) in marked)) { marked[k, f] = 1; hit[k] = hit[k] (hit[k] == "" ? "" : " ") f }
}
function arrow(rest) {
  return rest ~ /^[ \t]*=[ \t]*(async[ \t]+)?function/ ||
    rest ~ /^[ \t]*(:[^=]*)?=[ \t]*(async[ \t]+)?(\([^)]*\)|[A-Za-z_$][A-Za-z0-9_$]*)[ \t]*(:[^=]*)?=>/ ||
    rest ~ /^[ \t]*(:[^=]*)?=[ \t]*(async[ \t]+)?\([ \t]*$/ ||
    rest ~ /^[ \t]*:[^=]*=>[^=]*=[ \t]*(async[ \t]+)?(function|\(|[A-Za-z_$][A-Za-z0-9_$]*[ \t]*=>)/
}
BEGIN {
  while ((getline f < changed) > 0) mine[f] = 1
  while ((getline f < list) > 0) {
    if (f ~ /\.d\.ts$/) continue
    fam = f ~ /\.(js|jsx|ts|tsx|mjs|cjs|mts|cts|vue|svelte|astro)$/ ? "js" : f ~ /\.py$/ ? "py" : f ~ /\.(sh|bash|zsh)$/ ? "sh" : ""
    if (fam == "") continue
    while ((getline line < f) > 0) {
      if (fam == "js" && match(line, /^(export[ \t]+)?(default[ \t]+)?(async[ \t]+)?function([ \t]*\*[ \t]*|[ \t]+)[A-Za-z_$][A-Za-z0-9_$]*/)) {
        s = substr(line, RSTART, RLENGTH); sub(/.*[ \t*]/, "", s); add(fam, s, f)
      } else if (fam == "js" && match(line, /^(export[ \t]+)?(const|let|var)[ \t]+[A-Za-z_$][A-Za-z0-9_$]*/)) {
        s = substr(line, RSTART, RLENGTH); rest = substr(line, RSTART + RLENGTH); sub(/.*[ \t]/, "", s)
        if (arrow(rest)) add(fam, s, f)
      } else if (fam == "py" && match(line, /^(async[ \t]+)?def[ \t]+[A-Za-z_][A-Za-z0-9_]*/)) {
        s = substr(line, RSTART, RLENGTH); sub(/.*[ \t]/, "", s); add(fam, s, f)
      } else if (fam == "sh" && match(line, /^(function[ \t]+)?[A-Za-z_][A-Za-z0-9_]*[ \t]*\(\)/)) {
        s = substr(line, RSTART, RLENGTH); sub(/[ \t]*\(\)$/, "", s); sub(/.*[ \t]/, "", s); add(fam, s, f)
      } else if (fam == "sh" && match(line, /^function[ \t]+[A-Za-z_][A-Za-z0-9_]*/)) {
        s = substr(line, RSTART, RLENGTH); sub(/.*[ \t]/, "", s); add(fam, s, f)
      }
    }
    close(f)
  }
  for (k in where) if (nfiles[k] > 1 && hit[k] != "") print label[k] "\t" where[k] "\t" hit[k]
}
