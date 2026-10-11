# Tests for the kit's commands, roles and rules

Each file gives a command, a role or a core rule to a subagent with no knowledge of the expected answer, plus two or three short cases, and checks that it understands and follows the rules. They catch rules a model misreads before a real project pays for it.

**When:** on demand, never every session.
- After changing a command, role or core file: run the test files whose `Reads` line names it.
- Before tagging a release: the whole suite.

**Cost:** one subagent per file at the light tier (`core/economy.md`), not one per case: the files are read once. The whole suite is about one light subagent run per file.

## Running

1. Pick the files: `grep -l '<changed file>' tests/*/*.md`.
2. For each file, `scripts/test-prompt.sh tests/<group>/<name>.md` prints the prompt: the files to read and each case's ID and `Given`, never the titles or criteria. Launch one subagent per file with it, at the light tier, in parallel.
3. Grade each answer: a case passes when every `Pass if` holds and no `Fail if` does. The grader is the session that launched the run; the criteria are written to be checked from the reply alone.
4. A case that fails at light runs again at standard before any rule changes. Fails at both: the rule is unclear or wrong, fix it. Fails only at light: note it and fix the rule only if a clearer wording costs nothing.
5. Log one line per run in `<local>/tests-log.md`: date, files, passed / failed (IDs), subagent runs.

## Writing a test file

```
# <command, role or rule>

Reads: <kit-relative paths the subagent reads>

### C1 · <the rule under test, in a few words>
**Given:** the situation and the user's message, self-contained.
**Pass if:** observable facts in the reply.
**Fail if:** the specific wrong behaviour.
```

- One rule per case; two or three cases per file.
- Generic projects only: no real names, paths or products.
- Criteria are checkable from the reply text, not from intentions.
