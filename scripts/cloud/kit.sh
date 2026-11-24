# Jacquard cloud bridge, sourced by cloud.sh: what travels inside the kit branch, and what may come back.

# Writes the kit into the working folder $1: the installed kit's own tracked files, the preferences, everything in the
# local folder that travels (travelling), the cloud's bootstrap, instructions and settings.
build_kit() {
  wt="$1"; k="$wt/.cloud-kit"
  [ "$(git -C "$proj" rev-parse --show-toplevel 2>/dev/null)" = "$(cd "$layer" && pwd -P)" ] \
    || die "$layer is not its own git repo: cannot tell private files apart, nothing pushed"
  git -C "$kit" rev-parse -q --verify HEAD >/dev/null || die "$kit is not a git checkout: cannot tell its files from leftovers, nothing pushed"
  git -C "$layer" ls-files --error-unmatch preferences.md >/dev/null 2>&1 || die "the personal layer does not version preferences.md: nothing pushed"
  mkdir -p "$k/jacquard" "$k/personal" "$k/local" "$wt/.claude/skills" "$wt/.claude/agents"
  git -C "$kit" archive HEAD core roles scripts skills agents CHANGELOG.md | tar -x -C "$k/jacquard"   # no tests, docs or templates
  cp "$layer/preferences.md" "$k/personal/"
  all="$(travelling)"; send="$(printf '%s\n' "$all" | sed -n 's/^+//p')"
  waiting="$(git -C "$proj" -c core.quotePath=false ls-files --cached --others --exclude-standard -- '*.cloud' | plain)"
  [ -z "$waiting" ] || die "a document changed in both places is still waiting: merge each <file>.cloud into its <file> and delete it (git rm if the layer tracks it), then commit the layer. Nothing pushed:
$(printf '%s\n' "$waiting" | capped)"
  # files the personal layer does not version yet might be private, so they stop the sync (only those that would travel)
  new=""; [ -z "$send" ] || new="$(git -C "$proj" -c core.quotePath=false ls-files --others --exclude-standard -- . | grep -xF -e "$send" || true)"
  [ -z "$new" ] || die "the personal layer does not version these yet, nothing pushed. Look at each one: real data or real names go in the layer's .gitignore; anything else is backed up with personal-sync.sh. Say which went where.
$(printf '%s\n' "$new" | capped)"
  printf '%s\n' "$all" | sed -n 's/^-\([^:]*\): /⚠ not sent to the cloud (\1): /p' | capped
  printf '* -text -filter -ident !eol !working-tree-encoding\n' > "$k/.gitattributes"   # bytes as they are: no LFS, no line ends
  printf '%s\n' "$send" | while IFS= read -r f; do   # -P: a link stays a link, and the check below stops it
    [ -z "$f" ] || { mkdir -p "$k/local/$(dirname "$f")"; cp -P "$proj/$f" "$k/local/$f"; }
  done
  [ -z "$(find "$k/local" ! -type f ! -type d)" ] || die "links or special files among the project documents: nothing pushed"
  # a second check, on what was copied: nothing the personal layer ignores leaves
  (cd "$k/local" && find . -type f -print0) | git -C "$proj" check-ignore -z --no-index --stdin | (cd "$k/local" && xargs -0 -r rm -f --)
  rc=0; (cd "$k/local" && find . -type f -print0) | git -C "$proj" check-ignore -z --no-index --stdin >/dev/null || rc=$?
  [ "$rc" = 1 ] || die "the private-file check failed (rc=$rc): nothing pushed"
  local_size "$send"
  cp -R "$k/jacquard/skills/." "$wt/.claude/skills/"; cp "$k/jacquard/agents/"*.md "$wt/.claude/agents/"  # where Claude Code looks in a project
  printf '%s\n' "$local_dir" > "$k/local-folder"
  cat > "$k/bootstrap.sh" <<'EOF'
#!/bin/sh
# Cloud sessions only: make the kit appear where the framework's own paths expect it.
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
root="${CLAUDE_PROJECT_DIR:-$PWD}"
l="$(cat "$root/.cloud-kit/local-folder")"
case "$l" in ""|.|..|*[!A-Za-z0-9._-]*) echo "Jacquard: unusual local folder name in .cloud-kit/local-folder, kit not linked" >&2; exit 0 ;; esac
mkdir -p "$HOME/.claude" "$HOME/repos/jacquard-personal"
[ -e "$HOME/.claude/jacquard" ] || ln -s "$root/.cloud-kit/jacquard" "$HOME/.claude/jacquard"
[ -e "$HOME/repos/jacquard-personal/preferences.md" ] || ln -s "$root/.cloud-kit/personal/preferences.md" "$HOME/repos/jacquard-personal/preferences.md"
[ -e "$root/$l" ] || ln -s "$root/.cloud-kit/local" "$root/$l"
for x in "/$l" /.cloud-kit/local/away/.away-active; do   # the link, and the Away guard's marker of a block run here
  grep -qx "$x" "$root/.git/info/exclude" 2>/dev/null || echo "$x" >> "$root/.git/info/exclude"
done
# then the Away guard's own session start (a resumed Away session starts in Present), as on the computer
exec sh "$HOME/.claude/jacquard/scripts/away-guard.sh" session-start "$l"
EOF
  chmod +x "$k/bootstrap.sh" "$k/jacquard/scripts/"*.sh
  cat > "$wt/CLAUDE.local.md" <<EOF
# Jacquard (cloud session kit)

This branch (\`$out\`) carries the Jacquard framework so a cloud session can use it; the project's own instructions stay in its CLAUDE.md. It lives only in the user's private repo: it never goes to a repo shared with others, and it is never merged into \`main\` or opened as a PR. The user's computer brings the work home with \`cloud.sh land\`.

@.cloud-kit/jacquard/core/standards.md
@.cloud-kit/personal/preferences.md
@.cloud-kit/local/index.md

Cloud notes:
- Here \`origin\` is the user's private repo (the remote called \`$remote\` on their computer). Commit to this same branch, \`$out\`, and push it when the work is closed (core git.md › Cloud sync): that is how it reaches the computer. Never push to \`main\`.
- The computer's permissions travel in \`.claude/settings.json\` (same denials and confirmations, plus the Away guard), so the same commands are blocked or asked here. The local pre-commit guard does not exist here: never commit on \`main\` and never add \`$local_dir\` (it is a link).
- Project documents under \`$local_dir/\` are edited as usual. Here that folder is \`.cloud-kit/local/\`: commit them by that path, \`.cloud-kit/local/…\`, or they never reach the computer. Everything in it travels back, new folders and binaries included, as plain files: never a name with a part that starts with a dot, with a control character, a quote or a backslash, ending in \`.cloud\`, or that looks like settings or keys. \`git rm\` deletes on the computer too (a move is a deletion plus a new file), but only a file unchanged there, never index.md, project.md, away-profile.md or roles/, and never more than $max_deletions at once.
- Never edit this file, \`.claude/settings.json\` or anything else under \`.cloud-kit/\`: the framework and the kit change on the computer only.
- An Away block closed here writes the same report as on the computer, every section included (the reviews too).
- Files the personal layer never versions (real data, family names) do not travel: if the index points to one that is missing here, work from \`docs/decisions.md\` and say what you could not check.
EOF
  python3 "$parts/settings.py" "$repo/.claude/settings.local.json" "$wt/.claude/settings.json" "$local_dir"
}

# One line when the files that travel ($1) weigh more than max_local_mb: every prepare sends all of them.
local_size() {
  b="$( (cd "$proj" && printf '%s\n' "$1" | while IFS= read -r f; do [ -z "$f" ] || cat -- "$f"; done) | wc -c | tr -d ' ')"
  [ "$b" -le $((max_local_mb * 1048576)) ] || echo "  ⚠ $local_dir weighs $((b / 1048576)) MB, over $max_local_mb MB: every prepare sends all of it to the cloud"
}

# What a cloud session on the kit branch would miss, for status: the files that travel ($2) changed here after the
# sync point ($1): new, changed or deleted here; then what never travels by rule ($3, travelling's output), except
# dot names: how many files the layer ignores (never their names: they may be private), and the rest by name.
untravelled() {
  t="$(mktemp -d)"
  git -c core.quotePath=false ls-tree -r "$1" -- .cloud-kit/local \
    | awk -F '\t' '{ split($1, a, " "); sub(/^\.cloud-kit\/local\//, "", $2); print a[3] " " $2 }' > "$t/there"
  printf '%s\n' "$2" | while IFS= read -r f; do   # raw bytes, as prepare stores them (.cloud-kit/.gitattributes)
    [ -z "$f" ] || echo "$(git hash-object --no-filters "$proj/$f") $f"
  done > "$t/here"
  awk 'NR == FNR { there[substr($0, index($0, " ") + 1)] = $1; next }
       { p = substr($0, index($0, " ") + 1); if (!(p in there) || there[p] != $1) print p; delete there[p] }
       END { for (p in there) print p }' "$t/there" "$t/here" | sort | plain > "$t/diff"
  n="$(grep -c . "$t/diff" || true)"
  [ "$n" = 0 ] || { echo "  ⚠ $n file(s) of $local_dir changed here after the last prepare and did not travel to $out (cloud.sh prepare sends them):"; capped < "$t/diff"; }
  rm -rf "$t"
  ign="$(git -C "$proj" ls-files --cached --others --ignored --exclude-standard -- . | grep -c . || true)"
  [ "$ign" = 0 ] || echo "  · never in the cloud, by rule: $ign file(s) the personal layer ignores"
  rule="$(printf '%s\n' "$3" | sed -n '/^-name starts with a dot: /d; s/^-//p')"
  [ -z "$rule" ] || { echo "  · never in the cloud, by rule:"; printf '%s\n' "$rule" | capped; }
}

# The files the cloud changed from the sync point ($1) to its tip ($2) that run code or give Claude instructions, in
# the repo and in the local folder (its instruction files, a document that gains an @ import, scripts, settings,
# anything made executable): the user sees them before any check runs here or anyone follows them. One line, plain.
landed_runs() {
  d="git -c core.quotePath=false diff --no-ext-diff --no-textconv"
  { $d --name-only "$1" "$2" -- . $(excludes) \
      | grep -E '(^|/)(package\.json|Makefile|CLAUDE[^/]*\.md|\.mcp\.json|\.envrc|\.pre-commit-config\.yaml|\.?lefthook(-local)?\.ya?ml)$|^\.husky/|^\.github/workflows/|^\.claude/|(^|/)\.?(git-?)?hooks/' || true
    $d --name-only "$1" "$2" -- .cloud-kit/local | sed 's|^\.cloud-kit/local/||' \
      | grep -E '^(index|project|away-profile)\.md$|^roles/|(^|/)(package\.json|Makefile|CLAUDE[^/]*\.md|[^/]*settings[^/]*\.json)$|\.(sh|bash|zsh|py|mjs|cjs|js|ts|rb|pl|ps1)$' \
      | sed "s|^|$local_dir/|" || true
    $d -U0 "$1" "$2" -- '.cloud-kit/local/*.md' \
      | awk -v l="$local_dir/" '/^\+\+\+ / { f = $0; sub(/^\+\+\+ b\/\.cloud-kit\/local\//, "", f) } /^\+@/ { print l f }'
    $d --raw "$1" "$2" -- .cloud-kit/local \
      | awk -F '\t' -v l="$local_dir/" '{ split($1, a, " ") } a[2] == "100755" { sub(/^\.cloud-kit\/local\//, "", $2); print l $2 }'
  } | plain | sort -u | tr '\n' ' '
}

# Deletions, for land: what the sync point ($sp) carried and the cloud's tip ($tip) no longer has goes here too. Only
# when this computer wrote that sync point (its own record: the cloud cannot forge what "unchanged" means), never more
# than max_deletions or half the folder at once, and only a plain file the layer versions, unchanged since the sync
# point and since the layer's last commit (so git can bring it back), never one of the local folder's instruction files.
land_deletions() {
  nl='
'; kept=""
  git -c core.quotePath=false ls-tree -r --name-only "$sp" -- .cloud-kit/local | sed 's|^\.cloud-kit/local/||' \
    | { grep -vxF -f "$tmp/docs" || true; } > "$tmp/gone"
  n="$(grep -c . "$tmp/gone" || true)"; [ "$n" != 0 ] || return 0
  had="$(git ls-tree -r --name-only "$sp" -- .cloud-kit/local | grep -c .)"
  why=""
  if [ "$sp" != "$(sed -n 1p "$(rec)" 2>/dev/null)" ] || [ -z "$(sed -n 2p "$(rec)" 2>/dev/null)" ]; then
    why="this computer did not write the last sync point"
  elif [ "$n" -gt "$max_deletions" ] || [ $((n * 2)) -gt "$had" ]; then
    why="$n at once is more than land deletes on its own"
  fi
  if [ -n "$why" ]; then
    echo "  ⚠ deleted in the cloud, not here ($why). Delete them by hand if they should go; otherwise the next prepare sends them back. Names written in the cloud:"
    plain < "$tmp/gone" | capped; return 0
  fi
  while IFS= read -r f; do
    [ -z "$(doc_problem "$f")" ] && [ -f "$proj/$f" ] && [ ! -L "$proj/$f" ] || continue   # gone here too, or not a plain file
    case "$f" in index.md|project.md|away-profile.md|roles/*) kept="$kept$f (an instruction file: delete it by hand)$nl"; continue ;; esac
    inside_local "$f" || { kept="$kept$f (its folder links out of $local_dir)$nl"; continue; }
    ! git -C "$proj" check-ignore -q --no-index -- "$f" || continue                          # never what the layer ignores
    if git -C "$proj" ls-files --error-unmatch -- "$f" >/dev/null 2>&1 && git -C "$proj" diff --quiet HEAD -- "$f" \
      && git show "$sp:.cloud-kit/local/$f" | cmp -s - "$proj/$f"; then
      rm -f -- "$proj/$f"; echo "  layer ✗ $f (deleted in the cloud)"
    else kept="$kept$f (changed here, or not backed up in the layer yet)$nl"; fi
  done < "$tmp/gone"
  [ -z "$kept" ] || { echo "  ⚠ deleted in the cloud, but kept here:"; printf '%s' "$kept" | capped; }
}

# The documents a cloud tip ($1) may carry back: regular files that pass doc_problem. Anything else stops the land
# before a file is written. Prints one path per line, relative to the local folder.
cloud_docs() {
  tab="$(printf '\t')"; out_of_it="remove it in a cloud session (git rm), push, then cloud.sh land again"
  git -c core.quotePath=false ls-tree -r "$1" -- .cloud-kit/local | while IFS= read -r line; do
    mode="${line%% *}"; f="${line#*"$tab"}"; f="${f#.cloud-kit/local/}"
    [ "$f" != away/.away-active ] || { echo "  ⚠ the cloud tracks its Away marker ($f): not landed; the next prepare removes it there" >&2; continue; }
    case "$mode" in 100644|100755) ;; *) die "the cloud's documents hold a link or something that is not a file ($(printf '%s' "$f" | plain)): nothing landed; $out_of_it" ;; esac
    p="$(doc_problem "$f")"; [ -z "$p" ] || die "$p among the cloud's documents ($(printf '%s' "$f" | plain)): nothing landed; $out_of_it"
    echo "$f"
  done
}
