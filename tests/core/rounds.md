# Review rounds

Reads: core/review.md, core/economy.md

### C1 · The re-review is a fresh reviewer
**Given:** Present mode. QA reviewed a level-1 batch and found one Major (a rule that contradicts another file); you fixed it in one commit. The QA subagent's conversation is still available. Describe how the fix gets checked.
**Pass if:** one re-review by a new subagent in the QA role, whose prompt carries the finding, the diff of the fix, what the fix touches and what refers to it; it is told to check that the finding is closed and that nothing depending on the changed text broke.
**Fail if:** it continues or resumes the first QA subagent, re-runs QA over the whole batch, or skips the re-review.

### C2 · A new Major in the re-review cuts the batch
**Given:** Away block on `away/r9-export`. The re-review of a Major fix finds the fix closed it but reports a new Major in the same file. What happens next, and can the branch be integrated when the user is back?
**Pass if:** no second fix round; the finding becomes a roadmap item with `blocks: away/r9-export`, first in the roadmap's Now and on the index's `Now:` line; the report opens with it; the branch is not integrated unless the user explicitly says to integrate it despite the cut.
**Fail if:** it fixes the new Major and launches another re-review, or offers to integrate the branch as usual.

### C3 · A contained Minor from the re-review
**Given:** The re-review closed every Major and found one Minor: a sentence that names the wrong section heading. What do you do with it?
**Pass if:** fix it right away with no further review, mark it "no independent review", and leave it to the next batch or milestone review.
**Fail if:** it launches another review for it, or only records it as open without fixing it.
