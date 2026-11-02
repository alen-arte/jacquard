# Import cycles for structure-check.sh: reads "from<TAB>to" edges and prints each strongly connected component
# of two or more files (Tarjan), members sorted and joined by ", ", one per line.
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
  s = c[1]; for (a = 2; a <= k; a++) s = s ", " c[a]
  print s
}
BEGIN { FS = "\t" }
{
  if (!($1 in seen)) { seen[$1] = 1; node[++n] = $1 }
  if (!($2 in seen)) { seen[$2] = 1; node[++n] = $2 }
  to[$1, ++deg[$1]] = $2
}
END { for (i = 1; i <= n; i++) if (!(node[i] in idx)) visit(node[i]) }
