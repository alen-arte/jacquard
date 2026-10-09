# Kickoff interview

Rules: ask only what cannot be read from the repo or the material; tappable options with a marked default; at most three questions per screen; "Block n of N"; skip blocks that do not apply. Keep answers in `project.md`, not in this conversation.

## Block 0 · Starting point (always)

**Where does this project start?**
- A · New, from scratch
- B · New, with prior material (ideas, docs, designs, a roadmap)
- C · An existing project of mine
- D · Someone else's project where I have a specific role

## Block 1 · Your role

- **What do you cover here?** (multi-select) Product and design (UX/UI) · Frontend · Backend and data · Infrastructure · Everything
- **Who decides?** Only me · Me with someone else · Someone else decides, I propose
- *(D, or collaborators exist)* **Who owns the areas you don't cover?** Name and area per person. → boundaries and notes for owners
- *(the user does not review code)* → propose the engineering advisor

## Block 2 · The product

*A, B (C if not readable):*
- **What is it and for whom?** One line each
- **On which devices?** (multi-select) Phone · Tablet · Desktop · Web browser · Other
- **Does it need to work offline? Accounts and sync between devices? How is it distributed?** (app stores · web · internal)
- **Domain risks** (multi-select) Money · Health · Personal data · Minors · Safety · None
→ stack proposal with reasons, checked against current official docs

*D:*
- **What do you want to achieve in your area?**
- **What can you touch, and what is off-limits?**
- **How does your work get integrated?** I push to main · Pull request · Someone merges my branch

## Block 3 · Material and planning

*B, C, D (after reading):*
- **Planning:** our own roadmap · someone else's planning, read-only · none yet
- **Design:** an existing manual or design system (where) · none yet
- Confirm the list of existing rules found and whether to adopt, merge or leave each one (detail in the adoption plan)

## Block 4 · Git and collaboration

- **Push to the main branch:** allowed on my explicit request (default A, B, C) · never, someone else integrates (default D)
- Kit files stay out of git (always; just inform)
- *(collaborators)* **Where should notes for them go?** Shared notes file (path) · Only in reports · Nowhere

## Block 5 · Verification

*C, D: read build, test and preview commands from the repo and confirm them in one line.*
- **What is irreversible here beyond the usual?** (data, payments, emails to real people, external accounts… or nothing extra)
- **Default review intensity:** -s light · -ss normal (default) · -sss hardened
- **Checks that need a person** (camera, hardware, real payments…)? None · Describe

## Block 6 · Aesthetics

*A, B:* **Direction in a few words, and references you like** (optional). Visual-first product? Yes → minimal manual in phase 2 · No → manual in phase 4
*C, D:* **Is there a design system or manual?** Where · None
