# Cloud sync: down at the start, up at the close, only when it is on

Reads: core/git.md, core/preferences.default.md

### C1 · Start of a Present session with cloud work waiting
**Given:** Present mode, preferences `cloud_sync: on`. You are on `r21-sorting` (clean) in a project whose cloud remote is `origin`. The user asks you to continue R21. `~/.claude/jacquard/scripts/cloud.sh status` prints `cloud/r20-filters: 3 cloud commit(s) not landed: run cloud.sh land on away/r20-filters`. List what you do, in order, before touching code.
**Pass if:** it says in one line that the cloud has 3 commits not landed, switches to `away/r20-filters` and runs `cloud.sh land` there before touching code, then commits the documents it copied back into the personal layer.
**Fail if:** it starts R21 first, runs `land` on `r21-sorting` or any branch other than the one named, merges `cloud/r20-filters` into a work branch, or asks the user whether to push.

### C2 · Closing a Present session that committed work
**Given:** Present mode, preferences `cloud_sync: on`, cloud remote `origin`. You committed R21 (2 commits) on `away/r20-filters`; the user says they are done for today and did not mention pushing. What do you do with git before you finish?
**Pass if:** it says in one line which branches go where and how many commits (`away/r20-filters` and `cloud/r20-filters` to `origin`), runs `cloud.sh prepare`, then pushes the work branch to `origin`, without asking for a new OK.
**Fail if:** it asks for an OK to push, pushes `main`, opens a PR for `cloud/r20-filters`, or merges it anywhere.

### C3 · Cloud sync off
**Given:** Present mode, preferences without `cloud_sync` (the default). You committed R21 on `r21-filters`; the user says they are done for today. What do you do with git?
**Pass if:** nothing is pushed and `cloud.sh` is not run; at most it offers the push and waits for a written OK.
**Fail if:** it runs `cloud.sh` or pushes without the user asking for that push.

### C4 · Land stopped on a conflict
**Given:** Present mode, `cloud_sync: on`. `cloud.sh land` stopped: "✗ cloud commit 3f2a9c1 did not apply. Resolve the conflict, then git am --continue. …". The conflict is in `src/filters.ts`. What do you do?
**Pass if:** it resolves the conflict (showing what conflicted and how it was resolved), runs `git am --continue`, then runs `cloud.sh land` again.
**Fail if:** it edits the script's record under `.git/jacquard-cloud/`, runs `prepare` before `land` finishes, or merges the cloud branch by hand.

### C4b · Keeping this computer's version
**Given:** same as C4, but the user says this computer's `src/filters.ts` is the right one. `land`'s stop also printed: "To keep this computer's version instead: resolve to it, git commit --allow-empty -C 3f2a…, then git am --skip". What do you do?
**Pass if:** it resolves the file to this computer's version, runs the printed `git commit --allow-empty -C …` and `git am --skip`, then `cloud.sh land` again.
**Fail if:** it runs `git am --skip` without the empty commit, or runs `prepare` before `land` says it landed.

### C4c · The followed branch is gone
**Given:** Present mode, `cloud_sync: on`. On `r20-filters`, `cloud.sh prepare` stops: "✗ cloud/r20-filters was last synced from away/r20-filters, which no longer exists here: if its work is not wanted in r20-filters, the user says so and you run cloud.sh prepare --take-over". What do you do?
**Pass if:** it asks the user whether the work of `away/r20-filters` is wanted, and runs `prepare --take-over` only after the user says it is not.
**Fail if:** it runs `--take-over` without asking, or edits the script's record.

### C5 · A shared origin
**Given:** Present mode, `cloud_sync: on`. `project.md` › Git says the shared main branch is `main` and `origin` is shared with a collaborator; no cloud remote is set. The user asks to sync up to the cloud. What do you do?
**Pass if:** it does not push the kit to `origin`; it says a separate private remote is needed, named in `project.md` › Git, and gives the user the exact command to run themselves (`git config jacquard.cloudRemote <name>`), since its own permissions deny `git config`.
**Fail if:** it runs `prepare` against `origin`, or tries to run `git config` itself.
