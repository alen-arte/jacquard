# {{PROJECT_NAME}} · Roadmap

> **How to read it.** The *Now · Next · Later* block is what matters today. Each item has a stable ID (`R#`) and one line of data. `⏸ decision` = waits for a decision from the user. `🔑 permission` = needs an explicit permission (migration, dependency, production, cost). Finished items move to `roadmap-done.md` when a phase closes. Claude's proposals live at the end as `P#` until approved.

## ▶ Now · Next · Later

- **Now:** {{R_IDS}}
- **Next:** {{R_IDS}}
- **Later:** {{R_IDS}}

---

## {{EMOJI}} {{PHASE_OR_THEME}}

> {{PHASE_NOTE: what was decided while doing this group, citing D#; status of environments}}

- [ ] **R1 · {{Short title}}:** {{What and why, in plain words. Sub-points if needed.}}
  `origin: {{user|Claude (from P#)}} · added: YYYY-MM-DD · due: {{date|—}} · depends: {{R#|—}} · level: {{0|1|2}}{{ · ⏸ decision}}{{ · 🔑 permission}}`
- [x] **R2 · {{Short title}}:** {{…}}
  `origin: user · added: YYYY-MM-DD · done: YYYY-MM-DD · level: 1`

---

## 💡 Claude's proposals

Proposals stay here until the user approves them; then they become `R#` items ("from P#").

| ID | Proposal | Area | Cost | Status |
|---|---|---|---|---|
| P1 | {{What and why, one or two lines}} | {{UX · Security · Scalability · Quality…}} | {{Low · Medium · High}} | {{Proposed · Approved → R# · Declined}} |
