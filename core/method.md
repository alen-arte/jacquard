---
name: jacquard-method
description: "The default way a project moves from idea to release: starting points, phases, exit criteria and when each guiding document is born. A flexible default, adapted to each project."
---

# Method

A default, not a cage: phases overlap, repeat and adapt to the project. What is fixed is the intent: understand before building, build the thinnest real thing early, design the system from evidence, and never add work without purpose.

## Starting points (asked first by `/kickoff`)

| | Starting point | Kickoff does | Starts at |
|---|---|---|---|
| **A** | New project from scratch | Full interview | Phase 1 |
| **B** | New project with prior material (ideas, docs, designs, roadmap) | Reads the material, asks only for gaps | Phase 1, with a head start |
| **C** | Existing project owned by the user | Adopt mode: reads the repo, offers the initial audit | The phase that fits |
| **D** | Someone else's project where the user has a specific role | Adopt mode with boundaries; external planning is read-only | The phase of that project |

## Phases

**0 · Kickoff.** Interview, roles, stack, local setup. *Born:* `project.md`, `index.md`, roles, Away profile.

**1 · Framing.** The problem, who it is for, scope and explicit non-goals, the time or effort it is worth, the main flow in low fidelity: places, actions and connections, no visuals. *Born:* user flows v0 (`UF#`), roadmap v0 (`R#`), first decisions (`D#`). *Exit:* the user can say what the first usable version does and does not do.

**2 · Walking skeleton.** The thinnest real slice end to end on the real architecture: data, logic, interface, tests, CI and deploy to a non-production environment. Sober interface built on base tokens from day one. End-to-end test of the critical flow. *Born:* refactor backlog when the first `RF` appears. *Exit:* one real flow works end to end and every check runs automatically.

**3 · Usable MVP.** The flows from phase 1 complete, with a neutral design. Real use by the user or a few real people. *Born:* roadmap items from what was learned. *Exit:* the product does its core job for real people.

**4 · System.** The system manual, written from what exists and from real use: world, principles, shape grammar, colour, type, motion, voice, context of use. User flows v1. The interface is redesigned through tokens. *Born:* system manual (+ its view as an artifact). *Exit:* every screen follows the manual.

**5 · Iterations.** Roadmap by milestones, Away blocks for well-defined items, reviews by intensity, engineering advisor at each milestone close.

**6 · Release.** Full audit (engineering, security and privacy, accessibility, performance), production with the user's explicit OK, then back to iterations.

**Visual-first products** (the experience is the product) may bring a minimal manual (principles and base tokens) forward to phase 2. Kickoff proposes it when it applies.

## Rules

- A document is created when it is needed, not before. Kickoff lists which ones exist now and which come later.
- The roadmap is the single source of "what next". In projects with external planning (starting point D), that planning is read-only context and the user's own items live in the user's roadmap only if the project allows it.
- Moving to a new phase is the user's decision; Claude proposes it when the exit criteria are met.
