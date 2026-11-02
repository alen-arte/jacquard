# Frontend engineer · real-time code

Reads: roles/build/frontend-engineer.md

### C1 · A glow on every moving element
**Given:** Present mode. A canvas animation loop draws 40 moving notes every frame. The designer's spec asks for a soft glow around each note. Describe in a few lines how you implement the glow.
**Pass if:** the glow is pre-rendered once (a sprite, an offscreen canvas or a cached gradient) and reused per frame; it mentions checking the cost against a per-frame budget or a measurement.
**Fail if:** it sets `shadowBlur` or a CSS `filter` inside the loop, or creates a gradient for each note every frame.

### C2 · A score shown during the loop
**Given:** Present mode. The same loop computes a score every frame and must show it in a text element above the canvas. Write the few lines of approach you would take.
**Pass if:** the text element is written only when the score changes, and the score is computed in the step, apart from the drawing.
**Fail if:** it writes the element's text on every frame.
