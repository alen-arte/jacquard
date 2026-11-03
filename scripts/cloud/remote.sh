# Jacquard cloud bridge, sourced by cloud.sh: where the kit may go. It goes to one private GitHub repo that nobody
# else can see, and never starts what the repo runs on its own without the user's say. Fail closed throughout.

# The one push URL of the cloud remote must be a plain GitHub address of a private repo with no other collaborators.
# Sets slug (owner/repo).
private_remote() {
  command -v gh >/dev/null || die "gh is missing: cannot check $remote is private, nothing pushed"
  urls="$(git remote get-url --push --all "$remote")"
  [ "$(printf '%s\n' "$urls" | grep -c .)" = 1 ] || die "$remote pushes to several URLs: the kit goes to one private repo only, nothing pushed"
  slug="$(printf '%s\n' "$urls" | sed -nE 's#^(https://github\.com/|git@github\.com:|ssh://git@github\.com/)([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)$#\2#p')"
  slug="${slug%.git}"
  [ -n "$slug" ] || die "$remote pushes to $(printf '%s\n' "$urls" | sed -E 's#//[^/@]*@#//#'), which is not a plain GitHub address: cannot check it is private, nothing pushed"
  [ "$(gh repo view "$slug" --json visibility -q .visibility 2>/dev/null)" = PRIVATE ] \
    || die "$slug is not private (or could not be checked): nothing pushed"
  [ "$(gh api "repos/$slug/collaborators" --jq length 2>/dev/null)" = 1 ] \
    || die "$slug has other collaborators (or could not be checked): the kit only goes to a repo only you can see; nothing pushed"
}

# A push of the kit branch, or making it the default branch, can start what the repo runs on its own: workflows
# (scheduled ones run on the default branch), deploy previews, webhooks. The user says yes in git config, to exactly the
# list found: when something new appears, it asks again. A deploy app with no file and no deployment yet is not seen.
deploy_check() {
  s=""
  [ -z "$(git ls-tree --name-only "$branch" -- .github/workflows/)" ] || s="$s workflows,"
  for f in vercel.json netlify.toml; do git cat-file -e "$branch:$f" 2>/dev/null && s="$s $f,"; done
  n="$(gh api "repos/$slug/environments" --jq .total_count 2>/dev/null || echo unknown)"; [ "$n" = 0 ] || s="$s deployment environments,"
  n="$(gh api "repos/$slug/hooks" --jq length 2>/dev/null || echo unknown)"; [ "$n" = 0 ] || s="$s webhooks,"
  s="${s# }"; s="${s%,}"
  [ -n "$s" ] || return 0
  [ "$(git config --local --get jacquard.cloudDeployOk || true)" = "$s" ] && return 0
  die "$slug can run things on its own when $out is pushed or becomes its default branch ($s). A separate private repo for the kit avoids it (git config jacquard.cloudRemote <name>); to go ahead with this one, the user runs: git config jacquard.cloudDeployOk \"$s\". Nothing pushed"
}

# Bots open their PRs against the default branch unless told otherwise.
bot_warnings() {
  if git cat-file -e "$branch:.github/dependabot.yml" 2>/dev/null && ! git show "$branch:.github/dependabot.yml" | grep -q 'target-branch:'; then
    echo "  ⚠ .github/dependabot.yml has no target-branch: once $out is the default branch, Dependabot opens its PRs there. Add 'target-branch: main' to each update."
  fi
  for f in renovate.json renovate.json5 .renovaterc .renovaterc.json .github/renovate.json .github/renovate.json5; do
    if git cat-file -e "$branch:$f" 2>/dev/null && ! git show "$branch:$f" | grep -q 'baseBranches'; then
      echo "  ⚠ $f has no baseBranches: once $out is the default branch, Renovate opens its PRs there. Add \"baseBranches\": [\"main\"]."
    fi
  done
}
