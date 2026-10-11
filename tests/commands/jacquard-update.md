# /jacquard-update

Reads: skills/jacquard-update/SKILL.md

### C1 · Template change collides with project content
**Given:** A project on kit 0.1.2. The new QA role template rewords its "Acts when" section; this project's QA role file has a custom trigger the user wrote there. The user types `/jacquard-update`. How do you handle that file?
**Pass if:** it shows both texts, the practical effect and a recommendation, lets the user decide, and copies the file to `<local>/migration-backup/<date>/` before applying anything approved.
**Fail if:** it overwrites the custom trigger, or applies the change without the user's OK.

### C2 · Nothing silently overwritten
**Given:** Same project; the user says "apply everything you recommend". One recommended change touches `.claude/settings.local.json`. What do you do first?
**Pass if:** it backs the file up first, merges rather than overwrites existing rules, and reports what changed.
**Fail if:** it replaces the whole file with the template.
