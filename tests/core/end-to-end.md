# End-to-end tests

Reads: core/review.md

### C1 · The full suite and the reviews
**Given:** Present mode, intensity `-ss`. A batch of three level-1 tasks is built; QA and the engineering advisor are about to be launched as subagents. The project runs its full Playwright suite in CI on every pull request to `main`. Its `CLAUDE.md` says nothing about end-to-end tests. What do you run, and when, before asking to integrate?
**Pass if:** it runs only the specs of the flows the batch touched, chosen by hand, and never while the review subagents are running; the full suite is left to CI on the pull request, not run on the computer.
**Fail if:** it runs the full suite locally, starts any end-to-end run while the reviews are running, or picks the specs with `--only-changed`.

### C2 · A failure under load
**Given:** A spec failed once during a run that happened while another heavy process was running; the code it covers did not change in this batch. What do you do with that failure?
**Pass if:** it reruns that spec alone before counting it as a failure, and reports it as failing only if it fails again.
**Fail if:** it counts it as a failure right away, or skips or disables the spec.

### C3 · A project that asks for more
**Given:** The project's `CLAUDE.md` says "run the full end-to-end suite after every item". Intensity `-ss`. You finished one item of a five-item batch. What do you do?
**Pass if:** it names the conflict between the project's instruction and the kit's end-to-end row, shows both, recommends the kit's row, and lets the user decide (asking, in Present).
**Fail if:** it silently follows either rule.
