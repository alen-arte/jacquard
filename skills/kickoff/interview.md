# Kickoff interview

Rules:
- Ask only what cannot be read from the repo or the material. Skip blocks and questions that do not apply.
- At most three questions per screen. Tappable options; every question with options has a marked default.
- "Block n of N": block 0 has no count; N counts only the blocks that apply after it, numbered in order.
- With `technical_depth: plain`, say "review: light / normal / hardened" instead of `-s / -ss / -sss`, and "publish to the main version" instead of "push to main". With `technical`, use the flags and git terms.
- What the user does not cover, Claude's roles build; the user decides. Say so once, in block 1.

## Block 0 · Starting point (always)

**Where does this project start?** (default: A if the folder is empty, C if it has the user's own history, else ask)
- A · New, from scratch
- B · New, with prior material (ideas, docs, designs, a roadmap)
- C · An existing project of mine
- D · Someone else's project where I have a specific role

## Block 1 · Your role

- **What do you cover yourself?** (multi-select) Product and design (default) · Frontend · Backend and data · Infrastructure · Everything myself
- **Who decides?** Only me (default A, B, C) · Me with someone else · Someone else decides, I propose (default D)
- *(D, or collaborators exist)* **Who owns the areas you don't cover?** Name and area per person. → boundaries and notes for owners
- Whether the user reviews code is not asked: `technical_depth: plain` means no. State it and propose the engineering advisor.

## Block 2 · The product

*A, B (C if not readable), one question each:*
- **What is it, and for whom?** One line each
- **On which devices?** (multi-select) Phone · Tablet · Desktop · Web browser (default)
- **Does it need to work offline?** Needed · Nice to have · No (default)
- **Accounts and sync between devices?** Yes · No (default)
- **How is it distributed?** Web (default) · Installable web app · App stores · Internal
- **Domain risks** (multi-select) Money · Health · Personal data · Minors · Safety · None (default)

The stack is proposed once, in the proposal screen.

*D:*
- **What do you want to achieve in your area?**
- **What can you touch, and what is off-limits?**
- **How does your work get integrated?** Pull request (default) · Someone merges my branch · I integrate into main myself after review

## Block 3 · Material and planning

*B, C, D (after reading):*
- **Planning:** our own roadmap (default B, C) · someone else's planning, read-only (default D) · none yet
- **Design:** an existing manual or design system (where) · none yet (default)
- Confirm the list of existing rules found and whether to adopt, merge or leave each one (detail in the adoption plan)

## Block 4 · Git and collaboration

- **Publish to the main version:** on my explicit request (default A, B, C) · never, someone else integrates (default D). *(A, B with no remote and no collaborators: state the default, do not ask.)*
- Kit files stay out of git (always; just inform)
- *(collaborators)* **Where should notes for them go?** Only in reports (default) · A shared notes file (path)

## Block 5 · Verification

*C, D: read build, test and preview commands from the repo and confirm them in one line.*
- **Review:** light · normal · hardened (default: `default_intensity` from preferences, normal if unset)
- **Checks that need a person** (camera, hardware, real payments, a real phone…)? None (default) · Describe

What is irreversible here is derived from the stack and the domain risks and confirmed in the proposal.

## Block 6 · Aesthetics

*A, B:* **Direction in a few words, and references you like** (optional). **Is the experience the product?** Yes → minimal manual in phase 2 · No → manual in phase 4 (default: Yes if the user described the experience as the product, else No)
*C, D:* **Is there a design system or manual?** Where · None (default)
