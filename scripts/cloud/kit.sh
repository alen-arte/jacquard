# Jacquard cloud bridge, sourced by cloud.sh: what travels inside the kit branch, and what may come back.

# Writes the kit into the working folder $1: the installed kit's own tracked files, the preferences, the project
# documents the personal layer versions (what it ignores never travels), the cloud's bootstrap, instructions and settings.
build_kit() {
  wt="$1"; k="$wt/.cloud-kit"
  [ "$(git -C "$proj" rev-parse --show-toplevel 2>/dev/null)" = "$(cd "$layer" && pwd -P)" ] \
    || die "$layer is not its own git repo: cannot tell private files apart, nothing pushed"
  git -C "$kit" rev-parse -q --verify HEAD >/dev/null || die "$kit is not a git checkout: cannot tell its files from leftovers, nothing pushed"
  git -C "$layer" ls-files --error-unmatch preferences.md >/dev/null 2>&1 || die "the personal layer does not version preferences.md: nothing pushed"
  mkdir -p "$k/jacquard" "$k/personal" "$k/local/away" "$wt/.claude/skills" "$wt/.claude/agents"
  git -C "$kit" archive HEAD core roles scripts skills agents CHANGELOG.md | tar -x -C "$k/jacquard"   # no tests, docs or templates
  cp "$layer/preferences.md" "$k/personal/"
  # documents that the personal layer does not know yet might be private, so they stop the sync
  new="$(git -C "$proj" ls-files --others --exclude-standard -- index.md project.md away-profile.md docs roles 'away/*.md')"
  case "$new" in *.cloud*) die "a document changed in both places is still waiting: merge each <file>.cloud into its <file> and delete it, then commit the layer. Nothing pushed:
$new" ;; esac
  [ -z "$new" ] || die "the personal layer does not version these yet (commit or ignore them first), nothing pushed:
$new"
  for f in index.md project.md away-profile.md; do cp "$proj/$f" "$k/local/"; done        # documents only: no QA captures, backups or diffs
  cp -R "$proj/docs" "$proj/roles" "$k/local/"
  cp "$proj"/away/*.md "$k/local/away/" 2>/dev/null || true
  [ -z "$(find "$k/local" ! -type f ! -type d)" ] || die "links or special files among the project documents: nothing pushed"
  (cd "$k/local" && find . -type f -print0) | git -C "$proj" check-ignore -z --no-index --stdin | (cd "$k/local" && xargs -0 -r rm -f --)
  rc=0; (cd "$k/local" && find . -type f -print0) | git -C "$proj" check-ignore -z --no-index --stdin >/dev/null || rc=$?
  [ "$rc" = 1 ] || die "the private-file check failed (rc=$rc): nothing pushed"
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
grep -qx "/$l" "$root/.git/info/exclude" 2>/dev/null || echo "/$l" >> "$root/.git/info/exclude"
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
- Project documents under \`$local_dir/\` are edited as usual. Here that folder is \`.cloud-kit/local/\`: commit them by that path, \`.cloud-kit/local/…\`, or they never reach the computer. Only index.md, project.md, away-profile.md, docs/, roles/ and away/*.md travel back, as plain files whose names do not start with a dot.
- Never edit this file, \`.claude/settings.json\` or anything else under \`.cloud-kit/\`: the framework and the kit change on the computer only.
- An Away block closed here writes the same report as on the computer, every section included (the reviews too).
- Files the personal layer never versions (real data, family names) do not travel: if the index points to one that is missing here, work from \`docs/decisions.md\` and say what you could not check.
EOF
  python3 "$parts/settings.py" "$repo/.claude/settings.local.json" "$wt/.claude/settings.json" "$local_dir"
}

# The documents a cloud tip ($1) may carry back: regular files of the travelling set, with plain names. Anything else
# stops the land before a file is written. Prints one path per line, relative to the local folder.
cloud_docs() {
  tab="$(printf '\t')"
  git -c core.quotePath=false ls-tree -r "$1" -- .cloud-kit/local | while IFS= read -r line; do
    mode="${line%% *}"; f="${line#*"$tab"}"; f="${f#.cloud-kit/local/}"
    case "$mode" in 100644|100755) ;; *) die "the cloud's documents hold a link or something that is not a file ($f): nothing landed" ;; esac
    case "$f" in \"*|.*|*/.*) die "unusual file name among the cloud's documents ($f): nothing landed" ;; esac
    case "$f" in away/*/*) die "not a project document ($f): nothing landed" ;; esac
    case "$f" in index.md|project.md|away-profile.md|docs/*|roles/*|away/*.md) echo "$f" ;; *) die "not a project document ($f): nothing landed" ;; esac
  done
}
