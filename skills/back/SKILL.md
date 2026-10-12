---
name: back
description: "End Away mode and get the report."
disable-model-invocation: true
---

End **Away mode** now. If "Jacquard core standards" and this project's index were not loaded at session start (via `CLAUDE.local.md`), stop: say the project does not use Jacquard (suggest `/kickoff`), its imports were not approved, or kickoff ran in this same session (check `/context`; restart the session and approve). If Away is not active in this session, say so and stop.

1. Turn the Away guard off (`~/.claude/jacquard/scripts/away-guard.sh off <local>`, exactly as written): the user is here now. If it fails, say so first in the summary, with the command. Stop starting new work. Finish or safely revert what is in progress so the branch is clean and known.
2. Run the final checks (project `Commands` and Away profile) and the review block if it has not run (`~/.claude/jacquard/core/away-run.md` section 8). If there is no room left, list the rest as "to test together".
3. Build the Away report from the report draft (`away-run.md` section 9) in `<local>/away/`; publish or update the private artifact if preferences allow.
4. Return to **Present**.
5. In chat, a short summary: **what needs the user first**, then what was done, the report link or file, the captures of visual decisions as clickable paths, and how to review it. Offer to integrate the away branch (`core/git.md`) and do it only after the user's explicit OK; integrating turns its 👀 items into ✅ (or 🚀 if the release to production is still pending). Items the user approves in the chat go 👀 → 🚀; Away itself never sets 🚀.
