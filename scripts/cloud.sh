#!/bin/sh
# Jacquard cloud bridge (core git.md › Cloud sync): lets a Claude Code cloud session use the framework, and keeps both
# sides in sync. The cloud clones only the repo it is attached to, so the kit travels inside it, on one stable branch per
# work branch: cloud/<branch> = the work branch's files + the kit. Work branches never carry the kit.
# Every `prepare` ends with one sync commit: the work branch's files plus a fresh kit, on top of the cloud's tip. It never
# merges, so it cannot conflict; it refuses while the cloud has work not landed. Whatever comes after it was done in the cloud.
#
# Usage (on the computer, inside the project repo, on the work branch):
#   cloud.sh prepare   sync up: write cloud/<branch> from this branch plus the kit, push it, make it the default branch
#   cloud.sh land      sync down: copy the cloud's new commits here (kit paths left out), copy its documents back
#   cloud.sh status    is there cloud work not landed yet?
#
# The cloud remote is the project's own repo, `origin`, by default. Only when origin is shared with other people, a
# separate private remote is set in this repo's own git config (never global, never tracked):
# `git config jacquard.cloudRemote <name>`. `prepare` checks on GitHub that it is private and only the user's, every time.
# What the personal layer git-ignores never travels. Needs git, gh and python3.
set -eu

[ "${CLAUDE_CODE_REMOTE:-}" != true ] || { echo "✗ cloud.sh runs on the computer only: in a cloud session, commit and push this same cloud/ branch" >&2; exit 1; }
remote="$(git config --local --get jacquard.cloudRemote || echo origin)"  # private remote the cloud session is attached to
kit="${JACQUARD_KIT:-$(cd "$(dirname "$0")/.." && pwd)}"                  # installed framework
layer="${JACQUARD_PERSONAL:-$HOME/repos/jacquard-personal}"
cmd="${1:-}"
repo="$(git rev-parse --show-toplevel)"; cd "$repo"
# the project's local folder: the one whose index.md CLAUDE.local.md imports (a link into the personal layer)
local_dir="$(sed -n 's#^@\([^~/][^ ]*\)/index\.md$#\1#p' CLAUDE.local.md 2>/dev/null | head -n 1)"; local_dir="${local_dir:-.jacquard}"
marker="Jacquard cloud kit"                        # subject of every sync commit
kit_paths=".cloud-kit CLAUDE.local.md .claude/settings.json .claude/skills .claude/agents"
legacy=""                                          # an older sync point kept the kit in CLAUDE.md: that one never lands
record="$(git rev-parse --absolute-git-dir)/jacquard-cloud"  # local only: the cloud tips already landed, one file per branch

[ -L "$local_dir" ] || { echo "✗ $local_dir is not a link into $layer/projects/: run this inside a Jacquard project" >&2; exit 1; }
proj="$(readlink "$local_dir")"
branch="$(git symbolic-ref --short HEAD)"
case "$branch" in cloud/*) echo "✗ $branch is a kit branch: run cloud.sh on the work branch it comes from" >&2; exit 1 ;; esac
out="cloud/${branch#away/}"
ref="refs/remotes/$remote/$out"

rec() { echo "$record/$(echo "$out" | tr / _)"; }
# The last point both sides share: the newest sync commit, or a later cloud tip already landed here.
sync_point() {
  m="$(git log --format=%H --grep="^$marker" -n1 "$ref")"
  [ -n "$m" ] || { echo "✗ $out on $remote has no sync commit (cloud.sh did not make it): nothing done" >&2; exit 1; }
  r="$(cat "$(rec)" 2>/dev/null || true)"
  if [ -n "$r" ] && git merge-base --is-ancestor "$m" "$r" 2>/dev/null && git merge-base --is-ancestor "$r" "$ref"; then echo "$r"; else echo "$m"; fi
}
excludes() { for p in $kit_paths $legacy; do printf ' :!%s' "$p"; done; }
# The kit (framework, preferences, project documents, permissions) only goes to a private repo nobody else can see; fail closed.
private_remote() {
  url="$(git remote get-url "$remote")"
  case "$url" in *github.com*) ;; *) echo "✗ $remote is not on GitHub: cannot check it is private, nothing pushed" >&2; exit 1 ;; esac
  command -v gh >/dev/null || { echo "✗ gh is missing: cannot check $remote is private, nothing pushed" >&2; exit 1; }
  slug="$(echo "$url" | sed -E 's#^.*github\.com[:/]##; s#\.git$##')"
  [ "$(gh repo view "$slug" --json visibility -q .visibility 2>/dev/null)" = PRIVATE ] \
    || { echo "✗ $slug is not private (or could not be checked): nothing pushed" >&2; exit 1; }
  [ "$(gh api "repos/$slug/collaborators" --jq length 2>/dev/null)" = 1 ] \
    || { echo "✗ $slug has other collaborators (or could not be checked): the kit only goes to a repo only you can see; nothing pushed" >&2; exit 1; }
}
clean() { [ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "✗ tracked changes pending: commit or stash first" >&2; exit 1; }; }
halfway() {
  [ ! -d "$(git rev-parse --git-path rebase-apply)" ] \
    || { echo "✗ a land stopped halfway: resolve the conflict and run git am --continue (git am --abort undoes it), then cloud.sh land again" >&2; exit 1; }
}

case "$cmd" in
status)
  git fetch -q "$remote"
  git for-each-ref --format='%(refname)' "refs/remotes/$remote/" | while read -r ref; do
    case "$ref" in */HEAD) continue ;; esac
    git log --format=%H --grep="^$marker" -n1 "$ref" | grep -q . || continue
    out="${ref#refs/remotes/"$remote"/}"
    n="$(git rev-list --count --no-merges "$(sync_point)..$ref")"
    [ "$n" = 0 ] && echo "$out: in sync" || echo "$out: $n cloud commit(s) not landed: run cloud.sh land on the matching work branch"
  done ;;

prepare)
  halfway; clean
  # the cloud kit writes these paths; a branch that tracks one would lose it in the cloud, and the cloud's edits to it
  for p in $kit_paths; do
    [ -z "$(git ls-tree -r --name-only "$branch" -- "$p")" ] \
      || { echo "✗ $branch tracks $p, which the cloud kit writes (it would replace yours there): nothing pushed" >&2; exit 1; }
  done
  git fetch -q "$remote"
  private_remote
  # the kit branch becomes the default one, and Dependabot opens its PRs against the default branch unless told otherwise
  if git cat-file -e "$branch:.github/dependabot.yml" 2>/dev/null && ! git show "$branch:.github/dependabot.yml" | grep -q 'target-branch:'; then
    echo "  ⚠ .github/dependabot.yml has no target-branch: once $out is the default branch, Dependabot opens its PRs there. Add 'target-branch: main' to each update."
  fi
  # an older version kept its working folder open on the kit branch after a conflict; this one never needs it
  git worktree prune
  git worktree list --porcelain | awk -v b="branch refs/heads/$out" '/^worktree /{w=substr($0,10)} $0==b{print w}' | while IFS= read -r old; do
    echo "  ⚠ an earlier prepare left a working folder open at $old (it holds $out). If nothing in it matters: git worktree remove --force $old"
  done
  if git rev-parse -q --verify "$ref" >/dev/null; then
    sp="$(sync_point)"
    [ "$sp" = "$(git rev-parse "$ref")" ] || { echo "✗ $out has cloud work not landed yet: run cloud.sh land first" >&2; exit 1; }
    parents="-p $ref -p $branch"; ahead="$(git rev-list --count "$ref..$branch")"
  else
    parents="-p $branch"; ahead="$(git rev-list --count "$branch")"
  fi
  wt="$(mktemp -d)"; trap 'git worktree remove --force "$wt" 2>/dev/null || rm -rf "$wt"' EXIT; trap 'exit 1' HUP INT TERM
  git worktree add -q --detach "$wt" "$branch"
  # the kit, rebuilt from scratch every time (so files deleted here disappear there too)
  k="$wt/.cloud-kit"
  mkdir -p "$k/jacquard" "$k/personal" "$k/local/away" "$wt/.claude/skills" "$wt/.claude/agents"
  for d in core roles scripts skills agents; do cp -R "$kit/$d" "$k/jacquard/$d"; done   # no tests, docs or templates
  cp "$kit/CHANGELOG.md" "$k/jacquard/"
  cp "$layer/preferences.md" "$k/personal/"
  # project documents travel only if the personal layer versions them: what it ignores (real data, family names)
  # never travels, and what it does not know yet might be private, so it stops the sync. Fail closed throughout.
  [ "$(git -C "$proj" rev-parse --show-toplevel 2>/dev/null)" = "$(cd "$layer" && pwd -P)" ] \
    || { echo "✗ $layer is not its own git repo: cannot tell private files apart, nothing pushed" >&2; exit 1; }
  new="$(git -C "$proj" ls-files --others --exclude-standard -- index.md project.md away-profile.md docs roles 'away/*.md')"
  [ -z "$new" ] || { printf '✗ the personal layer does not version these yet (commit or ignore them first), nothing pushed:\n%s\n' "$new" >&2; exit 1; }
  for f in index.md project.md away-profile.md; do cp "$proj/$f" "$k/local/"; done        # documents only: no QA captures, backups or diffs
  cp -R "$proj/docs" "$proj/roles" "$k/local/"
  cp "$proj"/away/*.md "$k/local/away/" 2>/dev/null || true
  [ -z "$(find "$k/local" ! -type f ! -type d)" ] || { echo "✗ links or special files among the project documents: nothing pushed" >&2; exit 1; }
  (cd "$k/local" && find . -type f -print0) | git -C "$proj" check-ignore -z --no-index --stdin | (cd "$k/local" && xargs -0 -r rm -f --)
  rc=0; (cd "$k/local" && find . -type f -print0) | git -C "$proj" check-ignore -z --no-index --stdin >/dev/null || rc=$?
  [ "$rc" = 1 ] || { echo "✗ the private-file check failed (rc=$rc): nothing pushed" >&2; exit 1; }
  cp -R "$kit"/skills/. "$wt/.claude/skills/"; cp "$kit"/agents/*.md "$wt/.claude/agents/"  # where Claude Code looks in a project
  printf '%s\n' "$local_dir" > "$k/local-folder"
  cat > "$k/bootstrap.sh" <<'EOF'
#!/bin/sh
# Cloud sessions only: make the kit appear where the framework's own paths expect it.
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
root="${CLAUDE_PROJECT_DIR:-$PWD}"
l="$(cat "$root/.cloud-kit/local-folder")"
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
- Here \`origin\` is the user's private repo (the remote called \`$remote\` on their computer). Commit to this same branch, \`$out\`, and push it when the work is closed (core git.md › Cloud sync): that is how it reaches the computer.
- The computer's permissions travel in \`.claude/settings.json\` (same denials and confirmations, plus the Away guard), so the same commands are blocked or asked here. The local pre-commit guard does not exist here: never commit on \`main\` and never add \`$local_dir\`.
- Never edit this file, \`.cloud-kit/jacquard/\` or \`.cloud-kit/personal/\`: the framework changes on the computer only. Project documents under \`$local_dir/\` are edited as usual.
- An Away block closed here writes the same report as on the computer, every section included (the reviews too).
- Files the personal layer never versions (real data, family names) do not travel: if the index points to one that is missing here, work from \`docs/decisions.md\` and say what you could not check.
EOF
  python3 "$kit/scripts/cloud/settings.py" "$repo/.claude/settings.local.json" "$wt/.claude/settings.json" "$local_dir"
  (cd "$wt" && git add -A -f -- $kit_paths)   # -f: the repo's own exclude list names CLAUDE.local.md
  new="$(cd "$wt" && git commit-tree "$(git write-tree)" $parents -m "$marker: sync point from $branch (its files, plus the framework, preferences and project documents for cloud sessions)")"
  echo "→ git push $remote $out ($ahead commit(s) of $branch, plus the kit)"
  git push -q "$remote" "$new:refs/heads/$out"
  mkdir -p "$record"; echo "$new" > "$(rec)"
  if [ "$(gh repo view "$slug" --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)" != "$out" ]; then
    gh repo edit "$slug" --default-branch "$out" >/dev/null && echo "  $out is now the default branch of $slug: new cloud sessions start on it"
  fi
  echo "✓ $out is in sync with $branch." ;;

land)
  halfway; clean
  git fetch -q "$remote"
  git rev-parse -q --verify "$ref" >/dev/null || { echo "✗ no $out on $remote: nothing to land" >&2; exit 1; }
  sp="$(sync_point)"; tip="$(git rev-parse "$ref")"
  [ "$sp" != "$tip" ] || { echo "✓ nothing new in $out"; exit 0; }
  git cat-file -e "$sp:CLAUDE.local.md" 2>/dev/null || legacy=CLAUDE.md
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT; trap 'exit 1' HUP INT TERM
  # 1) code first (nothing is copied if it fails): the cloud's commits since the sync point, kit paths left out.
  #    One already here (same author, date and subject: a land that stopped halfway, finished by hand) is not applied twice.
  git log --no-merges --date=raw --format='%ae %ad %s' "$tip..HEAD" > "$tmp/here"
  git log --reverse --no-merges --date=raw --format='%H %ae %ad %s' "$sp..$tip" -- . $(excludes) > "$tmp/todo"
  : > "$tmp/patches"; : > "$tmp/cloud"
  while read -r h key; do
    grep -Fxq -- "$key" "$tmp/here" && continue
    git format-patch --stdout -1 "$h" -- . $(excludes) >> "$tmp/patches"; echo "$h" >> "$tmp/cloud"
  done < "$tmp/todo"
  before="$(git rev-parse HEAD)"
  if [ -s "$tmp/patches" ]; then
    git am --3way -q < "$tmp/patches" \
      || { echo "✗ a cloud commit did not apply: resolve the conflict and run git am --continue (git am --abort undoes this land), then cloud.sh land again; what is already here is skipped. No documents copied yet" >&2; exit 1; }
  fi
  echo "  code: $(grep -c . "$tmp/cloud" || true) cloud commit(s) applied to $branch"
  git rev-list --reverse "$before..HEAD" > "$tmp/landed"
  paste -d ' ' "$tmp/cloud" "$tmp/landed" | while read -r c h; do
    echo "    $(git rev-parse --short "$c") (cloud) → $(git rev-parse --short "$h") (here) $(git log -1 --format=%s "$h")"
  done
  # 2) documents: only what the cloud changed since the sync point; if the same file also changed here,
  #    yours stays and the cloud's is saved next to it as <file>.cloud
  mkdir -p "$tmp/new"; git archive "$tip" .cloud-kit | tar -x -C "$tmp/new"
  diff -rq "$kit/core" "$tmp/new/.cloud-kit/jacquard/core" >/dev/null 2>&1 || echo "  ⚠ the cloud edited the framework core: nothing copied back (it changes on this computer only)"
  (cd "$tmp/new/.cloud-kit/local" && find . -type f | sed "s|^\./||") | while IFS= read -r f; do
    new="$tmp/new/.cloud-kit/local/$f"; base="$tmp/base"
    if git cat-file -e "$sp:.cloud-kit/local/$f" 2>/dev/null; then
      git show "$sp:.cloud-kit/local/$f" > "$base"
      cmp -s "$new" "$base" && continue                                  # the cloud did not touch it
      if [ -f "$proj/$f" ] && ! cmp -s "$proj/$f" "$base"; then
        cp "$new" "$proj/$f.cloud"; echo "  ⚠ $f changed in both places: yours kept, cloud's saved as $f.cloud"; continue
      fi
    elif [ -f "$proj/$f" ]; then
      cmp -s "$new" "$proj/$f" && continue
      cp "$new" "$proj/$f.cloud"; echo "  ⚠ $f is new in the cloud but exists here: saved as $f.cloud"; continue
    fi
    mkdir -p "$(dirname "$proj/$f")"; cp "$new" "$proj/$f"; echo "  layer ← $f"
  done
  mkdir -p "$record"; echo "$tip" > "$(rec)"
  echo "✓ $out landed on $branch. Next: commit the personal layer, then cloud.sh prepare to sync back up." ;;

*) echo "usage: cloud.sh <prepare|land|status>  (on the computer, on the work branch)" >&2; exit 2 ;;
esac
