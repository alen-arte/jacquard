# structure-check part: the repo paths that project.md › Code map names, one per line, a leading ./ dropped.
# In a table row only the Files cell (the second) counts, so the Check cell's commands are left out; on any other
# line of the section every value in backticks counts, except a note (a line starting with >). A value that is not a
# plain path is skipped: a space, a wildcard or brace, ~ or $, a :line or #anchor, or a leading - (a command,
# a pattern or a reference).
/^## / { on = ($0 ~ /^## Code map/); next }
!on || /^[ \t]*>/ { next }
{
  s = $0
  if (s ~ /^[ \t]*\|/) { n = split(s, cell, "|"); s = (n >= 3 ? cell[3] : "") }
  while (match(s, /`[^`]+`/)) {
    v = substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH)
    if (v ~ /[ \t*?[{}$~:#]/ || v ~ /^-/) continue
    sub(/^\.\//, "", v); print v
  }
}
