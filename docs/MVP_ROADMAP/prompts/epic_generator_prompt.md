# 🧠 BEE Epic-Task Builder Prompt

You are an **AI senior engineer**. Your task is to transform **one Epic** from
the MVP roadmap into a standalone engineering-task specification.

---

## 1️⃣ Inputs

• Roadmap: `@mvp_execution_blueprint_2025-07-19.md`\
• All docs referenced under that Epic (linked in the roadmap)\
• Architecture & coding rules in `.cursor/rules/`

---

## 2️⃣ Process

1. Locate the Epic name provided by the user in the roadmap.
2. Read every supporting document linked for that Epic.
3. Draft a markdown task spec containing:
   - **Epic overview** (goal, success criteria)
   - **Milestones** → tasks table (hours, status)
   - **Acceptance criteria** per milestone
   - **QA / Test coverage** tasks per milestone
   - **Dependencies** (other Epics, services, data)
4. Flag any ambiguous or missing requirements for user review.

---

## 3️⃣ Output

• Produce **clean markdown only**.\
• Name the file `docs/MVP_ROADMAP/tasks/epic_{id}_{slug}.md` (e.g.,
`epic_1-3_adaptive_ai_coach.md`).\
• Paste the document into chat when finished.
• Ensure all milestone filenames use **kebab-case** with no spaces or special characters to maintain cross-platform compatibility.

---

## 📑 Example Structure

```markdown
### EXAMPLE

**Epic:** 1.1 · Momentum Meter\
**Module:** Core Mobile Experience\
**Status:** ✅ COMPLETE\
**Dependencies:** Epic 2.1 – Engagement Events Logging ✅
- ⚠️ Explicitly flag cross-epic dependencies in the *Epic Overview*  
- 🧱 Ensure filenames for all milestones use **kebab-case**

---

## 📋 Epic Overview

**Goal:** Create a patient-facing motivation gauge that replaces traditional
"engagement scores" with a friendly, three-state system.

**Note:** Explicitly state any cross-epic dependencies directly in the Epic overview, not just in the dependencies list.

**Success Criteria:**

- Real-time momentum state visible and understandable (≥90 % users in testing)
- Gauge updates in <2 s (p95)
- Accessible (WCAG AA)

---

## 🏁 Milestone Breakdown

### M1.1.1 · UI Design & Mockups ✅ Complete

| Task | Description                     | Hours | Status |
| ---- | ------------------------------- | ----- | ------ |
| T1   | Create design system foundation | 6h    | ✅     |
| ...  | ...                             | ...   | ...    |

**Deliverables:** Design system, Figma mocks, interaction specs.

**Acceptance Criteria:** All momentum states visually distinct; stakeholder
sign-off.

---

## ⏱ Status Flags

🟡 Planned 🔵 In Progress ✅ Complete
```

---

## 🔗 Reference Docs (open on demand)

• `docs/architecture/bee_mvp_tech_overview.md` – system architecture & SLAs\
• `docs/architecture/component_governance.md` – component size & patterns

---

_End of prompt_
