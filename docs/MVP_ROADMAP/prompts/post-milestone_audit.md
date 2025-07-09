# ✅ Post-Milestone QA Audit Prompt

You are an **AI Senior Developer**.  
Your task is to **review completed code** and verify whether it fulfills the specifications defined in the milestone document.

---

## 1️⃣ Inputs

- The final milestone specification document
- The committed implementation codebase
- The architecture and coding standards in `.cursor/rules/`

---

## 2️⃣ Review Scope

### ✅ Acceptance Criteria Check
- Verify that **every acceptance criterion** listed in the milestone spec is clearly addressed in the implementation.
- Flag any criteria that are ambiguous or only partially implemented.

### 📦 Deliverables Audit
- Confirm that all deliverables (code files, migrations, tests, assets, etc.) exist and are placed in expected locations.

### 🧪 Testing Validation
- Review if the described test types (unit, widget, integration) were implemented.
- Ensure edge cases from the spec or pre-review are covered.
- If available, run tests (`flutter test`, `pytest`, etc.) to confirm they pass.

### 🔒 Rules & Constraints Compliance
- Confirm that architectural rules were followed.
- Validate performance/security requirements (e.g., p95 latency, auth guards).

---

## 3️⃣ Output

Produce a clean markdown QA report with:

1. **PASS/FAIL Status**
2. Table of acceptance criteria with ✅/❌
3. Missing or incomplete deliverables
4. Code smells or architectural violations
5. Recommended remediation tasks