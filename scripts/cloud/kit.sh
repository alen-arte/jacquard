# Jacquard cloud bridge, sourced by cloud.sh: the kit branch that prepare writes, and what status says about it.
# What land takes back is in land.sh; the rule for both ways is in rule.sh.

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
  left_out "$all"
  # what reaches the cloud for the first time, named before it leaves (a first sync names everything)
  before=""; ! git rev-parse -q --verify "$ref" >/dev/null || before="$(git -c core.quotePath=false ls-tree -r --name-only "$ref" -- .cloud-kit/local | sed 's|^\.cloud-kit/local/||')"
  first="$(printf '%s\n' "$send" | if [ -n "$before" ]; then grep -vxF -e "$before"; else cat; fi || true)"
  [ -z "$first" ] || { echo "  first time in the cloud:"; printf '%s\n' "$first" | plain | capped; }
  printf '* -text -filter -ident !eol !working-tree-encoding\n' > "$k/.gitattributes"   # bytes as they are: no LFS, no line ends
  printf '%s\n' "$send" | while IFS= read -r f; do   # -P: a link stays a link, and the check below stops it
    [ -z "$f" ] || { mkdir -p "$k/local/$(dirname "$f")"; cp -P "$proj/$f" "$k/local/$f"; }
  done
  [ -z "$(find "$k/local" ! -type f ! -type d)" ] || die "links or special files among the project documents: nothing pushed"
  # a second check, on what was copied: nothing the personal layer ignores leaves
  (cd "$k/local" && find . -type f -print0) | git -C "$proj" check-ignore -z --no-index --stdin | (cd "$k/local" && xargs -0 rm -f --)
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
# then the session start's jobs, as on the computer (session-start.sh skips the ones a cloud session must not run)
exec sh "$HOME/.claude/jacquard/scripts/session-start.sh" "$l"
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
- Project documents under \`$local_dir/\` are edited as usual. Here that folder is \`.cloud-kit/local/\`: commit them by that path, \`.cloud-kit/local/…\`, or they never reach the computer. Everything in it travels back, new folders and binaries included, as plain files. A name with a part that starts with a dot, with a control character, a quote or a backslash, or ending in \`.cloud\`, stops the way back: never commit one there. Files the computer's personal layer ignores (Away HTML reports, captures, real data) files shaped like settings or keys, and \`migration-backup/\` (copies kept on the computer) are skipped on the way back: keep them out of commits. \`git rm\` deletes on the computer too (a move is a deletion plus a new file), within brakes the computer explains when it holds one back: never index.md, project.md, away-profile.md or roles/, never a file changed there, never many at once.
- Never edit this file, \`.claude/settings.json\` or anything else under \`.cloud-kit/\`: the framework and the kit change on the computer only.
- An Away block closed here writes the same report as on the computer, every section included (the reviews too).
- Files the personal layer never versions (real data, family names) do not travel: if the index points to one that is missing here, work from \`docs/decisions.md\` and say what you could not check.
EOF
  python3 "$parts/settings.py" "$repo/.claude/settings.local.json" "$wt/.claude/settings.json" "$local_dir"
}

# One line when the files that travel ($1) weigh more than max_local_mb: every cloud session clones the kit branch's
# whole history, which keeps every version of them.
local_size() {
  [ -n "$1" ] || return 0
  _b="$( (cd "$proj" && printf '%s\n' "$1" | tr '\n' '\0' | xargs -0 cat --) | wc -c | tr -d ' ')"
  [ "$_b" -le $((max_local_mb * 1048576)) ] || echo "  ⚠ $local_dir weighs $((_b / 1048576)) MB, over $max_local_mb MB: every cloud session clones all of it, with every earlier version"
}

# What a cloud session on the kit branch would miss, for status: the files of $local_dir that changed here after the
# sync point ($1), against the files that travel now ($2), sorted into what prepare sends, what it would refuse (new,
# not backed up yet), and what stays in the cloud only because this computer stopped sending it (counted, never
# named: it may be private now); then what never travels by rule ($3, travelling's output).
untravelled() {
  _t="$(mktemp -d)"
  git -c core.quotePath=false ls-tree -r "$1" -- .cloud-kit/local \
    | awk -F '\t' '{ split($1, a, " "); sub(/^\.cloud-kit\/local\//, "", $2); print a[3] " " $2 }' > "$_t/there"
  printf '%s\n' "$2" | grep . > "$_t/names" || true
  P="$proj_real/" awk '{ print ENVIRON["P"] $0 }' "$_t/names" | git hash-object --no-filters --stdin-paths \
    | paste -d ' ' - "$_t/names" > "$_t/here"   # raw bytes, as prepare stores them; absolute paths
  git -C "$proj" -c core.quotePath=false ls-files --others --exclude-standard -- . > "$_t/new"
  awk 'FILENAME == ARGV[1] { there[substr($0, index($0, " ") + 1)] = $1; next }
       FILENAME == ARGV[2] { fresh[$0] = 1; next }
       { p = substr($0, index($0, " ") + 1); if (p in fresh) print "new " p; else if (!(p in there) || there[p] != $1) print "send " p; delete there[p] }
       END { for (p in there) print "gone " p }' "$_t/there" "$_t/new" "$_t/here" | sort > "$_t/diff"
  : > "$_t/send"; : > "$_t/fresh"; : > "$_t/gone"; stale=0
  while IFS= read -r line; do
    f="${line#* }"
    case "$line" in
      "send "*) echo "$f" >> "$_t/send" ;;
      "new "*) echo "$f" >> "$_t/fresh" ;;
      "gone "*) if [ -e "$proj/$f" ]; then stale=$((stale + 1)); else echo "$f" >> "$_t/gone"; fi ;;   # excluded since, or deleted here
    esac
  done < "$_t/diff"
  # deleted here: prepare takes it out of the cloud's tip; one this computer never takes back is only counted
  taken_back < "$_t/gone" > "$_t/kept"; cat "$_t/kept" >> "$_t/send"
  stale=$((stale + $(grep -c . "$_t/gone" || true) - $(grep -c . "$_t/kept" || true)))
  [ ! -s "$_t/send" ] || { echo "  ⚠ $(grep -c . "$_t/send") file(s) of $local_dir changed here after the last prepare and did not travel to $out (cloud.sh prepare sends them):"; plain < "$_t/send" | capped; }
  [ ! -s "$_t/fresh" ] || { echo "  ⚠ $(grep -c . "$_t/fresh") new file(s) of $local_dir did not travel and are not backed up yet: back them up with personal-sync.sh or ignore them in the layer, then cloud.sh prepare:"; plain < "$_t/fresh" | capped; }
  [ "$stale" = 0 ] || echo "  ⚠ $stale file(s) are still in the cloud though this computer no longer sends them (ignored or excluded since): they stay in the kit branch's history until its cloud/ branches are deleted"
  rm -rf "$_t"
  _n="$(git -C "$proj" ls-files --cached --others --ignored --exclude-standard -- . | grep -c . || true)"
  [ "$_n" = 0 ] || echo "  · never in the cloud, by rule: $_n file(s) the personal layer ignores"
  left_out "$3"
}
