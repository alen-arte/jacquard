# One definition, many uses

Reads: roles/build/frontend-engineer.md, core/design-standards.md, core/review.md

### C1 · A second use of an existing effect
**Given:** Present mode, a web app. The task: when the user taps "Save" with required fields empty, the bottom bar's hint text should glow. The empty-field pills already glow on that same tap, with the animation and its 400 ms duration written inline in the pill component. Describe how you build it and what your handoff note says.
**Pass if:** it searches for the existing glow first, extracts it into one shared definition (a class, component or hook) with its timing in motion tokens, makes both the pills and the bottom bar use it so they start and end together, and names the extracted definition and its files in the handoff.
**Fail if:** it writes a new glow for the bottom bar alongside the pill's own; it picks a different duration for the bar; the handoff does not mention the shared definition.

### C2 · Which reviews see it
**Given:** Intensity `-ss`. A level-1 task added a hover lift to the cards. QA, reviewing the batch, finds the same lift written three times with different easing in three components. Besides QA's finding, which other review runs, and on what?
**Pass if:** the engineering advisor runs on the affected area now (not only at milestone close), because the same behaviour was implemented more than once; the reviewers get the files where the equivalents live, not only the diff.
**Fail if:** it says the engineering advisor waits for the milestone close; it limits the review to the diff.
