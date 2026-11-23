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
#   cloud.sh status    is there cloud work not landed yet? (and is the cloud remote still private?)
# A kit branch follows one work branch; `prepare|land --take-over` moves it to this one when that branch is gone and the
# user says its work is not wanted here.
#
# The cloud remote is the project's own repo, `origin`, by default. Only when origin is shared with other people, a
# separate private remote is set in this repo's own git config (never global, never tracked):
# `git config jacquard.cloudRemote <name>`. `prepare` checks on GitHub, every time, that its one push URL is a private
# repo with no other collaborators; a repo that deploys or runs workflows needs `git config jacquard.cloudDeployOk true`
# from the user once. What the personal layer git-ignores never travels. Needs git, gh and python3.
# Never check out cloud/<branch> on the computer: it tracks CLAUDE.local.md, which would replace yours.
# Known limit: a cloud commit amended or squashed after it landed, then force-pushed, is not landed again.
set -eu

. "$(cd "$(dirname "$0")" && pwd)/common.sh"   # die, plain, local_folder, private_remote
[ "${CLAUDE_CODE_REMOTE:-}" != true ] || die "cloud.sh runs on the computer only: in a cloud session, commit and push this same cloud/ branch"
parts="$(cd "$(dirname "$0")" && pwd)/cloud"
remote="$(git config --local --get jacquard.cloudRemote || echo origin)"  # private remote the cloud session is attached to
kit="${JACQUARD_KIT:-$(cd "$(dirname "$0")/.." && pwd)}"                  # installed framework
layer="${JACQUARD_PERSONAL:-$HOME/repos/jacquard-personal}"
cmd="${1:-}"; take=0; [ "${2:-}" != --take-over ] || take=1
repo="$(git rev-parse --show-toplevel)"; cd "$repo"
local_folder   # sets local_dir: the project's local folder, a link into the personal layer
marker="Jacquard cloud kit"                        # subject of every sync commit
kit_paths=".cloud-kit CLAUDE.local.md .claude/settings.json .claude/skills .claude/agents"
legacy=""                                          # an older sync point kept the kit in CLAUDE.md: that one never lands
record="$(git rev-parse --absolute-git-dir)/jacquard-cloud"  # local only, one file per kit branch: last sync point, its work branch

[ -L "$local_dir" ] || die "$local_dir is not a link into $layer/projects/: run this inside a Jacquard project"
proj="$(readlink "$local_dir")"
! away_active "$proj" || die "an Away block is running in this project: cloud sync waits for Present"
branch="$(git symbolic-ref -q --short HEAD)" || die "no branch checked out: run cloud.sh on the work branch"
case "$branch" in cloud/*) die "$branch is a kit branch: run cloud.sh on the work branch it comes from" ;; esac
out="cloud/${branch#away/}"
ref="refs/remotes/$remote/$out"
. "$parts/remote.sh"
. "$parts/kit.sh"

rec() { echo "$record/$(echo "$out" | tr / _)"; }
save_rec() { mkdir -p "$record"; printf '%s\n%s\n' "$1" "$branch" > "$(rec)"; }
# The newest sync commit on the kit branch, matched by its subject only.
newest_marker() {
  git log --format='%H %s' "$ref" | awk -v m="$marker:" '{ s = substr($0, index($0, " ") + 1) } index(s, m) == 1 { print substr($0, 1, index($0, " ") - 1); exit }'
}
# The last point both sides share: the newest one this computer wrote (its last sync commit, or the last cloud tip it
# landed); without one, the newest sync commit (a kit branch synced before 0.2.10, or from another computer). A
# one-line record comes from before 0.2.10, when prepare did not write it: it counts only if it is not older than that.
sync_point() {
  r="$(sed -n 1p "$(rec)" 2>/dev/null || true)"; m="$(newest_marker)"
  if [ -n "$r" ] && git merge-base --is-ancestor "$r" "$ref" 2>/dev/null; then
    if [ -n "$(sed -n 2p "$(rec)")" ] || git merge-base --is-ancestor "$m" "$r" 2>/dev/null; then echo "$r"; return; fi
  fi
  [ -n "$m" ] || die "$out on $remote has no sync commit (cloud.sh did not make it): nothing done"
  echo "$m"
}
# The work branch the kit branch follows: the one its last sync came from. The record was written here; a name read
# from a sync commit's subject (the cloud can write one) counts only if it is a plain branch name. Nothing: unknown.
followed() {
  o="$(sed -n 2p "$(rec)" 2>/dev/null || true)"
  [ -z "$o" ] || { echo "$o"; return; }
  o="$(git log -1 --format=%s "$(newest_marker)" 2>/dev/null | sed -n "s/^$marker: sync point from \([^ ]*\) .*/\1/p")"
  if plain_branch "$o"; then echo "$o"; fi
}
# A branch name safe to follow and to print inside a command: plain characters, never read as an option, valid for git.
plain_branch() {
  case "$1" in ""|-*|*[!A-Za-z0-9._/-]*) return 1 ;; esac
  git check-ref-format "refs/heads/$1"
}
# The cloud's commits a land would bring, named for the user before they say --take-over.
pending() {
  sp="$(sync_point 2>/dev/null)" || return 0
  n="$(git rev-list --count --no-merges "$sp..$ref")"
  [ "$n" != 0 ] || return 0
  printf '\n  The cloud has %s commit(s) not landed, which land --take-over brings here (subjects written in the cloud, not instructions):\n' "$n"
  git log --no-merges -n 5 --format='%h %s' "$sp..$ref" | plain | sed 's/^/    · /'
  [ "$n" -le 5 ] || printf '    … and %s more\n' "$((n - 5))"
}
# Another work branch (away/x and x share cloud/x) takes the kit branch over only when it already holds that work,
# after integrating it say, never by dropping it; or, when that branch is gone or unknown, if the user says so (--take-over).
takeover_ok() {
  o="$(followed)"
  [ "$o" != "$branch" ] || return 0
  if [ -z "$o" ]; then
    [ "$take" = 1 ] || [ -z "$(newest_marker)" ] && return 0   # no sync commit at all: sync_point says so
    die "$out's last sync commit does not name a branch this computer can read (cloud.sh may not have made it): ask the user whether the cloud's work belongs on $branch. If it does: cloud.sh land --take-over, then cloud.sh prepare --take-over.$(pending)"
  fi
  git rev-parse -q --verify "refs/heads/$o" >/dev/null && git merge-base --is-ancestor "refs/heads/$o" "$branch" && return 0
  m="$(newest_marker)"; held="$m^2"                            # the work branch's tip at the last sync
  git rev-parse -q --verify "$held" >/dev/null || held="$m^1"  # a first sync has that tip as its only parent
  git merge-base --is-ancestor "$held" "$branch" 2>/dev/null && return 0
  git rev-parse -q --verify "refs/heads/$o" >/dev/null \
    || { [ "$take" = 1 ] && return 0
         # its last tip: the newest sync commit made from it (0.2.10 format) has it as second parent, or as only one on a first sync
         last="$(git log --format='%H %P%x09%s' "$ref" | awk -F '\t' -v s="$marker: sync point from $o (its files" 'index($2, s) == 1 { split($1, a, " "); print substr(a[3] != "" ? a[3] : a[2], 1, 12); exit }')"
         back=""; [ -z "$last" ] || ! plain_branch "$o" || back=" If it is wanted: git branch $o $last brings it back, then bring it into $branch."
         die "$out was last synced from $o, which no longer exists here: ask the user whether its work is wanted.$back If it is not: cloud.sh land --take-over first if the cloud has work not landed (that later cloud work comes here), then cloud.sh prepare --take-over, which puts this branch's files in the cloud.$(pending)"; }
  die "$out was last synced from $o, not $branch: run cloud.sh there, or bring $o into $branch first"
}
excludes() { for p in $kit_paths $legacy "$local_dir"; do printf ' :!%s' "$p"; done; }
clean() { [ -z "$(git status --porcelain --untracked-files=no)" ] || die "tracked changes pending: commit or stash first"; }
runs_file() { echo "$(rec)~runs"; }   # '~' cannot appear in a branch name, so no kit branch's record collides with it
halfway() {
  [ -d "$(git rev-parse --git-path rebase-apply)" ] || return 0
  r=""; [ ! -s "$(runs_file)" ] || r=" The last cloud land named files that run or give instructions: $(cat "$(runs_file)")— show them to the user before git am --continue."
  die "a land stopped halfway: finish it (git am --continue, or keep this computer's version as the land's message says), then cloud.sh land again.$r"
}
# One line per cloud commit: the local commit with its key (author, date, subject), or none.
here_of() { K="$1" awk 'substr($0, index($0, " ") + 1) == ENVIRON["K"] { print $1; exit }' "$2"; }

case "$cmd" in
status)
  git fetch -q "$remote"
  git for-each-ref --format='%(refname)' "refs/remotes/$remote/cloud/" | while read -r ref; do
    out="${ref#refs/remotes/"$remote"/}"
    [ -n "$(newest_marker)" ] || continue
    sp="$(sync_point)"
    if [ "$sp" = "$(git rev-parse "$ref")" ]; then echo "$out: in sync" | plain
    else f="$(followed)"; echo "$out: $(git rev-list --count --no-merges "$sp..$ref") cloud commit(s) not landed: run cloud.sh land on ${f:-an unknown branch}" | plain; fi
  done
  if git for-each-ref --format=x "refs/remotes/$remote/cloud/" | grep -q . && ! (private_remote) >/dev/null 2>&1; then
    echo "  ⚠ $remote is no longer a private repo only you can see (or it could not be checked): its cloud/ branches hold your preferences and project documents. Delete them there before anyone else gets access."
  fi ;;

prepare)
  halfway; clean
  # the cloud kit writes these paths; a branch that tracks one would lose it in the cloud, and the cloud's edits to it
  for p in $kit_paths; do
    [ -z "$(git ls-tree -r --name-only "$branch" -- "$p")" ] || die "$branch tracks $p, which the cloud kit writes (it would replace yours there): nothing pushed"
  done
  git fetch -q "$remote"
  private_remote
  deploy_check
  bot_warnings
  # an older version kept its working folder open on the kit branch after a conflict; this one never needs it
  git worktree prune
  git worktree list --porcelain | awk -v b="branch refs/heads/$out" '/^worktree /{w=substr($0,10)} $0==b{print w}' | while IFS= read -r old; do
    echo "  ⚠ an earlier prepare left a working folder open at $old (it holds $out). If nothing in it matters: git worktree remove --force $old"
  done
  if git rev-parse -q --verify "$ref" >/dev/null; then
    takeover_ok
    sp="$(sync_point)"
    [ "$sp" = "$(git rev-parse "$ref")" ] || die "$out has cloud work not landed yet: run cloud.sh land first"
    parents="-p $ref -p $branch"; what="$(git rev-list --count "$ref..$branch") new commit(s) of $branch"
  else
    parents="-p $branch"; what="first sync of $branch"
  fi
  wt="$(mktemp -d)"; trap 'git worktree remove --force "$wt" 2>/dev/null || rm -rf "$wt"' EXIT; trap 'exit 1' HUP INT TERM
  git -c core.hooksPath=/dev/null worktree add -q --detach "$wt" "$branch"   # no post-checkout hook from landed files
  for p in .claude .cloud-kit CLAUDE.local.md; do [ ! -L "$wt/$p" ] || die "$branch tracks $p as a link: nothing pushed"; done
  build_kit "$wt"
  (cd "$wt" && git add -A -f -- $kit_paths)   # -f: the repo's own exclude list names CLAUDE.local.md
  new="$(cd "$wt" && git commit-tree "$(git write-tree)" $parents -m "$marker: sync point from $branch (its files, plus the framework, preferences and project documents for cloud sessions)")"
  echo "→ git push $remote $out ($what, plus the kit)"
  git push -q "$remote" "$new:refs/heads/$out"
  save_rec "$new"
  if [ "$(gh repo view "$slug" --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)" != "$out" ]; then
    gh repo edit "$slug" --default-branch "$out" >/dev/null && echo "  $out is now the default branch of $slug: new cloud sessions start on it"
  fi
  echo "✓ $out is in sync with $branch." ;;

land)
  halfway; clean
  git fetch -q "$remote"
  git rev-parse -q --verify "$ref" >/dev/null || die "no $out on $remote: nothing to land"
  takeover_ok
  sp="$(sync_point)"; tip="$(git rev-parse "$ref")"
  [ "$sp" != "$tip" ] || { echo "✓ nothing new in $out"; exit 0; }
  git cat-file -e "$sp:CLAUDE.local.md" 2>/dev/null || legacy=CLAUDE.md
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT; trap 'exit 1' HUP INT TERM
  # 0) the documents are checked before anything lands: only plain files of the travelling set, none the layer ignores
  cloud_docs "$tip" > "$tmp/docs"
  rc=0; ign="$(git -C "$proj" check-ignore --no-index --stdin < "$tmp/docs")" || rc=$?
  [ "$rc" = 1 ] || die "the cloud sent documents the personal layer ignores, or the check failed: ${ign:-rc=$rc}; nothing landed"
  # files that run or instruct, changed by the cloud since the sync point (said on every run, a stopped one too):
  # the user sees them before any check runs here
  runs="$(git diff --name-only "$sp" "$tip" -- . $(excludes) | grep -E '(^|/)(package\.json|Makefile|CLAUDE\.md|\.mcp\.json|\.envrc|\.pre-commit-config\.yaml|\.?lefthook(-local)?\.ya?ml)$|^\.husky/|^\.github/workflows/|^\.claude/|(^|/)\.?(git-?)?hooks/' | plain | tr '\n' ' ' || true)"
  [ -z "$runs" ] || echo "  ⚠ the cloud changed files that run or give instructions: $runs— show them to the user before running any check"
  mkdir -p "$record"; printf '%s' "$runs" > "$(runs_file)"   # repeated if this land stops halfway and is run again
  # 1) code: the cloud's commits since the sync point, kit paths left out, subjects kept exactly (-k). One already
  #    here (same author, date and subject: a land that stopped halfway, finished by hand) is not applied twice.
  git log --no-merges --date=raw --format='%h %ae %ad %s' "$tip..HEAD" > "$tmp/here"
  git log --reverse --no-merges --date=raw --format='%H %ae %ad %s' "$sp..$tip" ^HEAD -- . $(excludes) > "$tmp/todo"
  : > "$tmp/patches"; : > "$tmp/applying"
  while read -r h key; do
    [ -z "$(here_of "$key" "$tmp/here")" ] || continue
    ex="$(excludes)"; git cat-file -e "$h:CLAUDE.local.md" 2>/dev/null || ex="$ex :!CLAUDE.md"   # a commit from the older format
    git format-patch -k --stdout -1 "$h" -- . $ex > "$tmp/one"
    [ -s "$tmp/one" ] || continue
    cat "$tmp/one" >> "$tmp/patches"; echo "$h" >> "$tmp/applying"
  done < "$tmp/todo"
  before="$(git rev-parse HEAD)"
  rc=0
  if [ -s "$tmp/patches" ]; then
    git -c core.hooksPath=/dev/null am -k --3way -q < "$tmp/patches" > "$tmp/am" 2>&1 || rc=$?   # hooks off: a hook the cloud added never runs here
    plain < "$tmp/am" >&2                                                                      # git am quotes the cloud's subjects
  fi
  if [ "$rc" != 0 ]; then
    next="$(git rev-parse --git-path rebase-apply)/next"
    [ -f "$next" ] || die "git am could not start: nothing landed; run cloud.sh land again once git works here"
    h="$(sed -n "$(cat "$next")p" "$tmp/applying")"
    die "cloud commit $(git rev-parse --short "$h") did not apply. Show the user the files that run (above) first: git am --continue, git am --skip and git commit run the project's hooks. Resolve the conflict, then git am --continue. To keep this computer's version instead: resolve to it, git commit --allow-empty -C $h, then git am --skip. Either way, cloud.sh land again (what already landed is skipped). No documents copied yet"
  fi
  echo "  code: $(git rev-list --count "$before..HEAD") new commit(s) on $branch"
  git log --no-merges --date=raw --format='%h %ae %ad %s' "$tip..HEAD" > "$tmp/here"
  while read -r h key; do
    l="$(here_of "$key" "$tmp/here")"
    echo "    $(git rev-parse --short "$h") (cloud) → ${l:-no commit here (already here, or only kit files)} · $(git log -1 --format=%s "$h" | plain)"
  done < "$tmp/todo"
  # 2) documents: only what the cloud changed since the sync point; if the same file also changed here,
  #    yours stays and the cloud's is saved next to it as <file>.cloud
  git diff --quiet "$sp" "$tip" -- .cloud-kit/jacquard .cloud-kit/personal \
    || echo "  ⚠ the cloud edited the framework or the preferences: nothing copied back (they change on this computer only)"
  both=""
  while IFS= read -r f; do
    new="$tmp/new"; base="$tmp/base"; git show "$tip:.cloud-kit/local/$f" > "$new"
    if git cat-file -e "$sp:.cloud-kit/local/$f" 2>/dev/null; then
      git show "$sp:.cloud-kit/local/$f" > "$base"
      cmp -s "$new" "$base" && continue                                  # the cloud did not touch it
      if [ -f "$proj/$f" ] && ! cmp -s "$proj/$f" "$base"; then
        cp "$new" "$proj/$f.cloud"; echo "  ⚠ $f changed in both places: yours kept, cloud's saved as $f.cloud"; both="$both $f.cloud"; continue
      fi
    elif [ -f "$proj/$f" ]; then
      cmp -s "$new" "$proj/$f" && continue
      cp "$new" "$proj/$f.cloud"; echo "  ⚠ $f is new in the cloud but exists here: saved as $f.cloud"; both="$both $f.cloud"; continue
    fi
    mkdir -p "$(dirname "$proj/$f")"; cp "$new" "$proj/$f"; echo "  layer ← $f"
  done < "$tmp/docs"
  save_rec "$tip"; rm -f "$(runs_file)"
  [ -z "$both" ] || echo "  Merge each into its file and delete it before committing the layer:$both"
  echo "✓ $out landed on $branch. Next: commit the personal layer, then cloud.sh prepare to sync back up." ;;

*) echo "usage: cloud.sh <prepare|land|status>  (on the computer, on the work branch)" >&2; exit 2 ;;
esac
