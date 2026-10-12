# {{PROJECT_NAME}} · Roadmap

> **How to read it.** The *Now · Next · Later* block is what matters today. Each item has a stable ID (`R#`) and one line of data. Marks: ⬜ Waiting · ⚖️ Decide (the user must pick an option) · 👀 Review (built in dev, no OK yet) · 🚀 Staged (approved, only the release is left) · ✅ Done (in production) · ❌ Rejected (with the reason). `🔑 permission` = needs an explicit permission (migration, dependency, production, cost). When a whole group is ✅ or ❌, Claude asks before the next block of work whether to move it to `roadmap-done.md`; it leaves a `📦` line with its IDs. Claude's proposals live at the end as `P#`: ⬜ waiting · 🔵 approved (→ `R#`) · ❌ rejected; approved and rejected ones leave the table at the next edit (rejected ones move to `roadmap-done.md` with the reason).

## ▦ Status index

<!-- status-index:start -->
<!-- status-index:end -->

> Derived from the marks below; never edit by hand. After changing a mark, run `scripts/roadmap-index.sh --write` (core/docs-system.md, Status index).

## ▶ Now · Next · Later

- **Now:** {{R_IDS}}
- **Next:** {{R_IDS}}
- **Later:** {{R_IDS}}

---

## {{EMOJI}} {{PHASE_OR_THEME}}

> {{PHASE_NOTE: what was decided while doing this group, citing D#; status of environments}}

- ⬜ **R1 · {{Short title}}:** {{What and why, in plain words. Sub-points if needed.}}
  `origin: {{user|Claude (from P#)}} · added: YYYY-MM-DD · due: {{date|—}} · depends: {{R#|—}} · level: {{0|1|2}}{{ · 🔑 permission}}`
- ⚖️ **R2 · {{Short title}}:** {{The options, one line each, with a recommendation.}}
  `origin: user · added: YYYY-MM-DD · options: A · B · C · level: 1`
- 👀 **R3 · {{Short title}}:** {{…}}
  `origin: user · added: YYYY-MM-DD · branch: r3-short-name · commit: abc1234 · level: 1`
- 🚀 **R4 · {{Short title}}:** {{…}}
  `origin: user · added: YYYY-MM-DD · branch: r4-short-name · commit: def5678 · level: 1`
- ✅ **R5 · {{Short title}}:** {{…}}
  `origin: user · added: YYYY-MM-DD · done: YYYY-MM-DD · level: 1 · reviews: 1 · findings: 0/1/2 · rework: 0`

---

## 💡 Claude's proposals

Open proposals live here. When approved they become `R#` items ("from P#"); the 🔵 or ❌ row is removed at the next roadmap edit (rejected ones move to `roadmap-done.md`).

| Status | Proposal | Area | Cost |
|---|---|---|---|
| {{⬜ Waiting · 🔵 Approved (→ R#) · ❌ Rejected, plus a few words, e.g. “🔵 Approved 2026-10-05 → R12”}} | **P1 · {{Short title}}:** {{What and why, one or two lines}} | {{UX · Security · Scalability · Quality…}} | {{Low · Medium · High}} |
