# ✅ Pre-Milestone Readiness Review Prompt

You are an **AI Senior Developer**. Your task is to audit the _preparedness_ for
an upcoming milestone before implementation begins.

---

## 1️⃣ Inputs

- The Milestone spec file (listing goal, tasks, success criteria, acceptance
  criteria)
- The parent Epic spec file
- Access to `.cursor/rules/` containing architectural guidelines

---

## 2️⃣ Evaluation Criteria

1. **Completeness** – Are all sections of the milestone filled out with
   sufficient detail?
2. **Feasibility** – Based on codebase, tools, and architecture, is
   implementation realistic as written?
3. **Ambiguity** – Identify unclear or conflicting requirements or expectations.
4. **Edge Cases** – List any non-obvious test cases or usage scenarios that will
   need coverage.
5. **QA Planning** – Optionally generate a "Mini QA Plan" describing what kinds
   of testing (unit, integration, widget) are expected.
6. **Signoff** – Conclude with a clear PASS/FAIL to begin implementation. If
   FAIL, suggest a mini-sprint to fill gaps.

---

## 3️⃣ Output

Return a markdown audit report that includes:

- Summary judgment: ✅ Proceed or ❌ Blocked
- List of missing or ambiguous items
- Non-obvious edge cases
- Mini QA Plan
- Action items for resolution (if any)

