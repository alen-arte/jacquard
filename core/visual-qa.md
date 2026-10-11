---
name: jacquard-visual-qa
description: "Checking visual work in a real browser: what to capture, where it goes, who looks, how to keep image cost down, and what to say when no browser is available. Read for any task that changes what a screen looks like."
---

# Visual QA

Code that reads right can render wrong. Visual work is judged rendered (`design-standards.md` 16); this file says how, at a cost the project can keep paying.

## The tool

`project.md` › `render_check` names how this project renders and captures: usually the preview command plus a headless browser that saves a PNG Claude can read. "none" is a valid value.

- A headless browser run from the command line is enough. A browser extension or MCP server adds tools to every session; use one only if the project already has it.
- Adding a browser tool to a project is a dependency: ask first.
- **No browser, or it fails:** the work is reported as **"no real visual check"** in the reply, the QA verdict and the Away report. It is never presented as visually verified.

## What to capture

Only what the task changed:
- **Sizes:** the target sizes in the manual's context of use; without a manual, one phone width and one desktop width.
- **Themes:** every theme the product has.
- **States** the change can show: empty, loading, error, long text, many items (`design-standards.md` 12). A state the preview cannot reach is listed as not captured.

**Full sweep** (every affected screen, size, theme and state) only with `-sss`, before integrating a batch that changed shared tokens or layout, or at batch close when the budget is `generous`.

## Where

`<local>/qa/<ID>/<screen>-<size>-<theme>-<state>.png`, never in the repo. A new capture of the same thing overwrites the old one: captures are evidence for the current review, not an archive.

## Who looks

- **The builder, always,** before showing anything. That is verification, not review.
- **QA** looks at the captures when the task is level 2, at `-sss`, or when a mainly visual batch reaches its review; otherwise it checks the code and the builder's list of what was captured and what was not.
- QA gets the file paths and the spec, never the builder's opinion of the captures.

## Cost

An image costs about (width ÷ 28) × (height ÷ 28) tokens, up to the model's cap: a phone viewport ≈ 450, a desktop viewport ≈ 1,700. So:
- the viewport, not the full page, unless the change is below the fold;
- the element alone when the change is one component;
- one image per size, theme and state that changed, never "just in case";
- before-and-after pairs only when a regression is suspected.
