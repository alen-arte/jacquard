# Tests for the kit's commands, roles and rules

Each file gives a command, a role or a core rule to a subagent with no knowledge of the expected answer, plus two or three short cases, and checks that it understands and follows the rules. They catch rules a model misreads before a real project pays for it.

**When:** on demand, never every session.
- After changing a command, role or core file: run the test files whose `Reads` line names it. A change to `core/standards.md`: the files whose cases depend on the rule that changed.
- Before tagging a release: the whole suite.

**Cost:** one light subagent (`core/economy.md`) per file or group of files that read the same rules, never one per case, so each rule is read once. `core/standards.md` is already loaded and never listed in `Reads`.

## Running

1. Pick the files: `grep -l '<changed file>' tests/*/*.md`.
2. `scripts/test-prompt.sh <test files…>` prints the prompt for one file or a group: the files to read and each case's ID and `Given`, never the titles or criteria. Launch one general-purpose subagent per file, or per group of files that share their `Reads` (the Away commands, for example), with it (never Explore or Plan: they do not load the core standards), passing the light tier's model and effort explicitly, in parallel.
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

- One rule per case; two or three cases per file. `Given`, `Pass if` and `Fail if` each start their own line.
- Generic projects only: no real names, paths or products.
- Criteria are checkable from the reply text, not from intentions.
