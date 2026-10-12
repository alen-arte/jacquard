---
name: jacquard-design-standards
description: "The floor of design quality for every Jacquard project: principles that separate purposeful design from generic output. Read for any design or UI task. Each product's own aesthetic lives in its system manual."
---

# Design standards

These are the floor, not the style. New, high-impact visual decisions are explored with `design-exploration.md`. A product's look, world and voice live in its system manual; these principles apply to all of them. When the manual and this file disagree, flag it as a rule conflict.

## Purpose

1. **Every element answers "what is it for?"** Inform, act, orient or mark a moment. Decoration is welcome when it carries meaning (state, hierarchy, identity, a moment that earned it). Decoration that carries nothing is noise.
2. **Hierarchy before style.** One primary action per view. The eye should land where the task needs it.
3. **Avoid the generic.** No template look: default gradients, interchangeable hero sections, emoji as icons, shadows and glow on everything, everything centered. Every visual choice must be traceable to the product's world and principles.

## Meaning

4. **One colour, one meaning,** consistent across the product. Never use a colour "because it looks nice" if it already means something.
5. **Never colour alone.** Pair it with shape, text, icon or position, so meaning survives colour blindness, glare and grayscale.
6. **Affordance honesty.** What looks touchable is touchable; what is not, does not look it. A static element dressed as a chip or button is a defect.
7. **One home per thing.** Each control lives in one place, always the same. The same thing looks and behaves the same everywhere.

## Restraint

8. **Proportional ceremony.** The size of a celebration or alert matches its rarity and importance. Celebrate everything and nothing is celebrated.
9. **Budgets.** Light, glow, motion and sound have explicit limits in the manual. Start restrained and add only what the render shows is missing.
10. **Motion with meaning.** Durations by purpose (response, feedback, ceremony), never as filler. Respect reduced-motion settings. **One event, one clock:** elements that react to the same event (a save that flags every missing field, a selection) share one effect definition and start and end together; an effect is a shared primitive, never re-created per element.

## System

11. **Tokens for every value:** colour, type, spacing, radius, elevation, motion. No raw values in components. A closed type scale. A future re-skin should be a token swap, not a rewrite.
12. **Complete states:** empty, loading, error, partial data, long text, many items, offline, first run.
13. **Real content.** Design with realistic data and real copy. Microcopy is design: short, specific, kind, in the product's voice.

## Access and context

14. **Accessibility baseline:** WCAG AA contrast at minimum, visible focus, keyboard and screen-reader path, touch targets of at least 44 pt (iOS) / 48 dp (Android), legible over any background the element can sit on.
15. **Context of use shapes the design:** device, distance from the screen, attention available, environment (light, noise, motion), session length. Record it in the manual.

## Verification

16. **Judge it rendered,** at the real target sizes and in every theme, never from code alone. If it is not good enough, it is not shown yet. How and at what cost: `visual-qa.md`.
