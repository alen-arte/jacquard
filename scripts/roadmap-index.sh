#!/bin/sh
# Jacquard: derives the "Status index" block of a roadmap from the marks of its items.
# Usage: roadmap-index.sh --write|--check <roadmap.md>
# Items:   "- <mark> **R12 · …"   Proposals: "| <mark> … | **P3 · …"
# Archived groups: a "- 📦 …: R1, R2 → roadmap-done.md" line counts its IDs as Done.
# The block sits between <!-- status-index:start --> and <!-- status-index:end -->.
mode="$1"; file="$2"
case "$mode" in --write|--check) ;; *) echo "usage: $0 --write|--check <roadmap.md>" >&2; exit 2 ;; esac
[ -f "$file" ] || { echo "✗ $file not found" >&2; exit 2; }
grep -q 'status-index:start' "$file" && grep -q 'status-index:end' "$file" ||
  { echo "✗ $file has no status-index markers" >&2; exit 2; }

line="$(awk '
function add(m, id) { ids[m] = (ids[m] == "" ? id : ids[m] ", " id) }
/<!-- status-index:start -->/ { skip = 1 }
/<!-- status-index:end -->/   { skip = 0; next }
skip { next }
{
  if ($0 ~ /^- 📦 /) {
    t = $0; sub(/→.*/, "", t)
    while (match(t, /[RP][0-9]+[a-z]?/)) { add("✅", substr(t, RSTART, RLENGTH)); t = substr(t, RSTART + RLENGTH) }
  } else if (match($0, /^- (✅|🚀|👀|⚖️|⚖|⬜|❌) \*\*[RP][0-9]+[a-z]? /)) {
    mark = substr($0, 3); sub(/ .*/, "", mark); sub(/️/, "", mark)
    id = substr($0, RSTART, RLENGTH); sub(/^.*\*\*/, "", id); sub(/ $/, "", id); add(mark, id)
  } else if (match($0, /^\| (✅|🚀|👀|⚖️|⚖|⬜|🔵|❌)/)) {
    mark = substr($0, 3); sub(/ .*/, "", mark); sub(/️/, "", mark)
    if (match($0, /\*\*P[0-9]+[a-z]? /)) { id = substr($0, RSTART + 2, RLENGTH - 3); add(mark, id) }
  }
}
END {
  n = split("✅ Done|🚀 Staged|👀 Review|⚖ Decide|🔵 Approved|⬜ Waiting|❌ Rejected", st, "|")
  out = ""
  for (i = 1; i <= n; i++) {
    split(st[i], parts, " "); m = parts[1]; label = parts[2]
    shown = (m == "⚖" ? "⚖️" : m)
    list = (ids[m] == "" ? "—" : ids[m])
    out = out (i > 1 ? " · " : "") shown " " label ": " list
  }
  print out
}' "$file")"

tmp="$(mktemp)"
awk -v line="$line" '
/<!-- status-index:start -->/ { print; print line; skip = 1; next }
/<!-- status-index:end -->/   { skip = 0 }
!skip { print }' "$file" > "$tmp"

if [ "$mode" = "--check" ]; then
  if cmp -s "$tmp" "$file"; then rm -f "$tmp"; echo "✓ status index up to date"; exit 0
  else rm -f "$tmp"; echo "✗ status index out of date: run $0 --write $file" >&2; exit 1; fi
fi
cat "$tmp" > "$file"; rm -f "$tmp"; echo "✓ status index written"
