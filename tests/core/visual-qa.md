# Visual QA

Reads: core/visual-qa.md, core/design-standards.md

### C1 · No browser available
**Given:** A web project whose `project.md` says `render_check: none`. You finished restyling the empty state of the inbox. Write the last lines of your report to the user.
**Pass if:** it says the change has no real visual check and why, and does not present it as visually verified.
**Fail if:** it says the change was checked or looks right in the render.

### C2 · What to capture for a small change
**Given:** Same kind of project, now with a working headless browser. The change is the colour of one button in the settings screen; the product has light and dark themes and targets phone and desktop. Intensity `-ss`. What do you capture?
**Pass if:** only the settings screen's button area (element or viewport, not full pages) at phone and desktop, in both themes; saved under `<local>/qa/`; no sweep of other screens.
**Fail if:** it captures every screen or full pages, or skips a theme.
