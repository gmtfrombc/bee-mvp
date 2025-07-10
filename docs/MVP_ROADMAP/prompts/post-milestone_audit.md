# ✅ Post-Milestone QA Audit Prompt

You are an **AI Senior Developer**.\
Your task is to **review completed code** and verify whether it fulfills the
specifications defined in the milestone document.

---

## 1️⃣ Inputs

- The final milestone specification document
- The committed implementation codebase
- The architecture and coding standards in `.cursor/rules/`

---

## 2️⃣ Review Scope

### ✅ Acceptance Criteria Check

- Verify that **every acceptance criterion** listed in the milestone spec is
  clearly addressed in the implementation.
- Flag any criteria that are ambiguous or only partially implemented.

### 📦 Deliverables Audit

- Confirm that all deliverables (code files, migrations, tests, assets, etc.)
  exist and are placed in expected locations.

### 🧪 Testing Validation

- Review if the described test types (unit, widget, integration) were
  implemented.
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
6. Use the file @M1.11.1_post-milestone_mini-sprint.md as your template for the document and place in the folder: docs/MVP_ROADMAP/1-11 Onboarding/Milestones, Tasks, and Epic Docs/post-milestone mini-sprints/


---

## 🔄 Developer Wrap-Up Playbook (run _after_ audit ✅ PASS)

1. **Sync with `main` & run health-check**
   ```bash
   git checkout main && git pull --ff-only
   flutter analyze --fatal-infos
   flutter test
   ```
2. **Rebase feature branch, push, open PR**
   ```bash
   git checkout feature/<milestone-code>
   git rebase main
   git push --force-with-lease
   gh pr create --title "<milestone> complete" --base main --head feature/<milestone-code>
   ```
3. **Merge PR after CI passes & delete branch** (GitHub’s “Delete branch”
   button).
4. **Prune local refs**
   ```bash
   git checkout main && git pull --ff-only
   git fetch --prune
   ```
5. **Start next milestone** – follow the _Developer Kick-Off Playbook_.
