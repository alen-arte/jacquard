# Import edges "from<TAB>to" between JS/TS files, for structure-check.sh.
# Followed: relative specifiers and wildcard aliases from tsconfig/jsconfig "paths". Not edges: type-only imports
# (erased at build time), dynamic import() (loaded lazily) and comment lines.
# Variables: list (paths relative to the current folder), exts (extensions tried, in order), aliases ("prefix<TAB>target" lines).
function norm(p,   n, a, i, k, out) {
  n = split(p, a, "/"); k = 0
  for (i = 1; i <= n; i++) {
    if (a[i] == "" || a[i] == ".") continue
    if (a[i] == "..") { if (k == 0) return ""; k--; continue }
    part[++k] = a[i]
  }
  out = ""; for (i = 1; i <= k; i++) out = out (i > 1 ? "/" : "") part[i]
  return out
}
function lookup(p,   i, stem) {
  if (p == "") return ""
  if (p in exists) return p
  for (i = 1; i <= ne; i++) if ((p "." ext[i]) in exists) return p "." ext[i]
  for (i = 1; i <= ne; i++) if ((p "/index." ext[i]) in exists) return p "/index." ext[i]
  stem = p
  if (sub(/\.(js|jsx|mjs|cjs)$/, "", stem)) for (i = 1; i <= ne; i++) if ((stem "." ext[i]) in exists) return stem "." ext[i]
  return ""
}
function resolve(from, spec,   dir, i) {
  sub(/[?#].*/, "", spec)
  if (spec ~ /^\.\.?(\/|$)/) {
    dir = from
    if (sub(/\/[^\/]*$/, "", dir) == 0) dir = "."
    return lookup(norm(dir "/" spec))
  }
  for (i = 1; i <= na; i++) if (index(spec, prefix[i]) == 1) return lookup(norm(target[i] "/" substr(spec, length(prefix[i]) + 1)))
  return ""
}
BEGIN {
  ne = split(exts, ext, " ")
  while ((getline l < aliases) > 0) { split(l, kv, "\t"); prefix[++na] = kv[1]; target[na] = kv[2] }
  while ((getline f < list) > 0) { exists[f] = 1; files[++nf] = f }
  for (j = 1; j <= nf; j++) {
    f = files[j]; typ = 0
    while ((getline line < f) > 0) {
      if (line ~ /^[ \t]*(\/\/|\/\*|\*)/) continue
      if (line ~ /^[ \t]*(import|export)[ \t]+type[ \t{]/) typ = 1
      else if (line ~ /^[ \t]*(import|export)[ \t]/) typ = 0
      while (match(line, /(from|import|require\()[ \t]*["\047][^"\047]+["\047]/)) {
        m = substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH)
        kw = m; sub(/[ \t]*["\047].*/, "", kw)
        spec = m; sub(/^[^"\047]*["\047]/, "", spec); sub(/["\047]$/, "", spec)
        if (typ && kw == "from") { typ = 0; continue }
        t = resolve(f, spec)
        if (t != "" && t != f) print f "\t" t
      }
    }
    close(f)
  }
}
