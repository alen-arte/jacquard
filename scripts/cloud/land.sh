# Jacquard cloud bridge, sourced by cloud.sh: what land takes back from the cloud's tip into the local folder, what it
# names before anything runs, and which deletions it applies. The rule for names is rule.sh's.

# The documents a cloud tip ($1) may carry back: regular files that pass doc_problem, one path per line, relative to
# the local folder. A file shaped like settings or keys is never taken back and only counted, in $tmp/skipped. A link,
# a special file, a dot name, an unusual name or a .cloud copy stops the land before a file is written.
cloud_docs() {
  tab="$(printf '\t')"; out_of_it="remove it in a cloud session (git rm), push, then cloud.sh land again"
  : > "$tmp/skipped"
  git -c core.quotePath=false ls-tree -r "$1" -- .cloud-kit/local | while IFS= read -r line; do
    mode="${line%% *}"; f="${line#*"$tab"}"; f="${f#.cloud-kit/local/}"
    [ "$f" != away/.away-active ] || { echo "  ⚠ the cloud tracks its Away marker ($f): not landed; the next prepare removes it there" >&2; continue; }
    case "$mode" in 100644|100755) ;; *) die "the cloud's documents hold a link or something that is not a file ($(printf '%s' "$f" | plain)): nothing landed; $out_of_it" ;; esac
    p="$(doc_problem "$f")"
    [ "$p" != "looks like settings or keys" ] || { echo "$f" >> "$tmp/skipped"; continue; }
    [ -z "$p" ] || die "$p among the cloud's documents ($(printf '%s' "$f" | plain)): nothing landed; $out_of_it"
    echo "$f"
  done
}

# The files the cloud changed from the sync point ($1) to its tip ($2) that run code or give Claude instructions, in
# the repo and in the local folder (its instruction files, an Away brief, a document that gains an @ import, scripts,
# anything executable before or after): the user sees them before any check runs here or anyone follows them.
# Matched in any case, for case-insensitive disks. One line, plain.
landed_runs() {
  _g="git -c core.quotePath=false diff --no-ext-diff --no-textconv"
  { $_g --name-only "$1" "$2" -- . $(excludes) \
      | grep -iE '(^|/)(package\.json|Makefile|CLAUDE[^/]*\.md|\.mcp\.json|\.envrc|\.pre-commit-config\.yaml|\.?lefthook(-local)?\.ya?ml)$|^\.husky/|^\.github/workflows/|^\.claude/|(^|/)\.?(git-?)?hooks/' || true
    $_g --name-only "$1" "$2" -- .cloud-kit/local | sed 's|^\.cloud-kit/local/||' | while IFS= read -r f; do
      _l="$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')"
      local_instruction "$_l" && { echo "$local_dir/$f"; continue; }
      case "$_l" in away/brief*.md|package.json|*/package.json|makefile|*/makefile|claude*.md|*/claude*.md|*.sh|*.bash|*.zsh|*.py|*.mjs|*.cjs|*.js|*.ts|*.rb|*.pl|*.ps1)
        echo "$local_dir/$f" ;; esac
    done
    $_g --text -U0 "$1" "$2" -- '.cloud-kit/local/*.md' \
      | awk -v l="$local_dir/" '/^\+\+\+ / { f = $0; sub(/^\+\+\+ b\/\.cloud-kit\/local\//, "", f); next } /^\+(.*[ \t])?@[^ \t]/ { print l f }'
    $_g --raw "$1" "$2" -- .cloud-kit/local \
      | awk -F '\t' -v l="$local_dir/" '{ split($1, a, " ") } a[1] == ":100755" || a[2] == "100755" { sub(/^\.cloud-kit\/local\//, "", $2); print l $2 }'
  } | plain | sort -u | tr '\n' ' '
}

# Deletions: what the sync point ($sp) carried and the cloud's tip ($tip) no longer has goes here too. Only when this
# computer wrote that sync point (its own record: the cloud cannot forge what "unchanged" means), never more than
# max_deletions or half the folder at once, and only a plain file the layer versions, unchanged since the sync point
# and since the layer's last commit (so git can bring it back), never one of the local folder's instruction files.
land_deletions() {
  nl='
'; kept=""
  git -c core.quotePath=false ls-tree -r --name-only "$tip" -- .cloud-kit/local | sed 's|^\.cloud-kit/local/||' > "$tmp/now"
  git -c core.quotePath=false ls-tree -r --name-only "$sp" -- .cloud-kit/local | sed 's|^\.cloud-kit/local/||' \
    | { grep -vxF -f "$tmp/now" || true; } > "$tmp/gone"
  n="$(grep -c . "$tmp/gone" || true)"; [ "$n" != 0 ] || return 0
  had="$(git ls-tree -r --name-only "$sp" -- .cloud-kit/local | grep -c .)"
  why=""
  if [ "$sp" != "$(sed -n 1p "$(rec)" 2>/dev/null)" ] || [ -z "$(sed -n 2p "$(rec)" 2>/dev/null)" ]; then
    why="this computer did not write the last sync point"
  elif [ "$n" -gt "$max_deletions" ]; then
    why="$n at once is more than the $max_deletions land deletes on its own"
  elif [ $((n * 2)) -gt "$had" ]; then
    why="$n of $had is more than half the folder"
  fi
  if [ -n "$why" ]; then
    echo "  ⚠ deleted in the cloud, not here ($why). Delete them by hand if they should go; otherwise the next prepare sends them back. Names written in the cloud:"
    plain < "$tmp/gone" | capped; return 0
  fi
  while IFS= read -r f; do
    [ -z "$(doc_problem "$f")" ] && [ -f "$proj/$f" ] && [ ! -L "$proj/$f" ] || continue   # gone here too, or not a plain file
    local_instruction "$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')" && { kept="$kept$f (an instruction file: delete it by hand)$nl"; continue; }
    inside_local "$f" || { kept="$kept$f (its folder links out of $local_dir)$nl"; continue; }
    ! layer_ignored "$f" || continue                                                        # never what the layer ignores
    if GIT_LITERAL_PATHSPECS=1 git -C "$proj" ls-files --error-unmatch -- "$f" >/dev/null 2>&1 \
      && GIT_LITERAL_PATHSPECS=1 git -C "$proj" diff --quiet HEAD -- "$f" \
      && git show "$sp:.cloud-kit/local/$f" | cmp -s - "$proj/$f"; then
      rm -f -- "$proj/$f"; echo "  layer ✗ $f (deleted in the cloud)"
    else kept="$kept$f (changed here, or not backed up in the layer yet)$nl"; fi
  done < "$tmp/gone"
  [ -z "$kept" ] || { echo "  ⚠ deleted in the cloud, but kept here:"; printf '%s' "$kept" | capped; }
}
