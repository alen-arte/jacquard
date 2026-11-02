# Colour literals for structure-check.sh: hex colours (3, 4, 6 or 8 digits) and colour functions (rgb, hsl, hwb, lab,
# lch, oklab, oklch) that do not start from a var(). Comment lines are skipped.
# Prints "file<TAB>count<TAB>first lines" for each file with any. Variables: list (files to read), shown (lines listed).
BEGIN {
  while ((getline f < list) > 0) {
    n = 0; nl = 0; at = ""; ln = 0
    while ((getline line < f) > 0) {
      ln++
      if (line ~ /^[ \t]*(\/\/|\/\*|\*|<!--)/) continue
      k = 0; s = line
      while (match(s, /#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]*/)) {
        pre = RSTART > 1 ? substr(s, RSTART - 1, 1) : ""; len = RLENGTH - 1; post = substr(s, RSTART + RLENGTH, 1)
        s = substr(s, RSTART + RLENGTH)
        if (pre ~ /[A-Za-z0-9_&.]/ || post ~ /[A-Za-z0-9_-]/) continue
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
}
