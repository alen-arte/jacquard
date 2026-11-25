# structure-check part: the repo paths that project.md › Code map names, one per line, a leading ./ dropped.
# In a table row only the Files cell (the second) counts, so the Check cell's commands are left out; on any other
# line of the section every value in backticks counts. A value with a space or a wildcard, or that starts with -,
# is a command or a pattern, not a path.
/^## / { on = ($0 ~ /^## Code map/); next }
!on { next }
{
  s = $0
  if (s ~ /^[ \t]*\|/) { n = split(s, cell, "|"); s = (n >= 3 ? cell[3] : "") }
  while (match(s, /`[^`]+`/)) {
    v = substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH)
    if (v ~ /[ \t*?[]/ || v ~ /^-/) continue
    sub(/^\.\//, "", v); print v
  }
}
